import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { canonicalUuid, parseCustomerInfo } from '../revenuecat-webhook/logic.ts';
import type { Database } from '../_shared/database.types.ts';

const headers = { 'Content-Type': 'application/json' };
function result(body: Record<string, unknown>, status = 200) { return new Response(JSON.stringify(body), { status, headers }); }
type AdminClient = SupabaseClient<Database>;
function safeError(error: unknown): string { return error instanceof Error ? error.message.slice(0, 80) : 'backfill_error'; }
async function fetchWithTimeout(input: RequestInfo | URL, init: RequestInit = {}, timeoutMs = 15000): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try { return await fetch(input, { ...init, signal: controller.signal }); }
  finally { clearTimeout(timer); }
}

async function getJson(url: string, apiKey: string): Promise<unknown> {
  const response = await fetchWithTimeout(url, { headers: { Authorization: `Bearer ${apiKey}`, Accept: 'application/json' } });
  if (!response.ok) throw new Error(`RevenueCat API status ${response.status}`);
  try { return await response.json(); } catch (_) { throw new Error('malformed RevenueCat response'); }
}

async function failRun(admin: AdminClient, runId: string, leaseToken: string, error: unknown): Promise<boolean> {
  const { error: failError } = await admin.rpc('fail_revenuecat_backfill_run', { p_run_id: runId, p_lease_token: leaseToken, p_error_code: safeError(error) });
  return !failError;
}

Deno.serve(async (request) => {
  const auth = Deno.env.get('REVENUECAT_BACKFILL_AUTHORIZATION');
  const apiKey = Deno.env.get('REVENUECAT_API_KEY');
  const projectId = Deno.env.get('REVENUECAT_PROJECT_ID');
  const appId = Deno.env.get('REVENUECAT_APP_ID');
  const environment = Deno.env.get('REVENUECAT_ENVIRONMENT')?.trim().toUpperCase();
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!auth || !apiKey || !projectId || !appId || !environment || !supabaseUrl || !serviceRoleKey) return result({ error: 'server configuration unavailable' }, 500);
  if (request.method !== 'POST' || request.headers.get('Authorization') !== auth) return result({ error: 'unauthorized' }, 401);

  let requestedRunId: string | null = null;
  try {
    const body = await request.json();
    requestedRunId = typeof body?.run_id === 'string' ? canonicalUuid(body.run_id) : null;
    if (body?.run_id !== undefined && !requestedRunId) return result({ error: 'invalid run_id' }, 400);
  } catch (_) { return result({ error: 'invalid payload' }, 400); }

  const admin = createClient<Database>(supabaseUrl, serviceRoleKey, { global: { fetch: (input, init) => fetchWithTimeout(input, init) } });
  let runId: string;
  if (!requestedRunId) {
    const { data, error } = await admin.from('revenuecat_backfill_runs').insert({}).select('run_id').single();
    if (error || !data || typeof data.run_id !== 'string') return result({ error: 'backfill ledger unavailable' }, 500);
    runId = data.run_id;
  } else {
    runId = requestedRunId;
  }

  const { data: claim, error: claimError } = await admin.rpc('claim_revenuecat_backfill_run', { p_run_id: runId });
  if (claimError || !claim || typeof claim !== 'object') return result({ error: 'backfill ledger unavailable' }, 500);
  const claimMap = claim as Record<string, unknown>;
  if (claimMap.status === 'completed') return result({ run_id: runId, completed: true, next_starting_after: null });
  if (claimMap.status === 'in_progress') return result({ run_id: runId, accepted: false, retry: true }, 202);
  if (claimMap.status !== 'claimed' || typeof claimMap.lease_token !== 'string') return result({ error: 'backfill claim unavailable' }, 500);
  const leaseToken = claimMap.lease_token;
  const startingAfter = typeof claimMap.next_starting_after === 'string' ? claimMap.next_starting_after : null;
  const previousExamined = Number(claimMap.examined_count ?? 0);
  const previousUpdated = Number(claimMap.updated_count ?? 0);
  const pageKey = startingAfter ?? '__initial__';
  // 25 items keeps the worst-case bounded work below the 30-minute lease when
  // RevenueCat, Auth and Supabase calls each consume their 15-second timeout.
  const params = new URLSearchParams({ limit: '25' });
  if (startingAfter) params.set('starting_after', startingAfter);

  let page: Record<string, unknown>;
  try {
    page = await getJson(`https://api.revenuecat.com/v2/projects/${encodeURIComponent(projectId)}/customers?${params}`, apiKey) as Record<string, unknown>;
  } catch (error) {
    const recovered = await failRun(admin, runId, leaseToken, error);
    return result({ error: recovered ? 'RevenueCat customer listing unavailable' : 'backfill ledger unavailable', run_id: runId }, 502);
  }
  if (!page || !Array.isArray(page.items)) {
    const recovered = await failRun(admin, runId, leaseToken, 'malformed customer page');
    return result({ error: recovered ? 'malformed RevenueCat customer page' : 'backfill ledger unavailable', run_id: runId }, 502);
  }

  let examined = 0; let updated = 0;
  try {
    for (const item of page.items) {
      examined++;
      if (!item || typeof item !== 'object') continue;
      const userId = canonicalUuid((item as Record<string, unknown>).id);
      if (!userId) continue;
      const { data: user, error: userError } = await admin.auth.admin.getUserById(userId);
      if (userError) throw new Error('Supabase Auth lookup unavailable');
      if (!user.user) continue;
      const info = await getJson(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`, apiKey);
      const projection = parseCustomerInfo(info);
      const { data: applied, error } = await admin.rpc('apply_revenuecat_entitlement_for_backfill', {
        p_run_id: runId, p_lease_token: leaseToken,
        p_user_id: userId, p_revenuecat_app_user_id: userId, p_is_active: projection.active,
        p_expires_at: projection.expiresAt, p_product_id: projection.productId,
        p_environment: environment, p_event_at: null,
        p_projection_event_id: `backfill:${runId}:${userId}`, p_app_id: appId,
        p_observed_at: projection.snapshotAt, p_observed_reliable: projection.snapshotReliable,
      });
      if (error) throw new Error(`projection:${error.code ?? 'unknown'}`);
      if (applied === true) updated++;
    }
  } catch (error) {
    const recovered = await failRun(admin, runId, leaseToken, error);
    return result({ error: recovered ? 'backfill page failed' : 'backfill ledger unavailable', run_id: runId }, 502);
  }

  let next: string | null = null;
  try {
    if (typeof page.next_page === 'string') {
      const nextPage = new URL(page.next_page, 'https://api.revenuecat.com');
      if (nextPage.origin !== 'https://api.revenuecat.com') throw new Error('invalid pagination origin');
      next = nextPage.searchParams.get('starting_after');
      if (next && next === startingAfter) throw new Error('pagination cursor did not advance');
    }
  } catch (error) {
    const recovered = await failRun(admin, runId, leaseToken, error);
    return result({ error: recovered ? 'invalid RevenueCat pagination' : 'backfill ledger unavailable', run_id: runId }, 502);
  }

  const { error: advanceError } = await admin.rpc('advance_revenuecat_backfill_run_v2', {
    p_run_id: runId, p_lease_token: leaseToken, p_page_key: pageKey, p_next_starting_after: next,
    p_examined_delta: examined, p_updated_delta: updated,
  });
  if (advanceError) return result({ error: 'backfill progress unavailable', run_id: runId }, 500);
  return result({ run_id: runId, examined, updated, previous_examined: previousExamined, previous_updated: previousUpdated, next_starting_after: next });
});
