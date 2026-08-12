import ballerina/time;

// Internal row/result shapes for the repositories in product_repo.bal,
// cart_repo.bal and order_repo.bal. Kept separate from the wire types in
// types.bal (generated from openapi.yaml).

type CountRow record {|
    int count;
|};

type ProductRow record {|
    string id;
    string name;
    string? description;
    decimal price;
    string? imageUrl;
    string status;
|};

type ProductStatusRow record {|
    string status;
|};

type CartItemRow record {|
    string productId;
    string name;
    decimal price;
|};

// A cart line item joined with its product's current status — used only for
// checkout validation, never exposed on the wire.
type CheckoutItem record {|
    string productId;
    string name;
    decimal price;
    string status;
|};

type OrderRow record {|
    string id;
    string shopperId;
    string status;
    decimal? shippingFee;
    decimal total;
    string shippingAddress;
    time:Utc createdAt;
|};

type OrderItemRow record {|
    string productId;
    string name;
    decimal price;
|};

// Full order detail including the owning shopper — used internally to
// authorize before trimming down to the public `Order` wire type.
type OrderDetail record {|
    string id;
    string shopperId;
    string status;
    decimal? shippingFee;
    decimal total;
    string shippingAddress;
    time:Utc createdAt;
    OrderItem[] items;
|};
