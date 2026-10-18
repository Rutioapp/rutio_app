import { assertEquals, assertNotEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { premiumProductsShape } from './diagnostics.ts';

Deno.test('reports only structural metadata for malformed products', () => {
  const result = premiumProductsShape({
    items: [{ id: 'sensitive-product-id', app_id: 'sensitive-app-id' }],
    next_page: 'https://api.revenuecat.com/sensitive-pagination-url',
  });

  assertEquals(result, {
    productsType: 'object',
    productsIsNull: false,
    productsIsArray: false,
    hasItems: true,
    itemsIsArray: true,
    itemsLength: 1,
  });
  assertNotEquals(JSON.stringify(result), JSON.stringify({
    products: {
      items: [{ id: 'sensitive-product-id', app_id: 'sensitive-app-id' }],
      next_page: 'https://api.revenuecat.com/sensitive-pagination-url',
    },
  }));
});

Deno.test('classifies null, arrays and missing items without reading contents', () => {
  assertEquals(premiumProductsShape(null), {
    productsType: 'null',
    productsIsNull: true,
    productsIsArray: false,
    hasItems: false,
    itemsIsArray: false,
    itemsLength: null,
  });
  assertEquals(premiumProductsShape([]), {
    productsType: 'object',
    productsIsNull: false,
    productsIsArray: true,
    hasItems: false,
    itemsIsArray: false,
    itemsLength: null,
  });
  assertEquals(premiumProductsShape({ next_page: null }), {
    productsType: 'object',
    productsIsNull: false,
    productsIsArray: false,
    hasItems: false,
    itemsIsArray: false,
    itemsLength: null,
  });
});
