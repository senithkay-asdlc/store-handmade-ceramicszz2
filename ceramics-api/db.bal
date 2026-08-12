import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

final int dbPort = check int:fromString(dbPortString);

final postgresql:Client dbClient = check new (
    host = dbHost,
    username = dbUsername,
    password = dbPassword,
    database = dbDatabase,
    port = dbPort
);

// Module initializer — creates the schema on startup if it does not exist yet.
function init() returns error? {
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            price NUMERIC(12,2) NOT NULL,
            image_url TEXT,
            status TEXT NOT NULL DEFAULT 'available'
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS carts (
            id TEXT PRIMARY KEY,
            shopper_id TEXT
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS cart_items (
            cart_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            PRIMARY KEY (cart_id, product_id)
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            shopper_id TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'new',
            shipping_fee NUMERIC(12,2),
            total NUMERIC(12,2) NOT NULL,
            shipping_address TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS order_items (
            order_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            name TEXT NOT NULL,
            price NUMERIC(12,2) NOT NULL
        )
    `);
}
