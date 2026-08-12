import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { listAvailableProducts, type Product } from "../api";

export function Catalog() {
  const [products, setProducts] = useState<Product[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  useEffect(() => {
    listAvailableProducts()
      .then(setProducts)
      .catch(() => setError("Could not load the catalog. Please try again shortly."));
  }, []);

  const filtered = useMemo(() => {
    if (!products) return [];
    const q = search.trim().toLowerCase();
    if (!q) return products;
    return products.filter(
      (p) => p.name.toLowerCase().includes(q) || (p.description ?? "").toLowerCase().includes(q),
    );
  }, [products, search]);

  return (
    <div>
      <div className="row-between">
        <h1>Handpicked, one-of-a-kind pieces</h1>
        <input
          className="search-input"
          placeholder="Search pieces…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {error && <p className="error-text">{error}</p>}

      {products && (
        <div className="card summary-card">
          Available pieces: <strong>{products.length}</strong>
        </div>
      )}

      <h2>Available now</h2>
      {!products && !error && <p className="status-message">Loading pieces…</p>}
      <div className="grid">
        {filtered.map((p) => (
          <Link key={p.id} to={`/products/${p.id}`} className="card product-card">
            {p.imageUrl && <img src={p.imageUrl} alt={p.name} className="thumb" />}
            <h3>{p.name}</h3>
            <p className="price">${p.price.toFixed(2)}</p>
            <p className="muted">One of a kind</p>
          </Link>
        ))}
        {products && filtered.length === 0 && <p>No pieces match your search.</p>}
      </div>
    </div>
  );
}
