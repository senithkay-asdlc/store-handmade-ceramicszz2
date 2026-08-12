import { useEffect, useState } from "react";
import { listOrders, type Order } from "../api";

/**
 * The signed-in Shopper's own order history. ceramics-api scopes GET /orders
 * to the caller's own orders server-side via the gateway-injected X-User-Id —
 * this page passes no shopper filter of its own.
 */
export function MyOrders() {
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listOrders()
      .then(setOrders)
      .catch(() => setError("Could not load your orders. Please try again shortly."));
  }, []);

  return (
    <div>
      <h1>My orders</h1>
      {error && <p className="error-text">{error}</p>}
      {!orders && !error && <p className="status-message">Loading…</p>}
      {orders && orders.length === 0 && <p>You haven&apos;t placed any orders yet.</p>}

      {orders && orders.length > 0 && (
        <table className="table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Placed</th>
              <th>Total</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((o) => (
              <tr key={o.id}>
                <td>#{o.id}</td>
                <td>{new Date(o.createdAt).toLocaleDateString()}</td>
                <td>${o.total.toFixed(2)}</td>
                <td>
                  <span className={`badge ${o.status === "delivered" ? "badge-info" : "badge-muted"}`}>
                    {o.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
