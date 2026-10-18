export type PremiumProductsShape = {
  productsType: string;
  productsIsNull: boolean;
  productsIsArray: boolean;
  hasItems: boolean;
  itemsIsArray: boolean;
  itemsLength: number | null;
};

export function premiumProductsShape(value: unknown): PremiumProductsShape {
  const productsIsNull = value === null;
  const productsIsArray = Array.isArray(value);
  const productsType = productsIsNull ? 'null' : typeof value;
  const isObject = value !== null && typeof value === 'object' && !productsIsArray;
  const hasItems = isObject && Object.prototype.hasOwnProperty.call(value, 'items');
  const items = isObject ? (value as Record<string, unknown>).items : undefined;
  const itemsIsArray = Array.isArray(items);

  return {
    productsType,
    productsIsNull,
    productsIsArray,
    hasItems,
    itemsIsArray,
    itemsLength: itemsIsArray ? items.length : null,
  };
}
