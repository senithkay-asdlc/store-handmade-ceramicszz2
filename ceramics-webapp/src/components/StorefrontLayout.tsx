import { Link, Outlet } from "react-router-dom";
import { useAuth } from "../AuthContext";

export function StorefrontLayout() {
  const { user, isOwner, loading, signIn, signOut } = useAuth();

  return (
    <div className="app-shell">
      <nav className="navbar">
        <span className="brand">Ceramics Co.</span>
        <Link to="/">Shop</Link>
        <Link to="/cart">Cart</Link>
        {user && <Link to="/my-orders">My orders</Link>}
        {isOwner && <Link to="/owner">Admin</Link>}
        <span className="nav-spacer" />
        {loading ? null : user ? (
          <>
            <span className="nav-user">{user.profile?.email ?? user.profile?.sub}</span>
            <button className="link-button" onClick={() => signOut()}>
              Sign out
            </button>
          </>
        ) : (
          <button className="link-button" onClick={() => signIn("/")}>
            Sign in
          </button>
        )}
      </nav>
      <main className="page">
        <Outlet />
      </main>
    </div>
  );
}
