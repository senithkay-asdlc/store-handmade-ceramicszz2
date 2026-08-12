// Handmade Ceramics Store — wireframes

screen Catalog "Anyone browses the public catalog of available pieces"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart"
  row
    heading "Handpicked, one-of-a-kind pieces"
    right
    search "Search pieces…"
  row
    card "Available pieces | 18 | updated today"
  heading "Available now"
  row
    card "Speckled Stoneware Vase | $68 | one of a kind" -> ProductDetail
    card "Matte Blue Bowl Set | $52 | one of a kind" -> ProductDetail
    card "Terracotta Pitcher | $74 | one of a kind" -> ProductDetail

screen ProductDetail "A Shopper reviews one piece and adds it to the cart"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart"
  breadcrumb "Shop / Speckled Stoneware Vase"
  row
    image "Speckled Stoneware Vase photo" 400x300
    card
      heading "Speckled Stoneware Vase"
      badge "One of a kind" info
      text "$68"
      text "Hand-thrown stoneware with a speckled ash glaze. 9in tall."
      row
        right
        button "Add to cart" primary -> Cart

screen Cart "A Shopper reviews their cart before checking out"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart"
  heading "Your cart"
  table "Piece | Price | "
    row "Speckled Stoneware Vase | $68 | Remove"
    row "Terracotta Pitcher | $74 | Remove"
  row
    right
    text "Subtotal: $142 · Shipping: $8 · Total: $150"
  row
    right
    button "Continue to checkout" primary -> Checkout

screen Checkout "A signed-in Shopper enters shipping and payment to place the order"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart"
  breadcrumb "Cart / Checkout"
  heading "Checkout"
  text "Signed in as jane@example.com"
  input "Shipping address"
  input "Card number"
  row
    input "Expiry"
    input "CVC"
  text "Total: $150 (flat-rate shipping included)"
  row
    right
    button "Cancel"
    button "Place order" primary -> OrderConfirmation

screen OrderConfirmation "The Shopper sees their order was placed"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart"
  heading "Order confirmed"
  badge "New" info
  text "Order #10241 — confirmation emailed to jane@example.com"
  table "Piece | Price"
    row "Speckled Stoneware Vase | $68"
    row "Terracotta Pitcher | $74"
  row
    right
    button "View my orders" primary -> MyOrders

screen MyOrders "A signed-in Shopper tracks their past orders"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart"
  heading "My orders"
  table "Order | Placed | Total | Status"
    row "#10241 | Today | $150 | New"
    row "#10198 | 2 weeks ago | $68 | Delivered"

screen OwnerCatalog "The Store Owner manages product listings"
  navbar "Ceramics Co. Admin"
  sidebar "Catalog -> OwnerCatalog | Orders -> OwnerOrders"
  row
    heading "Manage catalog"
    right
    button "New listing" primary -> OwnerProductForm
  table "Piece | Price | Status | " -> OwnerProductForm
    row "Speckled Stoneware Vase | $68 | Available | Edit"
    row "Matte Blue Bowl Set | $52 | Available | Edit"
    row "Terracotta Pitcher | $74 | Sold | Edit"

screen OwnerProductForm "The Store Owner adds or edits one listing"
  navbar "Ceramics Co. Admin"
  sidebar "Catalog -> OwnerCatalog | Orders -> OwnerOrders"
  breadcrumb "Catalog / Speckled Stoneware Vase"
  heading "Edit listing"
  input "Name"
  textarea "Description"
  input "Price"
  image "Product photo" 300x200
  row
    right
    button "Cancel" -> OwnerCatalog
    button "Save" primary -> OwnerCatalog

screen OwnerOrders "The Store Owner tracks and updates incoming orders"
  navbar "Ceramics Co. Admin"
  sidebar "Catalog -> OwnerCatalog | Orders -> OwnerOrders"
  heading "Incoming orders"
  tabs "All (24) | New (6) | Shipped (12) | Delivered (6)"
  table "Order | Shopper | Total | Status | "
    row "#10241 | jane@example.com | $150 | New | Mark shipped"
    row "#10198 | mo@example.com | $68 | Shipped | Mark delivered"
