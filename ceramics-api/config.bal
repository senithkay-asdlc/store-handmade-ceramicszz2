import ballerina/os;

// Postgres platform-resource (ceramics-db) — envBindings from design.json.
configurable string dbHost = os:getEnv("CERAMICS_DB_HOST");
configurable string dbPortString = os:getEnv("CERAMICS_DB_PORT");
configurable string dbUsername = os:getEnv("CERAMICS_DB_USERNAME");
configurable string dbPassword = os:getEnv("CERAMICS_DB_PASSWORD");
configurable string dbDatabase = os:getEnv("CERAMICS_DB_DATABASE");

// Payment provider (Stripe) — external dependency, style: sdk.
configurable string stripeApiKey = os:getEnv("STRIPE_API_KEY");

// Email provider (SendGrid) — external dependency, style: sdk.
configurable string sendgridApiKey = os:getEnv("SENDGRID_API_KEY");
configurable string sendgridFromEmail = os:getEnv("SENDGRID_FROM_EMAIL");
