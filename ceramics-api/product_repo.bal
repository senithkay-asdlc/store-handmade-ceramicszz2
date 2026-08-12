import ballerina/sql;
import ballerina/uuid;

isolated function toProductStatus(string raw) returns "available"|"sold" {
    if raw == "sold" {
        return "sold";
    }
    return "available";
}

isolated function toProduct(ProductRow row) returns Product {
    Product product = {
        id: row.id,
        name: row.name,
        price: row.price,
        status: toProductStatus(row.status)
    };
    string? description = row.description;
    if description is string {
        product.description = description;
    }
    string? imageUrl = row.imageUrl;
    if imageUrl is string {
        product.imageUrl = imageUrl;
    }
    return product;
}

isolated function listAvailableProducts(int 'limit, int offset) returns [Product[], int]|error {
    stream<ProductRow, sql:Error?> resultStream = dbClient->query(`
        SELECT id, name, description, price, image_url AS "imageUrl", status
        FROM products
        WHERE status = 'available'
        ORDER BY id
        LIMIT ${'limit} OFFSET ${offset}
    `);
    Product[] products = [];
    check from ProductRow row in resultStream
        do {
            products.push(toProduct(row));
        };
    CountRow countRow = check dbClient->queryRow(`SELECT COUNT(*) AS "count" FROM products WHERE status = 'available'`);
    return [products, countRow.count];
}

isolated function getProductById(string productId) returns Product?|error {
    ProductRow|sql:Error result = dbClient->queryRow(`
        SELECT id, name, description, price, image_url AS "imageUrl", status
        FROM products
        WHERE id = ${productId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is error {
        return result;
    }
    return toProduct(result);
}

// Returns the raw product status (not the full row) — used by the cart
// resources to decide 404 vs 400 without pulling the whole product.
isolated function findProductStatus(string productId) returns string?|error {
    ProductStatusRow|sql:Error result = dbClient->queryRow(`SELECT status FROM products WHERE id = ${productId}`);
    if result is sql:NoRowsError {
        return ();
    }
    if result is error {
        return result;
    }
    return result.status;
}

isolated function insertProduct(ProductInput input) returns Product|error {
    string id = uuid:createRandomUuid();
    string? description = input?.description;
    string? imageUrl = input?.imageUrl;
    _ = check dbClient->execute(`
        INSERT INTO products (id, name, description, price, image_url, status)
        VALUES (${id}, ${input.name}, ${description}, ${input.price}, ${imageUrl}, 'available')
    `);
    Product product = {
        id: id,
        name: input.name,
        price: input.price,
        status: "available"
    };
    if description is string {
        product.description = description;
    }
    if imageUrl is string {
        product.imageUrl = imageUrl;
    }
    return product;
}

isolated function updateProductById(string productId, ProductInput input) returns Product?|error {
    string? description = input?.description;
    string? imageUrl = input?.imageUrl;
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE products
        SET name = ${input.name}, description = ${description}, price = ${input.price}, image_url = ${imageUrl}
        WHERE id = ${productId}
    `);
    int? affectedRowCount = result.affectedRowCount;
    if affectedRowCount is int && affectedRowCount == 0 {
        return ();
    }
    return getProductById(productId);
}

isolated function deleteProductById(string productId) returns boolean|error {
    sql:ExecutionResult result = check dbClient->execute(`DELETE FROM products WHERE id = ${productId}`);
    int? affectedRowCount = result.affectedRowCount;
    return affectedRowCount is int && affectedRowCount > 0;
}
