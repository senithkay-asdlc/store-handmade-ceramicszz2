import { useEffect, useState } from "react";
import { listOrders, updateOrderStatus, type Order } from "../api";

type StatusFilter = "all" | "new" | "shipped" | "delivered";

const TABS: { key: StatusFilter; label: string }[] = [
  { key: "all", label: "All" },
  { key: "new", label: "New" },
  { key: "shipped", label: "Shipped" },
  { key: "delivered", label: "Delivered" },
];

const NEXT_STATUS: Record<Order["status"], "shipped" | "delivered" | null> = {
  new: "shipped",
  shipped: "delivered",
  delivered: null,
};

/**
 * Store-Owner view of every order (ceramics-api scopes GET /orders to "all"
 * for an owner caller), with status-filter tabs and a one-step status
 * advance (new -> shipped -> delivered) via PATCH /orders/{orderId}.
 *
 * Order has no shopper-identity field in the contract, so unlike the
 * wireframe sketch this table has no "Shopper" column to show.
 */
export function OwnerOrders() {
  const [tab, setTab] = useState<StatusFilter>("all");
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  async function load(current: StatusFilter) {
    setError(null);
    try {
      setOrders(await listOrders(current === "all" ? undefined : current));
    } catch {
      setError("Could not load orders. Please try again shortly.");
    }
  }

  useEffect(() => {
    setOrders(null);
    load(tab);
  }, [tab]);

  async function handleAdvance(order: Order) {
    const next = NEXT_STATUS[order.status];
    if (!next) return;
    setUpdatingId(order.id);
    setError(null);
    try {
      await updateOrderStatus(order.id, next);
      await load(tab);
    } catch {
      setError("Could not update that order's status. Please try again.");
    } finally {
      setUpdatingId(null);
    }
  }

  return (
    <div>
      <h1>Incoming orders</h1>

      <div className="tabs">
        {TABS.map((t) => (
          <button
            key={t.key}
            className={`tab ${tab === t.key ? "tab-active" : ""}`}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {error && <p className="error-text">{error}</p>}
      {!orders && !error && <p className="status-message">Loading…</p>}

      {orders && (
        <table className="table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Total</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {orders.map((o) => {
              const next = NEXT_STATUS[o.status];
              return (
                <tr key={o.id}>
                  <td>#{o.id}</td>
                  <td>${o.total.toFixed(2)}</td>
                  <td>
                    <span className={`badge ${o.status === "delivered" ? "badge-info" : "badge-muted"}`}>
                      {o.status}
                    </span>
                  </td>
                  <td>
                    {next && (
                      <button
                        className="link-button"
                        disabled={updatingId === o.id}
                        onClick={() => handleAdvance(o)}
                      >
                        Mark {next}
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
            {orders.length === 0 && (
              <tr>
                <td colSpan={4}>No orders in this view.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
