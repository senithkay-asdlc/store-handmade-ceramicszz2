import { useEffect, type ReactNode } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../AuthContext";

/** Checkout / MyOrders — any signed-in session. Not signed in -> Thunder sign-in, then back here. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, loading, signIn } = useAuth();
  const location = useLocation();

  useEffect(() => {
    if (!loading && !user) {
      signIn(location.pathname);
    }
  }, [loading, user, signIn, location.pathname]);

  if (loading || !user) {
    return <p className="status-message">Redirecting you to sign in…</p>;
  }
  return <>{children}</>;
}

/**
 * Owner screens — Store-Owner role only. No match on profile.groups -> don't
 * render the owner screen, send the visitor back to the public Catalog.
 */
export function RequireOwner({ children }: { children: ReactNode }) {
  const { isOwner, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!loading && !isOwner) {
      navigate("/", { replace: true });
    }
  }, [loading, isOwner, navigate]);

  if (loading || !isOwner) {
    return <p className="status-message">Loading…</p>;
  }
  return <>{children}</>;
}
