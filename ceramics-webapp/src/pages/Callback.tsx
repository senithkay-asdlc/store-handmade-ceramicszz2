import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { handleCallback } from "../auth";
import { useAuth } from "../AuthContext";

/**
 * OIDC Authorization Code + PKCE redirect target. Runs once on mount, then
 * sends the user back to whatever screen requested sign-in (carried through
 * as `state.returnTo` by `signIn()` in auth.ts), defaulting to the storefront.
 */
export function Callback() {
  const navigate = useNavigate();
  const { refresh } = useAuth();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    handleCallback()
      .then(async (user) => {
        await refresh();
        const state = user.state as { returnTo?: string } | undefined;
        navigate(state?.returnTo ?? "/", { replace: true });
      })
      .catch(() => {
        setError("Sign-in did not complete. Please try again.");
      });
  }, [navigate, refresh]);

  if (error) {
    return (
      <div className="app-shell">
        <main className="page">
          <p className="error-text">{error}</p>
        </main>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <main className="page">
        <p className="status-message">Signing you in…</p>
      </main>
    </div>
  );
}
