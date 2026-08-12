import { useEffect, useState, type FormEvent } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { createProduct, getProduct, removeProduct, updateProduct } from "../api";

/** Store-Owner create/edit form — edit mode when :productId is present in the route. */
export function OwnerProductForm() {
  const { productId } = useParams<{ productId: string }>();
  const isEdit = Boolean(productId);
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [loading, setLoading] = useState(isEdit);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!productId) return;
    setLoading(true);
    getProduct(productId)
      .then((p) => {
        setName(p.name);
        setDescription(p.description ?? "");
        setPrice(String(p.price));
        setImageUrl(p.imageUrl ?? "");
      })
      .catch(() => setError("Could not load this listing."))
      .finally(() => setLoading(false));
  }, [productId]);

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);

    const parsedPrice = Number(price);
    if (!name.trim() || Number.isNaN(parsedPrice) || parsedPrice <= 0) {
      setError("Enter a name and a valid price.");
      return;
    }

    setSaving(true);
    try {
      const input = {
        name: name.trim(),
        description: description.trim() || undefined,
        price: parsedPrice,
        imageUrl: imageUrl.trim() || undefined,
      };
      if (productId) {
        await updateProduct(productId, input);
      } else {
        await createProduct(input);
      }
      navigate("/owner");
    } catch {
      setError("Could not save this listing. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  async function handleRemove() {
    if (!productId) return;
    if (!window.confirm("Remove this listing? This cannot be undone.")) return;
    setSaving(true);
    setError(null);
    try {
      await removeProduct(productId);
      navigate("/owner");
    } catch {
      setError("Could not remove this listing. Please try again.");
      setSaving(false);
    }
  }

  if (loading) {
    return <p className="status-message">Loading…</p>;
  }

  return (
    <div>
      <p className="breadcrumb">Catalog / {isEdit ? name || "Edit listing" : "New listing"}</p>
      <h1>{isEdit ? "Edit listing" : "New listing"}</h1>

      <form className="card" onSubmit={handleSubmit}>
        <label className="form-field">
          Name
          <input required value={name} onChange={(e) => setName(e.target.value)} />
        </label>

        <label className="form-field">
          Description
          <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={4} />
        </label>

        <label className="form-field">
          Price
          <input
            required
            type="number"
            min="0"
            step="0.01"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
          />
        </label>

        <label className="form-field">
          Product photo URL
          <input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://…" />
        </label>
        {imageUrl && <img src={imageUrl} alt="Preview" className="thumb" />}

        {error && <p className="error-text">{error}</p>}

        <div className="row-end">
          <button type="button" className="link-button" onClick={() => navigate("/owner")}>
            Cancel
          </button>
          {isEdit && (
            <button type="button" className="link-button" disabled={saving} onClick={handleRemove}>
              Remove
            </button>
          )}
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? "Saving…" : "Save"}
          </button>
        </div>
      </form>
    </div>
  );
}
