# Handmade Ceramics Store — Design

## Overview

A single-seller online store for handmade ceramics. The **Ceramics Storefront**
(React SPA) serves an anonymous, browsable catalog of one-of-a-kind pieces and,
after Thunder sign-in, a cart/checkout flow for Shoppers and catalog/order
management for the Store Owner. The **Ceramics API** (Ballerina service) owns
the catalog, cart, checkout, and order lifecycle, calling out to a payment
provider to collect payment and an email provider to send order confirmations.
Because every piece is unique, a sale removes it from the catalog immediately.

## Context (C1)

```mermaid
graph TD
    shopper[Shopper]
    owner[Store Owner]
    system((Handmade Ceramics Store))
    thunder[Thunder Auth]
    payment[Payment Provider]
    email[Email Provider]

    shopper -->|browse, cart, checkout, view orders| system
    owner -->|manage catalog, manage orders| system
    system -->|sign-in| thunder
    system -->|charge card| payment
    system -->|send confirmation| email
```

## Domain model (ER)

```mermaid
erDiagram
    PRODUCT {
        string id
        string name
        string description
        decimal price
        string imageUrl
        string status
    }
    CART {
        string id
        string shopperId
    }
    CART_ITEM {
        string cartId
        string productId
    }
    ORDER {
        string id
        string shopperId
        string status
        decimal shippingFee
        decimal total
        string shippingAddress
        datetime createdAt
    }
    ORDER_ITEM {
        string orderId
        string productId
        decimal price
    }

    CART ||--o{ CART_ITEM : contains
    CART_ITEM }o--|| PRODUCT : references
    ORDER ||--o{ ORDER_ITEM : contains
    ORDER_ITEM }o--|| PRODUCT : references
```

`PRODUCT.status` is `available` or `sold` — a sold product is excluded from the
public catalog. `ORDER.status` moves `new` → `shipped` → `delivered`.

## Key flows

### Browse and add to cart

```mermaid
sequenceDiagram
    participant S as Shopper
    participant W as Ceramics Storefront
    participant A as Ceramics API

    S->>W: Open catalog
    W->>A: GET /products (available only)
    A-->>W: Product list
    S->>W: Add piece to cart
    W->>A: POST /carts/{cartId}/items
    A-->>W: Updated cart
```

### Checkout

```mermaid
sequenceDiagram
    participant S as Shopper
    participant W as Ceramics Storefront
    participant T as Thunder Auth
    participant A as Ceramics API
    participant P as Payment Provider
    participant E as Email Provider

    S->>W: Proceed to checkout
    W->>T: Sign in (OIDC)
    T-->>W: ID token
    S->>W: Enter shipping + payment details
    W->>A: POST /orders (bearer token, cart, shipping, payment)
    A->>P: Charge card
    P-->>A: Payment confirmed
    A->>A: Mark ordered products sold, remove from catalog
    A->>E: Send order confirmation email
    A-->>W: Order created
    W-->>S: Order confirmation
```

### Store Owner order fulfillment

```mermaid
sequenceDiagram
    participant O as Store Owner
    participant W as Ceramics Storefront
    participant T as Thunder Auth
    participant A as Ceramics API

    O->>W: Sign in
    W->>T: Sign in (OIDC)
    T-->>W: ID token
    O->>W: Open incoming orders
    W->>A: GET /orders (bearer token)
    A-->>W: Order list
    O->>W: Mark order shipped
    W->>A: PATCH /orders/{orderId} (status: shipped)
    A-->>W: Updated order
```