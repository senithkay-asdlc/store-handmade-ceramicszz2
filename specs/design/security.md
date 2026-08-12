# Security design

## Roles → permissions

## Authentication (Thunder)

- **Dependency name**: `user-auth` — declared identically on `ceramics-webapp`
and `ceramics-api`, tying SPA sign-in to the bearer tokens the API validates.
- **Scopes**: `openid profile email` (default).
- **Public side**: catalog browsing and product detail pages on
`ceramics-webapp` and their read endpoints on `ceramics-api` require no
sign-in (stories 1, 2).
- **Protected side**: cart checkout, order placement, order history, catalog
management, and order management all require a valid Thunder session on
`ceramics-webapp` and a valid bearer token on `ceramics-api`.

## Role resolution

`ceramics-api` resolves the caller's role from the validated token's claims
(the gateway injects the identity headers): a caller with no Store-Owner claim
is treated as a Shopper and may only act on their own cart and orders; a
request for another Shopper's order or for a Store-Owner-only endpoint without
the Store-Owner claim is denied (403) by default.