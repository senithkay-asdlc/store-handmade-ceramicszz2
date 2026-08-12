const CART_ID_KEY = "ceramics_cart_id";

/**
 * ceramics-api has no "create cart" endpoint — only GET/POST items/DELETE item
 * on /carts/{cartId} — so the cart id is generated and persisted client-side.
 */
export function getOrCreateCartId(): string {
  let id = localStorage.getItem(CART_ID_KEY);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(CART_ID_KEY, id);
  }
  return id;
}

/** Called after a successful checkout so the next add-to-cart starts a fresh cart. */
export function resetCartId(): void {
  localStorage.removeItem(CART_ID_KEY);
}

/** Flat-rate shipping shown pre-checkout; the real fee is authoritative on the created Order. */
export const FLAT_SHIPPING_FEE = 8;
