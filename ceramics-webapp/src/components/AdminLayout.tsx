import { Link, Outlet } from "react-router-dom";
import { useAuth } from "../AuthContext";

export function AdminLayout() {
  const { user, signOut } = useAuth();

  return (
    <div className="app-shell admin-shell">
      <nav className="navbar">
        <span className="brand">Ceramics Co. Admin</span>
        <Link to="/">Back to shop</Link>
        <span className="nav-spacer" />
        {user && <span className="nav-user">{user.profile?.email ?? user.profile?.sub}</span>}
        <button className="link-button" onClick={() => signOut()}>
          Sign out
        </button>
      </nav>
      <div className="admin-body">
        <aside className="sidebar">
          <Link to="/owner">Catalog</Link>
          <Link to="/owner/orders">Orders</Link>
        </aside>
        <main className="page">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
