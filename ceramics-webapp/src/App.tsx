import { Navigate, Route, Routes } from "react-router-dom";
import { StorefrontLayout } from "./components/StorefrontLayout";
import { AdminLayout } from "./components/AdminLayout";
import { RequireAuth, RequireOwner } from "./components/RouteGuards";
import { Catalog } from "./pages/Catalog";
import { ProductDetail } from "./pages/ProductDetail";
import { Cart } from "./pages/Cart";
import { Checkout } from "./pages/Checkout";
import { OrderConfirmation } from "./pages/OrderConfirmation";
import { MyOrders } from "./pages/MyOrders";
import { OwnerCatalog } from "./pages/OwnerCatalog";
import { OwnerProductForm } from "./pages/OwnerProductForm";
import { OwnerOrders } from "./pages/OwnerOrders";
import { Callback } from "./pages/Callback";

export function App() {
  return (
    <Routes>
      {/* OIDC redirect target — outside any layout/guard. */}
      <Route path="/callback" element={<Callback />} />

      {/* Public storefront + sign-in-required shopper screens. */}
      <Route element={<StorefrontLayout />}>
        <Route index element={<Catalog />} />
        <Route path="products/:productId" element={<ProductDetail />} />
        <Route path="cart" element={<Cart />} />
        <Route
          path="checkout"
          element={
            <RequireAuth>
              <Checkout />
            </RequireAuth>
          }
        />
        <Route
          path="order-confirmation"
          element={
            <RequireAuth>
              <OrderConfirmation />
            </RequireAuth>
          }
        />
        <Route
          path="my-orders"
          element={
            <RequireAuth>
              <MyOrders />
            </RequireAuth>
          }
        />
      </Route>

      {/* Store-Owner-only admin screens. */}
      <Route
        element={
          <RequireOwner>
            <AdminLayout />
          </RequireOwner>
        }
      >
        <Route path="owner" element={<OwnerCatalog />} />
        <Route path="owner/new" element={<OwnerProductForm />} />
        <Route path="owner/:productId/edit" element={<OwnerProductForm />} />
        <Route path="owner/orders" element={<OwnerOrders />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
