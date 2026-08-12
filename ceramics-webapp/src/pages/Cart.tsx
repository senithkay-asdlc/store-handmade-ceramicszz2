import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { getCart, removeCartItem, type Cart as CartType } from "../api";
import { FLAT_SHIPPING_FEE, getOrCreateCartId } from "../cart";

export function Cart() {
  const navigate = useNavigate();
  const [cart, setCart] = useState<CartType | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [removingId, setRemovingId] = useState<string | null>(null);

  async function load() {
    try {
      const c = await getCart(getOrCreateCartId());
      setCart(c ?? { id: getOrCreateCartId(), items: [] });
    } catch {
      setError("Could not load your cart. Please try again shortly.");
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleRemove(productId: string) {
    setRemovingId(productId);
    setError(null);
    try {
      const updated = await removeCartItem(getOrCreateCartId(), productId);
      setCart(updated);
    } catch {
      setError("Could not remove that item. Please try again.");
    } finally {
      setRemovingId(null);
    }
  }

  const items = cart?.items ?? [];
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  const shipping = items.length > 0 ? FLAT_SHIPPING_FEE : 0;
  const total = subtotal + shipping;

  return (
    <div>
      <h1>Your cart</h1>
      {error && <p className="error-text">{error}</p>}
      {!cart && !error && <p className="status-message">Loading…</p>}

      {cart && items.length === 0 && <p>Your cart is empty.</p>}

      {cart && items.length > 0 && (
        <>
          <table className="table">
            <thead>
              <tr>
                <th>Piece</th>
                <th>Price</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.productId}>
                  <td>{item.name}</td>
                  <td>${item.price.toFixed(2)}</td>
                  <td>
                    <button
                      className="link-button"
                      disabled={removingId === item.productId}
                      onClick={() => handleRemove(item.productId)}
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <p className="row-end totals">
            Subtotal: ${subtotal.toFixed(2)} · Shipping: ${shipping.toFixed(2)} · Total: ${total.toFixed(2)}
          </p>

          <div className="row-end">
            <button className="btn-primary" onClick={() => navigate("/checkout")}>
              Continue to checkout
            </button>
          </div>
        </>
      )}
    </div>
  );
}
