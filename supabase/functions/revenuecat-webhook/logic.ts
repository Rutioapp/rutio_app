export type RevenueCatEntitlement = {
  expires_date: string | null;
  product_identifier?: string | null;
  purchase_date?: string | null;
};

export type PremiumProjection = {
  active: boolean;
  expiresAt: string | null;
  productId: string | null;
  snapshotAt: string | null;
  snapshotReliable: boolean;
  sandboxVerified: boolean;
  subscriptions: Array<{
    subscriptionKey: string;
    productId: string | null;
    store: string | null;
    isActive: boolean;
    startsAt: string | null;
    expiresAt: string | null;
  }>;
};

const SNAPSHOT_TIME_TOLERANCE_MS = 2000;

function snapshotTime(value: unknown, field: string): number | null {
  if (value === undefined || value === null) return null;
  if (field === 'request_date_ms') {
    if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) throw new Error('malformed RevenueCat snapshot time');
    return value;
  }
  if (typeof value !== 'string' || Number.isNaN(Date.parse(value))) throw new Error('malformed RevenueCat snapshot time');
  return Date.parse(value);
}

export function parseCustomerHttpResponse(status: number, value: unknown, now = Date.now()): PremiumProjection {
  if (status === 404) throw new Error('RevenueCat subscriber not found');
  if (status >= 500) throw new Error('RevenueCat temporary API failure');
  if (status < 200 || status >= 300) throw new Error(`RevenueCat API status ${status}`);
  return parseCustomerInfo(value, now);
}

export function parseCustomerInfo(value: unknown, now = Date.now()): PremiumProjection {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('malformed RevenueCat response');
  const root = value as Record<string, unknown>;
  const requestDateMs = snapshotTime(root.request_date_ms, 'request_date_ms');
  const requestDate = snapshotTime(root.request_date, 'request_date');
  if (requestDateMs !== null && requestDate !== null && Math.abs(requestDateMs - requestDate) > SNAPSHOT_TIME_TOLERANCE_MS) {
    throw new Error('contradictory RevenueCat snapshot time');
  }
  const observedAt = requestDateMs ?? requestDate;
  const subscriber = (value as Record<string, unknown>).subscriber;
  if (!subscriber || typeof subscriber !== 'object' || Array.isArray(subscriber)) throw new Error('malformed RevenueCat subscriber');
  const entitlements = (subscriber as Record<string, unknown>).entitlements;
  if (!entitlements || typeof entitlements !== 'object' || Array.isArray(entitlements)) throw new Error('malformed RevenueCat entitlements');
  const premium = (entitlements as Record<string, unknown>).premium;
  if (premium === undefined) return { active: false, expiresAt: null, productId: null, snapshotAt: observedAt === null ? null : new Date(observedAt).toISOString(), snapshotReliable: observedAt !== null, sandboxVerified: false, subscriptions: [] };
  if (!premium || typeof premium !== 'object' || Array.isArray(premium)) throw new Error('malformed RevenueCat premium entitlement');
  const expires = (premium as Record<string, unknown>).expires_date;
  if (expires !== null && typeof expires !== 'string') throw new Error('malformed RevenueCat expiry');
  if (expires !== null && Number.isNaN(Date.parse(expires))) throw new Error('malformed RevenueCat expiry');
  const productId = (premium as Record<string, unknown>).product_identifier;
  if (productId !== undefined && productId !== null && typeof productId !== 'string') throw new Error('malformed RevenueCat product');
  const subscriptions = (subscriber as Record<string, unknown>).subscriptions;
  const sandboxVerified = typeof productId === 'string'
    && !!subscriptions && typeof subscriptions === 'object' && !Array.isArray(subscriptions)
    && !!(subscriptions as Record<string, unknown>)[productId]
    && typeof (subscriptions as Record<string, unknown>)[productId] === 'object'
    && (subscriptions as Record<string, Record<string, unknown>>)[productId].is_sandbox === true;
  return {
    active: expires === null || Date.parse(expires) > now,
    expiresAt: expires,
    productId: productId ?? null,
    snapshotAt: observedAt === null ? null : new Date(observedAt).toISOString(),
    snapshotReliable: observedAt !== null,
    sandboxVerified,
    subscriptions: [],
  };
}

export function parseAllowedUserIds(value: unknown): Set<string> | null {
  if (typeof value !== 'string' || !value.trim()) return null;
  const values = value.split(/[\s,]+/).filter(Boolean).map((item) => canonicalUuid(item));
  if (values.length === 0 || values.some((item) => item === null)) return null;
  return new Set(values as string[]);
}

export type RevenueCatEnvironment = 'SANDBOX' | 'PRODUCTION';

export function parseRevenueCatEnvironment(value: unknown): RevenueCatEnvironment | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim().toUpperCase();
  return normalized === 'SANDBOX' || normalized === 'PRODUCTION' ? normalized : null;
}

export function isExpectedRevenueCatEnvironment(value: unknown, expectedEnvironment: RevenueCatEnvironment): boolean {
  return typeof value === 'string' && value.trim().toUpperCase() === expectedEnvironment;
}

export function isExpectedWebhookEnvironment(value: unknown, expectedEnvironment: RevenueCatEnvironment): boolean {
  return typeof value === 'string' && value.trim() === expectedEnvironment;
}

export function isSandboxWebhookEnvironment(value: unknown, expectedEnvironment: string): boolean {
  return expectedEnvironment === 'SANDBOX' && isExpectedWebhookEnvironment(value, 'SANDBOX');
}

export function areIdentitiesAllowed(event: Record<string, unknown>, allowedUserIds: Set<string>): boolean {
  const identities = classifyTransferIdentities(event);
  return identities.internalIds.length > 0
    && identities.unresolvedIds.length === 0
    && identities.internalIds.every((id) => allowedUserIds.has(id));
}

export function productionIdentityIds(event: Record<string, unknown>): string[] | null {
  const primary = canonicalUuid(event.app_user_id);
  const identities = classifyTransferIdentities(event);
  if (!primary || identities.internalIds.length === 0 || identities.unresolvedIds.length > 0) return null;
  if (identities.internalIds[0] !== primary) return null;
  return identities.internalIds;
}

export async function productionIdentitiesExist(
  identities: string[],
  exists: (userId: string) => Promise<boolean>,
): Promise<boolean> {
  for (const userId of identities) if (!(await exists(userId))) return false;
  return true;
}

export function parseSandboxSubscriptionPages(value: unknown, observedAt: string | null, expectedAppId = '', expectedEnvironment: RevenueCatEnvironment = 'SANDBOX'): PremiumProjection {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('malformed RevenueCat v2 subscription page');
  const page = value as Record<string, unknown>;
  if (page.object !== 'list' || !Array.isArray(page.items)) throw new Error('malformed RevenueCat v2 subscription page');
  if (page.next_page !== undefined && page.next_page !== null && typeof page.next_page !== 'string') throw new Error('malformed RevenueCat v2 pagination');
  let active = false;
  let expiresAt: string | null = null;
  let productId: string | null = null;
  const subscriptions: PremiumProjection['subscriptions'] = [];
  for (const raw of page.items) {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('malformed RevenueCat v2 subscription');
    const item = raw as Record<string, unknown>;
    if (!isExpectedRevenueCatEnvironment(item.environment, expectedEnvironment)) throw new Error('RevenueCat v2 subscription environment mismatch');
    if (typeof item.gives_access !== 'boolean') throw new Error('malformed RevenueCat v2 access state');
    const entitlements = item.entitlements;
    if (!entitlements || typeof entitlements !== 'object' || Array.isArray(entitlements)) throw new Error('malformed RevenueCat v2 entitlements');
    if ((entitlements as Record<string, unknown>).next_page !== null && (entitlements as Record<string, unknown>).next_page !== undefined) throw new Error('incomplete RevenueCat v2 entitlement pagination');
    const entitlementItems = (entitlements as Record<string, unknown>).items;
    if (!Array.isArray(entitlementItems)) throw new Error('malformed RevenueCat v2 entitlement list');
    for (const rawEntitlement of entitlementItems) {
      if (!rawEntitlement || typeof rawEntitlement !== 'object' || Array.isArray(rawEntitlement)) throw new Error('malformed RevenueCat v2 entitlement');
      const entitlement = rawEntitlement as Record<string, unknown>;
      if (entitlement.lookup_key !== 'premium') continue;
      if (entitlement.state !== 'active' && entitlement.state !== 'expired') throw new Error('ambiguous RevenueCat v2 premium state');
      const products = entitlement.products;
      const productItems = products && typeof products === 'object' && !Array.isArray(products) ? (products as Record<string, unknown>).items : null;
      if (!Array.isArray(productItems)) throw new Error('malformed RevenueCat v2 premium products');
      if (products && typeof products === 'object' && !Array.isArray(products) && (products as Record<string, unknown>).next_page !== null && (products as Record<string, unknown>).next_page !== undefined) throw new Error('incomplete RevenueCat v2 product pagination');
      const matchingProduct = productItems.find((rawProduct) => {
        if (!rawProduct || typeof rawProduct !== 'object' || Array.isArray(rawProduct)) return false;
        const product = rawProduct as Record<string, unknown>;
        return product.id === item.product_id && product.app_id === expectedAppId;
      });
      if (!matchingProduct) throw new Error('RevenueCat v2 premium app association unavailable');
      const end = item.ends_at ?? item.current_period_ends_at;
      if (end !== null && end !== undefined && (typeof end !== 'number' || !Number.isFinite(end) || end <= 0)) throw new Error('malformed RevenueCat v2 expiry');
      if (typeof end === 'number' && (!expiresAt || end > Date.parse(expiresAt))) expiresAt = new Date(end).toISOString();
      if (typeof item.product_id === 'string') productId = item.product_id;
      if (item.gives_access === true && entitlement.state === 'active') active = true;
      const subscriptionKey = typeof item.id === 'string' && item.id.trim()
        ? item.id.trim()
        : typeof item.product_id === 'string' && item.product_id.trim()
          ? item.product_id.trim()
          : null;
      if (!subscriptionKey) throw new Error('malformed RevenueCat v2 subscription identity');
      const starts = item.starts_at ?? item.current_period_starts_at;
      if (starts !== null && starts !== undefined && (typeof starts !== 'number' || !Number.isFinite(starts) || starts <= 0)) throw new Error('malformed RevenueCat v2 start');
      subscriptions.push({
        subscriptionKey,
        productId: typeof item.product_id === 'string' ? item.product_id : null,
        store: typeof item.store === 'string' ? item.store : null,
        isActive: item.gives_access === true && entitlement.state === 'active',
        startsAt: typeof starts === 'number' ? new Date(starts).toISOString() : null,
        expiresAt: typeof end === 'number' ? new Date(end).toISOString() : null,
      });
    }
  }
  return { active, expiresAt, productId, snapshotAt: observedAt, snapshotReliable: observedAt !== null, sandboxVerified: expectedEnvironment === 'SANDBOX', subscriptions };
}

export function canonicalUuid(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim().toLowerCase();
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(normalized) ? normalized : null;
}

export function eventIds(event: Record<string, unknown>): string[] {
  const ids = new Set<string>();
  if (typeof event.app_user_id === 'string') ids.add(event.app_user_id.trim().toLowerCase());
  for (const field of ['transferred_from', 'transferred_to']) {
    const values = event[field];
    if (Array.isArray(values)) for (const value of values) if (typeof value === 'string') ids.add(value.trim().toLowerCase());
  }
  return [...ids];
}

export function classifyTransferIdentities(event: Record<string, unknown>): { internalIds: string[]; unresolvedIds: string[] } {
  const internalIds: string[] = [];
  const unresolvedIds: string[] = [];
  for (const id of eventIds(event)) {
    if (canonicalUuid(id)) internalIds.push(id);
    else unresolvedIds.push(id);
  }
  return { internalIds, unresolvedIds };
}
