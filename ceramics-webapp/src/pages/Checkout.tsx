import { useEffect, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../AuthContext";
import { ApiRequestError, createOrder, getCart, type Cart as CartType } from "../api";
import { FLAT_SHIPPING_FEE, getOrCreateCartId, resetCartId } from "../cart";

/**
 * Reached only through RequireAuth, so an active Thunder session is already
 * guaranteed by the time this renders. No real payment processor is wired up
 * here — the entered card fields are packed into the OrderInput `paymentToken`
 * string exactly as ceramics-api's contract expects; the API decides decline
 * vs. success.
 */
export function Checkout() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [cart, setCart] = useState<CartType | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [shippingAddress, setShippingAddress] = useState("");
  const [cardholderName, setCardholderName] = useState("");
  const [cardNumber, setCardNumber] = useState("");
  const [expiry, setExpiry] = useState("");
  const [cvc, setCvc] = useState("");

  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  useEffect(() => {
    getCart(getOrCreateCartId())
      .then((c) => setCart(c ?? { id: getOrCreateCartId(), items: [] }))
      .catch(() => setLoadError("Could not load your cart. Please try again shortly."));
  }, []);

  const items = cart?.items ?? [];
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  const shipping = items.length > 0 ? FLAT_SHIPPING_FEE : 0;
  const total = subtotal + shipping;

  async function handlePlaceOrder(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitError(null);

    if (items.length === 0) {
      setSubmitError("Your cart is empty — add a piece before checking out.");
      return;
    }

    setSubmitting(true);
    try {
      // No Stripe/PSP integration in this app — the entered payment details
      // are sent as-is inside the OrderInput.paymentToken string.
      const paymentToken = JSON.stringify({ cardNumber, expiry, cvc, cardholderName });
      const order = await createOrder({
        cartId: getOrCreateCartId(),
        shippingAddress,
        paymentToken,
      });
      resetCartId();
      navigate("/order-confirmation", { state: { order } });
    } catch (err) {
      // Stay on the page and show an inline error on a decline (400) instead
      // of navigating to confirmation.
      if (err instanceof ApiRequestError) {
        setSubmitError(
          err.body?.message ?? "Your payment was declined. Please check your details and try again.",
        );
      } else {
        setSubmitError("Something went wrong placing your order. Please try again.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <p className="breadcrumb">Cart / Checkout</p>
      <h1>Checkout</h1>
      {user && <p className="muted">Signed in as {user.profile?.email ?? user.profile?.sub}</p>}

      {loadError && <p className="error-text">{loadError}</p>}

      {cart && items.length === 0 && !loadError && <p>Your cart is empty — there is nothing to check out.</p>}

      {cart && items.length > 0 && (
        <form className="card checkout-form" onSubmit={handlePlaceOrder}>
          <label className="form-field">
            Shipping address
            <input
              required
              value={shippingAddress}
              onChange={(e) => setShippingAddress(e.target.value)}
              placeholder="123 Main St, Springfield"
            />
          </label>

          <label className="form-field">
            Name on card
            <input
              required
              value={cardholderName}
              onChange={(e) => setCardholderName(e.target.value)}
              placeholder="Jane Doe"
            />
          </label>

          <label className="form-field">
            Card number
            <input
              required
              inputMode="numeric"
              autoComplete="cc-number"
              value={cardNumber}
              onChange={(e) => setCardNumber(e.target.value)}
              placeholder="4242 4242 4242 4242"
            />
          </label>

          <div className="form-row">
            <label className="form-field">
              Expiry
              <input
                required
                autoComplete="cc-exp"
                value={expiry}
                onChange={(e) => setExpiry(e.target.value)}
                placeholder="MM/YY"
              />
            </label>
            <label className="form-field">
              CVC
              <input
                required
                autoComplete="cc-csc"
                value={cvc}
                onChange={(e) => setCvc(e.target.value)}
                placeholder="123"
              />
            </label>
          </div>

          <p className="totals">Total: ${total.toFixed(2)} (flat-rate shipping included)</p>

          {submitError && <p className="error-text">{submitError}</p>}

          <div className="row-end">
            <button type="button" className="link-button" onClick={() => navigate("/cart")}>
              Cancel
            </button>
            <button type="submit" className="btn-primary" disabled={submitting}>
              {submitting ? "Placing order…" : "Place order"}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
