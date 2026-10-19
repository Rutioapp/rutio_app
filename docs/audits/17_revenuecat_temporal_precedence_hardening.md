# RevenueCat temporal precedence hardening

## Verdict

**BLOCKED.** The corrective migration and local parser/static tests are
prepared, but the isolated PostgreSQL integration suite could not run because
this environment has no `psql` or Docker. Deno 2.9.7 is available and its local
checks passed. No remote system was contacted, no migration was run, and no
Edge Function was deployed.

## Diagnosis

The three existing migrations provide useful idempotency, row locks, leases and
lease-token checks. They do not, however, provide an authoritative ordering for
API v2 reads.

`revenuecat-webhook/index.ts` fetches all v2 subscription pages and passes
`new Date().toISOString()` as `snapshotAt`. That is local observation/completion
time, not a RevenueCat state version. Two concurrent reads can complete in the
opposite order and 153000 can accept the later local timestamp. A webhook's
`event_timestamp_ms` is the event clock, not the version of the later API
snapshot. Comparing either clock with a v1 `request_date` is invalid.

The previous conflict branch also set `is_active = false`. That can revoke a
currently valid entitlement when the only evidence is an ambiguous, partial,
or cross-clock observation. API errors already fail before projection; the
same safety rule must apply to temporal ambiguity.

Leases and fencing tokens prevent two workers from owning the same work item at
the same time and allow recovery. They do not turn a local generation or lease
sequence into proof of RevenueCat's remote mutation order. A lease can expire
while HTTP is in flight; the guarded RPC must re-check ownership immediately
before the write, and a stale worker must never finalize the ledger.

## Formal policy

1. Event time, observation time, operation order, subscription validity and
   remote snapshot version are separate values.
2. API v1 `request_date` is retained as `observed_v1`, a provider response
   observation marker. It is not a proven remote mutation version and cannot
   establish global remote order. It is used only for bounded recovery and is
   never compared across API v2 or webhook clocks.
3. API v2 snapshots are `unversioned`. Local receive time, local completion
   time, a lease token, and a local generation are never used as precedence.
4. A duplicate event is idempotent by event ID. An older `observed_v1`
   response is ignored; a same-time different response is a conflict. This is
   an operation/observation ordering policy, not proof of RevenueCat mutation
   ordering.
5. Cross-clock/source comparisons are conflicts, not ordering decisions.
6. A conflict preserves the last entitlement, sets
   `reconciliation_required`, records a bounded conflict code, and grants no
   Premium to a new/empty row. It does not revoke existing Premium.
7. Only a complete v1 reconciliation may replace a conflicted row and clear
   the flag, subject to the limited `request_date` contract above. HTTP
   failure, timeout, malformed data, partial pagination and expired leases
   leave the projection unchanged. If RevenueCat cannot guarantee that v1
   `request_date` is a coherent observation cutoff, automatic recovery must be
   disabled and made operator-confirmed.
8. Sandbox and Production remain separate by the existing app/environment
   validation; a future deployment must also verify that the projection key
   includes the intended environment if both are stored together.

## Scenario outcomes

Concurrent v2 reads, inverted completion, delayed/duplicate webhooks,
reconciliation during a webhook, backfill races, partial pages, HTTP failure,
timeouts and lease recovery are safe because unversioned reads cannot replace
state and lease tokens are checked in the guarded RPC. A new Sandbox purchase
cannot activate Premium in the webhook itself: it creates an inactive
reconciliation candidate. Activation, renewal and legitimate expiry currently
require the v1 reconciliation path. Cancellation that preserves access remains
active until its known expiry. An event only triggers a refresh and does not by
itself prove the state returned by a later v2 read. A transfer is applied only
for verified internal UUID/Auth identities, as already enforced by the webhook.

## Proposed change

`20261013100000_revenuecat_temporal_precedence_hardening.sql` is additive and
posterior to 153000. It adds `last_snapshot_kind` and replaces the v2 apply
policy without editing installed migrations. It preserves the existing
SECURITY DEFINER, empty search path, explicit service-role EXECUTE grants, RLS
and event ledger. It is intentionally not executed here.

The Edge Function's v2 observation is passed as `null/false`; the
corrective SQL also derives `unversioned` from `p_source='webhook'`, so an old
caller cannot turn a local clock into an authoritative version.

## Required local tests

Before staging review, run the static checks and an isolated PostgreSQL test
with migrations 145000, 152000, 153000 and this migration loaded. The isolated
test must cover inverted concurrent reads, stale/equal tokens, expired leases,
old webhook, later renewal, legitimate expiry, incomplete snapshot,
reconciliation failure, concurrent backfill, Sandbox/Production separation,
EXECUTE privileges, RLS and cleanup. Do not point it at either Supabase project.

## Required answers

- **New purchase:** no direct webhook activation; it becomes an inactive
  candidate until reconciliation. A v1 read can activate it only under the
  bounded recovery rule.
- **Renewal/expiry:** same limitation; they are not proven by webhook event
  time. A complete reconciliation is required.
- **v2 reconciliation:** v2 alone cannot safely resolve precedence. It can
  request/retry reconciliation, but cannot authorize replacement.
- **Indefinite pending state:** yes, if v1 is unavailable or its contract is
  insufficient. Retry backoff and monitoring are required; there is no cron
  activation in this scope.
- **Permanent Premium block:** yes for new/ambiguous rows; existing known
  Premium remains available until its known expiry. Recovery requires a
  complete reconciliation or explicit operator decision.
- **Remote ordering guarantee:** none is established by this migration. The
  policy provides bounded consistency and recovery, not total remote order.

## Open risks

The v1 `request_date` is not assumed to be authoritative. It remains a
provider-contract dependency that must be confirmed before production. If it
is not a coherent observation cutoff, disable automatic timestamp recovery and
require reconciliation with a provider-supported version/token or operator
approval. The current schema also stores one row per user, so a production
deployment serving Sandbox and Production simultaneously should add an
explicit environment/app dimension before enabling both paths.

## Staging protocol

Review the SQL and privileges offline; apply only in a disposable staging
window; run the isolated SQL tests first; then exercise two delayed reads,
duplicate/old webhook delivery, a real expiry and renewal, a forced timeout,
lease recovery, and a failed reconciliation. Verify that ambiguity preserves
the previous entitlement, that a new ambiguous row is inactive, and that no
client role can execute the projection functions or read internal tables.
