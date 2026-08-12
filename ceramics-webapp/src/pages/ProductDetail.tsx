import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { addCartItem, getProduct, type Product } from "../api";
import { getOrCreateCartId } from "../cart";

export function ProductDetail() {
  const { productId } = useParams<{ productId: string }>();
  const navigate = useNavigate();
  const [product, setProduct] = useState<Product | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    if (!productId) return;
    setProduct(null);
    setError(null);
    getProduct(productId).catch(() => setError("This piece could not be found.")).then((p) => {
      if (p) setProduct(p);
    });
  }, [productId]);

  async function handleAddToCart() {
    if (!productId) return;
    setAdding(true);
    setError(null);
    try {
      await addCartItem(getOrCreateCartId(), productId);
      navigate("/cart");
    } catch {
      setError("Could not add this piece to your cart — it may already be sold.");
    } finally {
      setAdding(false);
    }
  }

  if (error && !product) {
    return (
      <div>
        <p className="error-text">{error}</p>
        <Link to="/">Back to catalog</Link>
      </div>
    );
  }

  if (!product) {
    return <p className="status-message">Loading…</p>;
  }

  return (
    <div>
      <p className="breadcrumb">
        <Link to="/">Shop</Link> / {product.name}
      </p>
      <div className="detail-row">
        {product.imageUrl && <img src={product.imageUrl} alt={product.name} className="detail-image" />}
        <div className="card detail-card">
          <h1>{product.name}</h1>
          <span className={`badge ${product.status === "available" ? "badge-info" : "badge-muted"}`}>
            {product.status === "available" ? "One of a kind" : "Sold"}
          </span>
          <p className="price">${product.price.toFixed(2)}</p>
          {product.description && <p>{product.description}</p>}
          {error && <p className="error-text">{error}</p>}
          <div className="row-end">
            <button
              className="btn-primary"
              disabled={adding || product.status !== "available"}
              onClick={handleAddToCart}
            >
              {product.status === "available" ? (adding ? "Adding…" : "Add to cart") : "Sold"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
