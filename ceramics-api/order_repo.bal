import ballerina/sql;
import ballerina/time;
import ballerina/uuid;

isolated function toOrderStatus(string raw) returns "new"|"shipped"|"delivered" {
    if raw == "shipped" {
        return "shipped";
    }
    if raw == "delivered" {
        return "delivered";
    }
    return "new";
}

// `new` -> `shipped` -> `delivered`, one step at a time; no skipping and no
// going backwards.
isolated function isValidOrderTransition(string current, string target) returns boolean {
    if current == "new" && target == "shipped" {
        return true;
    }
    if current == "shipped" && target == "delivered" {
        return true;
    }
    return false;
}

isolated function toOrder(OrderDetail detail) returns Order {
    Order orderResult = {
        id: detail.id,
        status: toOrderStatus(detail.status),
        total: detail.total,
        shippingAddress: detail.shippingAddress,
        createdAt: time:utcToString(detail.createdAt),
        items: detail.items
    };
    decimal? shippingFee = detail.shippingFee;
    if shippingFee is decimal {
        orderResult.shippingFee = shippingFee;
    }
    return orderResult;
}

isolated function getOrderItems(string orderId) returns OrderItem[]|error {
    stream<OrderItemRow, sql:Error?> resultStream = dbClient->query(`
        SELECT product_id AS "productId", name, price
        FROM order_items
        WHERE order_id = ${orderId}
        ORDER BY product_id
    `);
    OrderItem[] items = [];
    check from OrderItemRow row in resultStream
        do {
            items.push({productId: row.productId, name: row.name, price: row.price});
        };
    return items;
}

isolated function getOrderDetail(string orderId) returns OrderDetail?|error {
    OrderRow|sql:Error result = dbClient->queryRow(`
        SELECT id, shopper_id AS "shopperId", status, shipping_fee AS "shippingFee", total,
               shipping_address AS "shippingAddress", created_at AS "createdAt"
        FROM orders
        WHERE id = ${orderId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is error {
        return result;
    }
    OrderItem[] items = check getOrderItems(orderId);
    return {
        id: result.id,
        shopperId: result.shopperId,
        status: result.status,
        shippingFee: result.shippingFee,
        total: result.total,
        shippingAddress: result.shippingAddress,
        createdAt: result.createdAt,
        items: items
    };
}

isolated function buildOrdersFilter(string? callerId, boolean isOwner, string? status) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery whereClause = ``;
    if !isOwner && callerId is string {
        whereClause = sql:queryConcat(whereClause, ` WHERE shopper_id = ${callerId}`);
        if status is string {
            whereClause = sql:queryConcat(whereClause, ` AND status = ${status}`);
        }
    } else if status is string {
        whereClause = sql:queryConcat(whereClause, ` WHERE status = ${status}`);
    }
    return whereClause;
}

isolated function countOrders(string? callerId, boolean isOwner, string? status) returns int|error {
    sql:ParameterizedQuery whereClause = buildOrdersFilter(callerId, isOwner, status);
    sql:ParameterizedQuery query = sql:queryConcat(`SELECT COUNT(*) AS "count" FROM orders`, whereClause);
    CountRow countRow = check dbClient->queryRow(query);
    return countRow.count;
}

isolated function listOrders(string? callerId, boolean isOwner, string? status, int 'limit, int offset) returns [Order[], int]|error {
    sql:ParameterizedQuery whereClause = buildOrdersFilter(callerId, isOwner, status);
    sql:ParameterizedQuery query = sql:queryConcat(`
        SELECT id, shopper_id AS "shopperId", status, shipping_fee AS "shippingFee", total,
               shipping_address AS "shippingAddress", created_at AS "createdAt"
        FROM orders`, whereClause, ` ORDER BY created_at DESC LIMIT ${'limit} OFFSET ${offset}`);
    stream<OrderRow, sql:Error?> resultStream = dbClient->query(query);
    OrderRow[] rows = [];
    check from OrderRow row in resultStream
        do {
            rows.push(row);
        };
    Order[] orders = [];
    foreach OrderRow row in rows {
        OrderItem[] items = check getOrderItems(row.id);
        OrderDetail detail = {
            id: row.id,
            shopperId: row.shopperId,
            status: row.status,
            shippingFee: row.shippingFee,
            total: row.total,
            shippingAddress: row.shippingAddress,
            createdAt: row.createdAt,
            items: items
        };
        orders.push(toOrder(detail));
    }
    int total = check countOrders(callerId, isOwner, status);
    return [orders, total];
}

isolated function applyOrderStatus(string orderId, string targetStatus) returns error? {
    _ = check dbClient->execute(`UPDATE orders SET status = ${targetStatus} WHERE id = ${orderId}`);
}

// Checkout: charges must already have succeeded by the time this is called.
// Marking every ordered product `sold` and inserting the order + order items
// happens in one SQL transaction — a failure partway through rolls everything
// back, so a declined charge (checked before this is ever invoked) can never
// leave a half-written order.
isolated function placeOrder(string shopperId, string shippingAddress, string cartId, CheckoutItem[] items, decimal total) returns Order|error {
    string orderId = uuid:createRandomUuid();
    time:Utc now = time:utcNow();
    decimal shippingFee = 0d;
    transaction {
        foreach CheckoutItem item in items {
            sql:ExecutionResult soldResult = check dbClient->execute(`
                UPDATE products SET status = 'sold' WHERE id = ${item.productId} AND status = 'available'
            `);
            int? affectedRowCount = soldResult.affectedRowCount;
            if affectedRowCount is int && affectedRowCount == 0 {
                fail error("product no longer available: " + item.productId);
            }
        }
        _ = check dbClient->execute(`
            INSERT INTO orders (id, shopper_id, status, shipping_fee, total, shipping_address, created_at)
            VALUES (${orderId}, ${shopperId}, 'new', ${shippingFee}, ${total}, ${shippingAddress}, ${new sql:TimestampValue(now)})
        `);
        foreach CheckoutItem item in items {
            _ = check dbClient->execute(`
                INSERT INTO order_items (order_id, product_id, name, price)
                VALUES (${orderId}, ${item.productId}, ${item.name}, ${item.price})
            `);
        }
        _ = check dbClient->execute(`DELETE FROM cart_items WHERE cart_id = ${cartId}`);
        check commit;
    }
    OrderItem[] orderItems = [];
    foreach CheckoutItem item in items {
        orderItems.push({productId: item.productId, name: item.name, price: item.price});
    }
    return {
        id: orderId,
        status: "new",
        shippingFee: shippingFee,
        total: total,
        shippingAddress: shippingAddress,
        createdAt: time:utcToString(now),
        items: orderItems
    };
}
