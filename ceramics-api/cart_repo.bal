import ballerina/sql;

isolated function cartExists(string cartId) returns boolean|error {
    CountRow countRow = check dbClient->queryRow(`SELECT COUNT(*) AS "count" FROM carts WHERE id = ${cartId}`);
    return countRow.count > 0;
}

isolated function cartItemExists(string cartId, string productId) returns boolean|error {
    CountRow countRow = check dbClient->queryRow(`
        SELECT COUNT(*) AS "count" FROM cart_items WHERE cart_id = ${cartId} AND product_id = ${productId}
    `);
    return countRow.count > 0;
}

isolated function getCartItems(string cartId) returns CartItem[]|error {
    stream<CartItemRow, sql:Error?> resultStream = dbClient->query(`
        SELECT p.id AS "productId", p.name AS "name", p.price AS "price"
        FROM cart_items ci JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = ${cartId}
        ORDER BY p.id
    `);
    CartItem[] items = [];
    check from CartItemRow row in resultStream
        do {
            items.push({productId: row.productId, name: row.name, price: row.price});
        };
    return items;
}

// Cart lines joined with the product's current status — used only to
// validate checkout, never returned on the wire.
isolated function getCheckoutItems(string cartId) returns CheckoutItem[]|error {
    stream<CheckoutItem, sql:Error?> resultStream = dbClient->query(`
        SELECT p.id AS "productId", p.name AS "name", p.price AS "price", p.status AS "status"
        FROM cart_items ci JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = ${cartId}
        ORDER BY p.id
    `);
    CheckoutItem[] items = [];
    check from CheckoutItem item in resultStream
        do {
            items.push(item);
        };
    return items;
}

// A cart is created implicitly the first time an item is added to a new
// cartId — there is no explicit "create cart" operation in openapi.yaml.
isolated function ensureCart(string cartId) returns error? {
    _ = check dbClient->execute(`INSERT INTO carts (id) VALUES (${cartId}) ON CONFLICT (id) DO NOTHING`);
}

isolated function addItemToCart(string cartId, string productId) returns error? {
    _ = check dbClient->execute(`
        INSERT INTO cart_items (cart_id, product_id) VALUES (${cartId}, ${productId})
        ON CONFLICT (cart_id, product_id) DO NOTHING
    `);
}

isolated function removeItemFromCart(string cartId, string productId) returns error? {
    _ = check dbClient->execute(`DELETE FROM cart_items WHERE cart_id = ${cartId} AND product_id = ${productId}`);
}

isolated function clearCart(string cartId) returns error? {
    _ = check dbClient->execute(`DELETE FROM cart_items WHERE cart_id = ${cartId}`);
}

isolated function buildCart(string cartId) returns Cart|error {
    CartItem[] items = check getCartItems(cartId);
    return {id: cartId, items: items};
}
