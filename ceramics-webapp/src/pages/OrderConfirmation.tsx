import { useNavigate, useLocation, Link } from "react-router-dom";
import type { Order } from "../api";

/**
 * Shown immediately after a successful checkout. The just-created Order is
 * handed in via router state (Checkout navigates here with `{ order }`) so no
 * extra round trip is needed; a direct/refreshed visit with no state falls
 * back to pointing the shopper at MyOrders instead of guessing an id.
 */
export function OrderConfirmation() {
  const navigate = useNavigate();
  const location = useLocation();
  const order = (location.state as { order?: Order } | null)?.order;

  if (!order) {
    return (
      <div>
        <h1>Order confirmed</h1>
        <p>We could not find the details of your most recent order on this page.</p>
        <Link to="/my-orders">View my orders</Link>
      </div>
    );
  }

  return (
    <div>
      <h1>Order confirmed</h1>
      <span className="badge badge-info">{order.status === "new" ? "New" : order.status}</span>
      <p>
        Order #{order.id} — placed {new Date(order.createdAt).toLocaleString()}.
      </p>

      <table className="table">
        <thead>
          <tr>
            <th>Piece</th>
            <th>Price</th>
          </tr>
        </thead>
        <tbody>
          {order.items.map((item) => (
            <tr key={item.productId}>
              <td>{item.name}</td>
              <td>${item.price.toFixed(2)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <p className="row-end totals">Total: ${order.total.toFixed(2)}</p>

      <div className="row-end">
        <button className="btn-primary" onClick={() => navigate("/my-orders")}>
          View my orders
        </button>
      </div>
    </div>
  );
}
