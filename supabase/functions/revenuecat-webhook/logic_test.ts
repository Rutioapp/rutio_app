import { assertEquals, assertThrows } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { areIdentitiesAllowed, canonicalUuid, classifyTransferIdentities, eventIds, isExpectedRevenueCatEnvironment, isExpectedWebhookEnvironment, isSandboxWebhookEnvironment, parseAllowedUserIds, parseCustomerHttpResponse, parseCustomerInfo, parseRevenueCatEnvironment, parseSandboxSubscriptionPages, productionIdentitiesExist, productionIdentityIds } from './logic.ts';

const now = Date.parse('2026-10-12T12:00:00.000Z');

Deno.test('parses active sandbox premium only with sandbox subscription evidence', () => {
  assertEquals(parseCustomerInfo({ request_date_ms: 1791892800000, request_date: '2026-10-13T12:00:00.000Z', subscriber: { subscriptions: { 'rutio.monthly': { is_sandbox: true } }, entitlements: { premium: { expires_date: '2026-10-13T12:00:00.000Z', product_identifier: 'rutio.monthly' } } } }, now).active, true);
});
Deno.test('parses expired and absent premium as verified inactive', () => {
  assertEquals(parseCustomerInfo({ request_date: '2026-10-13T12:00:00.000Z', subscriber: { entitlements: { premium: { expires_date: '2026-10-11T12:00:00.000Z' } } } }, now).active, false);
  assertEquals(parseCustomerInfo({ subscriber: { entitlements: {} } }, now).subscriptions, []);
});
Deno.test('rejects malformed or incomplete customer responses', () => {
  assertThrows(() => parseCustomerInfo({ entitlements: {} }, now));
  assertThrows(() => parseCustomerInfo({ subscriber: { entitlements: { premium: { expires_date: 123 } } } }, now));
  assertThrows(() => parseCustomerInfo({ request_date_ms: 1, request_date: '2026-10-13T12:00:10.000Z', subscriber: { entitlements: {} } }, now));
  assertThrows(() => parseCustomerInfo({ request_date_ms: 'bad', subscriber: { entitlements: {} } }, now));
});
Deno.test('does not convert 404 or temporary API failures into Free', () => {
  assertThrows(() => parseCustomerHttpResponse(404, {}, now), Error, 'subscriber not found');
  assertThrows(() => parseCustomerHttpResponse(503, {}, now), Error, 'temporary API failure');
  assertThrows(() => parseCustomerHttpResponse(200, { subscriber: {} }, now), Error, 'malformed RevenueCat entitlements');
});
Deno.test('canonicalizes only UUID identities and includes transfer endpoints', () => {
  assertEquals(canonicalUuid('550e8400-e29b-41d4-a716-446655440000'), '550e8400-e29b-41d4-a716-446655440000');
  assertEquals(canonicalUuid('anonymous'), null);
  assertEquals(eventIds({ app_user_id: 'A', transferred_from: ['B'], transferred_to: ['C'] }), ['a', 'b', 'c']);
});
Deno.test('classifies non-UUID transfer aliases as unresolved', () => {
  assertEquals(classifyTransferIdentities({
    app_user_id: '550e8400-e29b-41d4-a716-446655440000',
    transferred_from: ['external-alias'],
    transferred_to: ['550e8400-e29b-41d4-a716-446655440001'],
  }), {
    internalIds: ['550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440001'],
    unresolvedIds: ['external-alias'],
  });
});
Deno.test('validates the explicit allowlist format', () => {
  assertEquals(parseAllowedUserIds('550e8400-e29b-41d4-a716-446655440000\n550e8400-e29b-41d4-a716-446655440001')?.size, 2);
  assertEquals(parseAllowedUserIds(''), null);
  assertEquals(parseAllowedUserIds('not-a-uuid'), null);
});
Deno.test('accepts only Sandbox webhook environment', () => {
  assertEquals(isSandboxWebhookEnvironment('SANDBOX', 'SANDBOX'), true);
  assertEquals(isSandboxWebhookEnvironment('PRODUCTION', 'SANDBOX'), false);
  assertEquals(isSandboxWebhookEnvironment('SANDBOX', 'PRODUCTION'), false);
});
Deno.test('accepts only the explicitly configured RevenueCat environment', () => {
  assertEquals(parseRevenueCatEnvironment('SANDBOX'), 'SANDBOX');
  assertEquals(parseRevenueCatEnvironment(' production '), 'PRODUCTION');
  assertEquals(parseRevenueCatEnvironment(''), null);
  assertEquals(parseRevenueCatEnvironment('staging'), null);
  assertEquals(isExpectedRevenueCatEnvironment('PRODUCTION', 'PRODUCTION'), true);
  assertEquals(isExpectedRevenueCatEnvironment('SANDBOX', 'PRODUCTION'), false);
  assertEquals(isExpectedWebhookEnvironment('PRODUCTION', 'PRODUCTION'), true);
  assertEquals(isExpectedWebhookEnvironment('production', 'PRODUCTION'), false);
});
Deno.test('requires every transfer identity to be allowlisted', () => {
  const allowed = new Set(['550e8400-e29b-41d4-a716-446655440000']);
  assertEquals(areIdentitiesAllowed({ app_user_id: '550e8400-e29b-41d4-a716-446655440000' }, allowed), true);
  assertEquals(areIdentitiesAllowed({ app_user_id: '550e8400-e29b-41d4-a716-446655440000', transferred_to: ['550e8400-e29b-41d4-a716-446655440001'] }, allowed), false);
  assertEquals(areIdentitiesAllowed({ app_user_id: 'external-alias' }, allowed), false);
});
Deno.test('Production identity validation requires the primary UUID and rejects aliases', async () => {
  const primary = '550e8400-e29b-41d4-a716-446655440000';
  const transfer = '550e8400-e29b-41d4-a716-446655440001';
  assertEquals(productionIdentityIds({ app_user_id: primary }), [primary]);
  assertEquals(productionIdentityIds({ app_user_id: primary, transferred_to: [transfer] }), [primary, transfer]);
  assertEquals(productionIdentityIds({ app_user_id: primary, transferred_from: ['external-alias'] }), null);
  assertEquals(productionIdentityIds({ app_user_id: 'external-alias' }), null);
  assertEquals(await productionIdentitiesExist([primary, transfer], async (id) => id !== transfer), false);
  assertEquals(await productionIdentitiesExist([primary, transfer], async () => true), true);
});
Deno.test('does not verify Sandbox when the matching subscription is production or absent', () => {
  const production = parseCustomerInfo({ subscriber: { subscriptions: { 'rutio.monthly': { is_sandbox: false } }, entitlements: { premium: { expires_date: '2026-10-13T12:00:00.000Z', product_identifier: 'rutio.monthly' } } } }, now);
  const ambiguous = parseCustomerInfo({ subscriber: { entitlements: { premium: { expires_date: '2026-10-13T12:00:00.000Z', product_identifier: 'rutio.monthly' } } } }, now);
  assertEquals(production.sandboxVerified, false);
  assertEquals(ambiguous.sandboxVerified, false);
});
Deno.test('parses active Sandbox v2 premium subscription', () => {
  const result = parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'sandbox', product_id: 'premium.monthly', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.monthly', app_id: 'app-staging' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging');
  assertEquals(result.active, true);
  assertEquals(result.sandboxVerified, true);
  assertEquals(result.productId, 'premium.monthly');
});
Deno.test('parses active Production v2 premium subscription only when configured for Production', () => {
  const result = parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'production', product_id: 'premium.monthly', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.monthly', app_id: 'app-production' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-production', 'PRODUCTION');
  assertEquals(result.active, true);
  assertEquals(result.sandboxVerified, false);
  assertThrows(() => parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'sandbox', product_id: 'premium.monthly', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.monthly', app_id: 'app-production' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-production', 'PRODUCTION'));
});
Deno.test('rejects a premium Sandbox subscription without the products relation', () => {
  assertThrows(
    () => parseSandboxSubscriptionPages({
      object: 'list',
      items: [{
        environment: 'sandbox',
        product_id: 'premium.monthly',
        gives_access: true,
        ends_at: 1791892800000,
        entitlements: {
          items: [{ lookup_key: 'premium', state: 'active' }],
        },
      }],
      next_page: null,
    }, '2026-10-13T12:00:00.000Z', 'app-staging'),
    Error,
    'malformed RevenueCat v2 premium products',
  );
});
Deno.test('handles expired and cancelled-but-current Sandbox subscriptions', () => {
  const expired = parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'sandbox', product_id: 'premium.monthly', gives_access: false, ends_at: 1791806400000, entitlements: { items: [{ lookup_key: 'premium', state: 'expired', products: { items: [{ id: 'premium.monthly', app_id: 'app-staging' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging');
  const cancelled = parseSandboxSubscriptionPages({ object: 'list', product_id: 'premium.monthly', items: [{ environment: 'sandbox', product_id: 'premium.monthly', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.monthly', app_id: 'app-staging' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging');
  assertEquals(expired.active, false);
  assertEquals(cancelled.active, true);
  const noSubscriptions = parseSandboxSubscriptionPages({ object: 'list', items: [], next_page: null }, null, 'app-staging');
  assertEquals(noSubscriptions.active, false);
  assertEquals(noSubscriptions.subscriptions, []);
});
Deno.test('rejects Production or unsupported v2 subscription evidence', () => {
  assertThrows(() => parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'production', product_id: 'premium.monthly', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.monthly', app_id: 'app-staging' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging'));
  const unrelated = parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'sandbox', product_id: 'other', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'other', state: 'active', products: { items: [] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging');
  assertEquals(unrelated.active, false);
});
Deno.test('supports multiple Sandbox subscriptions and rejects malformed pages', () => {
  const result = parseSandboxSubscriptionPages({ object: 'list', items: [
    { environment: 'sandbox', product_id: 'premium.old', gives_access: false, ends_at: 1791806400000, entitlements: { items: [{ lookup_key: 'premium', state: 'expired', products: { items: [{ id: 'premium.old', app_id: 'app-staging' }] } }] } },
    { environment: 'sandbox', product_id: 'premium.new', gives_access: true, ends_at: 1791892800000, entitlements: { items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.new', app_id: 'app-staging' }] } }] } },
  ], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging');
  assertEquals(result.active, true);
  assertThrows(() => parseSandboxSubscriptionPages({ object: 'list', items: [], next_page: 42 }, '2026-10-13T12:00:00.000Z'));
});
Deno.test('rejects incomplete nested v2 pagination instead of projecting a partial snapshot', () => {
  assertThrows(() => parseSandboxSubscriptionPages({ object: 'list', items: [{ environment: 'sandbox', product_id: 'premium.monthly', gives_access: true, ends_at: 1791892800000, entitlements: { next_page: '/v2/next', items: [{ lookup_key: 'premium', state: 'active', products: { items: [{ id: 'premium.monthly', app_id: 'app-staging' }] } }] } }], next_page: null }, '2026-10-13T12:00:00.000Z', 'app-staging'));
});
