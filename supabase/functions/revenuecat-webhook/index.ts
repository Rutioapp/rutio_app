import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { areIdentitiesAllowed, classifyTransferIdentities, isExpectedWebhookEnvironment, parseAllowedUserIds, parseRevenueCatEnvironment, productionIdentitiesExist, productionIdentityIds, type RevenueCatEnvironment } from './logic.ts';
import type { Database } from '../_shared/database.types.ts';

const jsonHeaders = { 'Content-Type': 'application/json' };
const knownTypes = new Set(['INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'CANCELLATION', 'BILLING_ISSUE', 'NON_RENEWING_PURCHASE', 'UNCANCELLATION', 'TRANSFER', 'SUBSCRIPTION_PAUSED', 'EXPIRATION', 'REFUND', 'SUBSCRIPTION_EXTENDED', 'REFUND_REVERSED', 'CUSTOMER_SUPPORT', 'TEMPORARY_ENTITLEMENT_GRANT', 'PURCHASE_REDEEMED', 'TEST']);
const positiveTypes = new Set(['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'SUBSCRIPTION_EXTENDED', 'NON_RENEWING_PURCHASE', 'PURCHASE_REDEEMED']);
type Event = Record<string, unknown>;
type AdminClient = SupabaseClient<Database>;

function response(body: Record<string, unknown>, status = 200) { return new Response(JSON.stringify(body), { status, headers: jsonHeaders }); }
async function fetchWithTimeout(input: RequestInfo | URL, init: RequestInit = {}, timeoutMs = 15000): Promise<Response> {
  const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), timeoutMs);
  try { return await fetch(input, { ...init, signal: controller.signal }); } finally { clearTimeout(timer); }
}
function constantTimeEqual(a: string, b: string): boolean { const aa = new TextEncoder().encode(a); const bb = new TextEncoder().encode(b); let result = aa.length ^ bb.length; for (let i = 0; i < Math.max(aa.length, bb.length); i++) result |= (aa[i] ?? 0) ^ (bb[i] ?? 0); return result === 0; }
function isoFromMillis(value: unknown): string | null { return typeof value === 'number' && Number.isFinite(value) && value > 0 ? new Date(value).toISOString() : null; }
function priorityFor(type: string): number { return type === 'TRANSFER' ? 100 : ['EXPIRATION', 'REFUND', 'REFUND_REVERSED', 'BILLING_ISSUE', 'SUBSCRIPTION_PAUSED'].includes(type) ? 80 : 20; }
function premiumEvent(value: Event): boolean { const ids = value.entitlement_ids; return Array.isArray(ids) && ids.some((id) => typeof id === 'string' && id.trim().toLowerCase() === 'premium'); }
function positiveExpiry(value: Event): string | null { const expiry = isoFromMillis(value.expiration_at_ms); return expiry && Date.parse(expiry) > Date.now() ? expiry : null; }
function subscriptionKey(value: Event): string | null { for (const field of ['original_transaction_id', 'transaction_id', 'product_id']) if (typeof value[field] === 'string' && value[field].trim()) return value[field].trim(); return null; }

async function enqueue(admin: AdminClient, userId: string, appId: string, environment: string, eventId: string, priority: number, allowlisted: boolean) {
  const { error } = await admin.rpc('enqueue_revenuecat_premium_sync', { p_user_id: userId, p_app_id: appId, p_environment: environment, p_event_id: eventId, p_priority: priority, p_allowlisted: allowlisted });
  if (error) throw new Error(`sync queue unavailable:${error.code ?? 'unknown'}`);
}

function defaultAdminClient(): AdminClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL'); const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) throw new Error('server configuration unavailable');
  return createClient<Database>(supabaseUrl, serviceRoleKey, { global: { fetch: (input: RequestInfo | URL, init: RequestInit = {}) => fetchWithTimeout(input, init) } });
}

export async function handleRequest(request: Request, injectedAdmin?: AdminClient): Promise<Response> {
  const expected = Deno.env.get('REVENUECAT_WEBHOOK_AUTHORIZATION');
  const expectedEnvironment = parseRevenueCatEnvironment(Deno.env.get('REVENUECAT_ENVIRONMENT'));
  const expectedAppId = Deno.env.get('REVENUECAT_APP_ID');
  const allowedUserIds = parseAllowedUserIds(Deno.env.get('REVENUECAT_ALLOWED_USER_IDS'));
  const supabaseUrl = Deno.env.get('SUPABASE_URL'); const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!expected || !expectedEnvironment || !expectedAppId || !supabaseUrl || !serviceRoleKey) return response({ error: 'server configuration unavailable' }, 500);
  if (expectedEnvironment === 'SANDBOX' && !allowedUserIds) return response({ error: 'server configuration unavailable' }, 500);
  if (request.method !== 'POST') return response({ error: 'method not allowed' }, 405);
  if (!constantTimeEqual(request.headers.get('Authorization') ?? '', expected)) return response({ error: 'unauthorized' }, 401);
  let payload: Record<string, unknown>;
  try { const raw = await request.text(); if (raw.length > 1_000_000) return response({ error: 'payload too large' }, 413); payload = JSON.parse(raw) as Record<string, unknown>; } catch (_) { return response({ error: 'invalid payload' }, 400); }
  if (typeof payload.api_version !== 'string' || !payload.api_version.trim()) return response({ error: 'invalid api version' }, 422);
  const event = payload.event; if (!event || typeof event !== 'object' || Array.isArray(event)) return response({ error: 'invalid event' }, 422);
  const value = event as Event; const eventId = typeof value.id === 'string' ? value.id.trim() : ''; const type = typeof value.type === 'string' ? value.type.trim().toUpperCase() : '';
  if (!eventId || !type || (typeof value.event_timestamp_ms !== 'number' && type !== 'TEST')) return response({ error: 'invalid event fields' }, 422);
  if (typeof value.app_id !== 'string' || value.app_id !== expectedAppId) return response({ error: 'wrong RevenueCat app' }, 422);
  if (!isExpectedWebhookEnvironment(value.environment, expectedEnvironment)) return response({ error: 'wrong RevenueCat environment' }, 422);
  if (type === 'TEST') return response({ accepted: true, test: true });
  if (!knownTypes.has(type)) return response({ accepted: true, ignored: true });
  const admin = injectedAdmin ?? defaultAdminClient();
  const ids = classifyTransferIdentities(value);
  if ([...ids.internalIds, ...ids.unresolvedIds].length > 8 || ids.internalIds.length === 0 || ids.unresolvedIds.length > 0) return response({ error: 'unauthorized identity' }, 403);
  if (expectedEnvironment === 'SANDBOX') {
    if (!allowedUserIds || !areIdentitiesAllowed(value, allowedUserIds)) return response({ error: 'unauthorized test identity' }, 403);
  } else {
    const productionIds = productionIdentityIds(value);
    const identitiesExist = productionIds !== null && await productionIdentitiesExist(productionIds, async (userId) => {
      const { data, error } = await admin.auth.admin.getUserById(userId);
      return !error && !!data.user;
    });
    if (!identitiesExist) return response({ error: 'unauthorized production identity' }, 403);
  }
  const identityValidated = expectedEnvironment === 'PRODUCTION'
    ? true
    : allowedUserIds !== null;
  const appUserId = typeof value.app_user_id === 'string' ? value.app_user_id.trim().toLowerCase() : null;
  const { data: claim, error: claimError } = await admin.rpc('claim_revenuecat_webhook_event', { p_event_id: eventId, p_event_type: type, p_app_user_id: appUserId, p_event_at: isoFromMillis(value.event_timestamp_ms), p_environment: expectedEnvironment });
  if (claimError || !claim || typeof claim !== 'object') return response({ error: 'event ledger unavailable' }, 500);
  const claimMap = claim as Record<string, unknown>; if (claimMap.status === 'processed' || claimMap.status === 'ignored') return response({ accepted: true, duplicate: true }); if (claimMap.status === 'in_progress') return response({ accepted: false, retry: true }, 503);
  if (claimMap.status !== 'claimed' || typeof claimMap.lease_token !== 'string') return response({ error: 'event claim unavailable' }, 500);
  const leaseToken = claimMap.lease_token;
  try {
    if (type === 'TEST') { const { error } = await admin.rpc('finalize_revenuecat_webhook_event', { p_event_id: eventId, p_lease_token: leaseToken, p_status: 'ignored', p_error_code: null }); if (error) throw new Error('event ledger unavailable'); return response({ accepted: true, ignored: true }); }
    const eventExpiry = positiveExpiry(value); const eventSubscriptionKey = subscriptionKey(value);
    const isPositive = positiveTypes.has(type) && premiumEvent(value) && eventExpiry !== null && eventSubscriptionKey !== null;
    for (const userId of ids.internalIds) {
      await enqueue(admin, userId, expectedAppId, expectedEnvironment, eventId, priorityFor(type), identityValidated);
      if (isPositive && eventExpiry && eventSubscriptionKey) {
        const { error: positiveError } = await admin.rpc('apply_revenuecat_positive_event', { p_event_id: eventId, p_lease_token: leaseToken, p_user_id: userId, p_revenuecat_app_user_id: userId, p_expires_at: eventExpiry, p_product_id: typeof value.product_id === 'string' ? value.product_id : null, p_store: typeof value.store === 'string' ? value.store : null, p_environment: expectedEnvironment, p_event_at: isoFromMillis(value.event_timestamp_ms), p_app_id: expectedAppId, p_subscription_key: eventSubscriptionKey, p_allowlisted: identityValidated });
        if (positiveError) throw new Error(`positive projection unavailable:${positiveError.code ?? 'unknown'}`);
      }
    }
    const { error } = await admin.rpc('finalize_revenuecat_webhook_event', { p_event_id: eventId, p_lease_token: leaseToken, p_status: 'processed', p_error_code: null }); if (error) throw new Error('event ledger unavailable');
    return response({ accepted: true, queued: true, provisional_positive: isPositive });
  } catch (error) {
    const errorCode = error instanceof Error ? error.message.slice(0, 80) : 'processing_error'; const { error: finalizeError } = await admin.rpc('finalize_revenuecat_webhook_event', { p_event_id: eventId, p_lease_token: leaseToken, p_status: 'failed', p_error_code: errorCode });
    return finalizeError ? response({ error: 'event ledger unavailable' }, 500) : response({ error: 'event processing unavailable' }, 500);
  }
}

if (import.meta.main) Deno.serve((request) => handleRequest(request));
