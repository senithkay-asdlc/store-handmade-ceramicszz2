import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { listAvailableProducts, removeProduct, type Product } from "../api";

/**
 * Store-Owner catalog management. ceramics-api's only listing endpoint
 * (GET /products) returns unsold products — there is no "list everything
 * including sold" endpoint in the contract, so a listing that sells out
 * drops out of this view too rather than this page inventing one.
 */
export function OwnerCatalog() {
  const [products, setProducts] = useState<Product[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [removingId, setRemovingId] = useState<string | null>(null);

  async function load() {
    try {
      setProducts(await listAvailableProducts());
    } catch {
      setError("Could not load the catalog. Please try again shortly.");
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleRemove(productId: string) {
    if (!window.confirm("Remove this listing? This cannot be undone.")) return;
    setRemovingId(productId);
    setError(null);
    try {
      await removeProduct(productId);
      await load();
    } catch {
      setError("Could not remove that listing. Please try again.");
    } finally {
      setRemovingId(null);
    }
  }

  return (
    <div>
      <div className="row-between">
        <h1>Manage catalog</h1>
        <Link to="/owner/new" className="btn-primary">
          New listing
        </Link>
      </div>

      {error && <p className="error-text">{error}</p>}
      {!products && !error && <p className="status-message">Loading…</p>}

      {products && (
        <table className="table">
          <thead>
            <tr>
              <th>Piece</th>
              <th>Price</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {products.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td>${p.price.toFixed(2)}</td>
                <td>
                  <span className={`badge ${p.status === "available" ? "badge-info" : "badge-muted"}`}>
                    {p.status === "available" ? "Available" : "Sold"}
                  </span>
                </td>
                <td className="owner-actions">
                  <Link to={`/owner/${p.id}/edit`} className="link-button">
                    Edit
                  </Link>
                  <button
                    className="link-button"
                    disabled={removingId === p.id}
                    onClick={() => handleRemove(p.id)}
                  >
                    Remove
                  </button>
                </td>
              </tr>
            ))}
            {products.length === 0 && (
              <tr>
                <td colSpan={4}>No listings yet — add your first piece.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
