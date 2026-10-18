import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { canonicalUuid, parseRevenueCatEnvironment, parseSandboxSubscriptionPages, type RevenueCatEnvironment } from '../revenuecat-webhook/logic.ts';
import { premiumProductsShape } from './diagnostics.ts';
import type { Database } from '../_shared/database.types.ts';

const headers = { 'Content-Type': 'application/json' };
type AdminClient = SupabaseClient<Database>;
function response(body: Record<string, unknown>, status = 200) { return new Response(JSON.stringify(body), { status, headers }); }
function safeError(error: unknown): string { return error instanceof Error ? error.message.slice(0, 80) : 'reconciliation_error'; }
class RevenueCatHttpError extends Error { constructor(readonly status: number) { super(`rc_status_${status}`); } }
async function fetchWithTimeout(input: RequestInfo | URL, init: RequestInit = {}, timeoutMs = 15000): Promise<Response> { const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), timeoutMs); try { return await fetch(input, { ...init, signal: controller.signal }); } finally { clearTimeout(timer); } }
function constantTimeEqual(a: string, b: string): boolean { const aa = new TextEncoder().encode(a); const bb = new TextEncoder().encode(b); let result = aa.length ^ bb.length; for (let i = 0; i < Math.max(aa.length, bb.length); i++) result |= (aa[i] ?? 0) ^ (bb[i] ?? 0); return result === 0; }

async function fetchSandboxSubscriptions(apiKey: string, projectId: string, userId: string, appId: string, environment: RevenueCatEnvironment) {
  const items: unknown[] = []; let nextUrl: string | null = `https://api.revenuecat.com/v2/projects/${encodeURIComponent(projectId)}/customers/${encodeURIComponent(userId)}/subscriptions?environment=${environment.toLowerCase()}&limit=100`; const seen = new Set<string>();
  for (let page = 0; nextUrl; page++) {
    if (page >= 20 || seen.has(nextUrl)) throw new Error('RevenueCat v2 pagination did not terminate'); seen.add(nextUrl);
    const result = await fetchWithTimeout(nextUrl, { headers: { Authorization: `Bearer ${apiKey}`, Accept: 'application/json', 'Cache-Control': 'no-cache' } });
    if (result.status === 404 && page === 0) return parseSandboxSubscriptionPages({ object: 'list', items: [], next_page: null }, null, appId, environment);
    if (!result.ok) throw new RevenueCatHttpError(result.status);
    const body = await readListPage(result);
    items.push(...body.items); const rawNext = body.next_page;
    if (rawNext === undefined || rawNext === null) nextUrl = null; else if (typeof rawNext !== 'string') throw new Error('malformed RevenueCat v2 pagination'); else { const parsed = new URL(rawNext, 'https://api.revenuecat.com'); if (parsed.origin !== 'https://api.revenuecat.com' || !parsed.pathname.startsWith(`/v2/projects/${projectId}/customers/`)) throw new Error('invalid RevenueCat v2 pagination origin'); nextUrl = parsed.toString(); }
  }
  const completeItems = [];
  for (const item of items) completeItems.push(await completeNestedSubscription(item, apiKey, projectId, environment));
  return parseSandboxSubscriptionPages({ object: 'list', items: completeItems, next_page: null }, null, appId, environment);
}

async function readListPage(result: Response): Promise<{ items: unknown[]; next_page?: unknown }> {
  let body: unknown; try { body = await result.json(); } catch (_) { throw new Error('malformed RevenueCat v2 response'); }
  if (!body || typeof body !== 'object' || Array.isArray(body) || (body as Record<string, unknown>).object !== 'list' || !Array.isArray((body as Record<string, unknown>).items)) throw new Error('malformed RevenueCat v2 list page');
  return body as { items: unknown[]; next_page?: unknown };
}

function nestedUrl(value: unknown, projectId: string): string | null {
  if (typeof value !== 'string') return null;
  const parsed = new URL(value, 'https://api.revenuecat.com');
  if (parsed.origin !== 'https://api.revenuecat.com' || !parsed.pathname.startsWith(`/v2/projects/${projectId}/`)) throw new Error('invalid RevenueCat v2 nested pagination origin');
  return parsed.toString();
}

async function fetchNestedItems(first: unknown[], nextValue: unknown, apiKey: string, projectId: string): Promise<unknown[]> {
  const items = [...first]; let next = nestedUrl(nextValue, projectId); const seen = new Set<string>();
  for (let page = 0; next; page++) {
    if (page >= 20 || seen.has(next)) throw new Error('RevenueCat v2 nested pagination did not terminate'); seen.add(next);
    const result = await fetchWithTimeout(next, { headers: { Authorization: `Bearer ${apiKey}`, Accept: 'application/json', 'Cache-Control': 'no-cache' } });
    if (!result.ok) throw new RevenueCatHttpError(result.status);
    const body = await readListPage(result); items.push(...body.items); next = nestedUrl(body.next_page, projectId);
  }
  return items;
}

async function completeNestedSubscription(raw: unknown, apiKey: string, projectId: string, environment: string): Promise<unknown> {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('malformed RevenueCat v2 subscription');
  const item = raw as Record<string, unknown>; const rawEntitlements = item.entitlements;
  if (!rawEntitlements || typeof rawEntitlements !== 'object' || Array.isArray(rawEntitlements)) throw new Error('malformed RevenueCat v2 entitlements');
  const entitlements = rawEntitlements as Record<string, unknown>; const entitlementItems = entitlements.items;
  if (!Array.isArray(entitlementItems)) throw new Error('malformed RevenueCat v2 entitlement list');
  const completedEntitlementItems = await fetchNestedItems(entitlementItems, entitlements.next_page, apiKey, projectId);
  const completed = [];
  for (const rawEntitlement of completedEntitlementItems) {
    if (!rawEntitlement || typeof rawEntitlement !== 'object' || Array.isArray(rawEntitlement)) throw new Error('malformed RevenueCat v2 entitlement');
    const entitlement = { ...(rawEntitlement as Record<string, unknown>) };
    if (entitlement.lookup_key === 'premium') {
      const rawProducts = entitlement.products;
      if (!rawProducts || typeof rawProducts !== 'object' || Array.isArray(rawProducts)) {
        if (environment === 'SANDBOX') console.warn('revenuecat-reconcile: malformed premium products shape', premiumProductsShape(rawProducts));
        throw new Error('malformed RevenueCat v2 premium products');
      }
      const products = rawProducts as Record<string, unknown>;
      if (!Array.isArray(products.items)) {
        if (environment === 'SANDBOX') console.warn('revenuecat-reconcile: malformed premium products shape', premiumProductsShape(rawProducts));
        throw new Error('malformed RevenueCat v2 premium products');
      }
      entitlement.products = { ...products, items: await fetchNestedItems(products.items, products.next_page, apiKey, projectId), next_page: null };
    }
    completed.push(entitlement);
  }
  return { ...item, entitlements: { ...entitlements, items: completed, next_page: null } };
}

function defaultAdminClient(): AdminClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL'); const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) throw new Error('server configuration unavailable');
  return createClient<Database>(supabaseUrl, serviceRoleKey, { global: { fetch: (input: RequestInfo | URL, init: RequestInit = {}) => fetchWithTimeout(input, init) } });
}

export async function handleRequest(request: Request, injectedAdmin?: AdminClient): Promise<Response> {
  const expectedAuth = Deno.env.get('REVENUECAT_RECONCILE_AUTHORIZATION'); const apiKey = Deno.env.get('REVENUECAT_API_V2_KEY'); const projectId = Deno.env.get('REVENUECAT_PROJECT_ID'); const appId = Deno.env.get('REVENUECAT_APP_ID'); const environment = parseRevenueCatEnvironment(Deno.env.get('REVENUECAT_ENVIRONMENT')); const allowlisted = Deno.env.get('REVENUECAT_ALLOWED_USER_IDS'); const supabaseUrl = Deno.env.get('SUPABASE_URL'); const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!expectedAuth || !apiKey || !projectId || !appId || !environment || !supabaseUrl || !serviceRoleKey) return response({ error: 'server configuration unavailable' }, 500);
  if (environment === 'SANDBOX' && !allowlisted) return response({ error: 'server configuration unavailable' }, 500);
  if (request.method !== 'POST' || !constantTimeEqual(request.headers.get('Authorization') ?? '', expectedAuth)) return response({ error: 'unauthorized' }, 401);
  let userId: string; try { const body = await request.json(); userId = canonicalUuid(body?.user_id) ?? ''; } catch (_) { return response({ error: 'invalid payload' }, 400); }
  const admin = injectedAdmin ?? defaultAdminClient();
  if (!userId) return response({ error: 'invalid identity' }, 403);
  if (environment === 'SANDBOX') {
    const allowed = new Set((allowlisted ?? '').split(/[\s,]+/).filter(Boolean).map((id) => canonicalUuid(id)).filter((id): id is string => id !== null));
    if (!allowed.has(userId)) return response({ error: 'identity is not allowlisted' }, 403);
  } else {
    const { data, error } = await admin.auth.admin.getUserById(userId);
    if (error || !data.user) return response({ error: 'identity is not a Production user' }, 403);
  }
  const { data: claim, error: claimError } = await admin.rpc('claim_revenuecat_premium_sync', { p_user_id: userId, p_app_id: appId, p_environment: environment, p_allowlisted: true });
  if (claimError || !claim || typeof claim !== 'object') return response({ error: 'sync queue unavailable' }, 500);
  const claimMap = claim as Record<string, unknown>; if (claimMap.status === 'not_found') return response({ accepted: false, queued: false }); if (claimMap.status === 'in_progress') return response({ accepted: false, retry: true }, 202); if (claimMap.status !== 'claimed' || typeof claimMap.lease_token !== 'string') return response({ error: 'sync claim unavailable' }, 500);
  const token = claimMap.lease_token;
  try {
    const projection = await fetchSandboxSubscriptions(apiKey, projectId, userId, appId, environment);
    const { data, error } = await admin.rpc('apply_revenuecat_v2_reconciliation', { p_user_id: userId, p_app_id: appId, p_environment: environment, p_lease_token: token, p_subscriptions: projection.subscriptions, p_read_complete: true });
    if (error) throw new Error(`reconciliation projection unavailable:${error.code ?? 'unknown'}`);
    const { error: completeError } = await admin.rpc('complete_revenuecat_premium_sync', { p_user_id: userId, p_app_id: appId, p_environment: environment, p_lease_token: token, p_success: true, p_error_code: null });
    if (completeError) throw new Error('sync completion unavailable');
    return response({ accepted: true, status: data?.status ?? 'applied', is_active: data?.is_active ?? false });
  } catch (error) {
    const permanent = error instanceof RevenueCatHttpError && (error.status === 401 || error.status === 403);
    const errorCode = `${permanent ? 'PERMANENT:' : ''}${safeError(error)}`;
    const { error: completeError } = await admin.rpc('complete_revenuecat_premium_sync', { p_user_id: userId, p_app_id: appId, p_environment: environment, p_lease_token: token, p_success: false, p_error_code: errorCode });
    return completeError ? response({ error: 'sync completion unavailable' }, 500) : response({ error: 'reconciliation unavailable', retry: !permanent }, 502);
  }
}

if (import.meta.main) Deno.serve((request) => handleRequest(request));
