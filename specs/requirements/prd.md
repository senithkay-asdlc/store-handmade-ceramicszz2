# Handmade Ceramics Store — PRD

## Problem Statement

Independent ceramic artists who sell one-of-a-kind, handmade pieces have no simple way to put their work in front of buyers online. General marketplace platforms bury unique, low-volume handmade items among mass-produced goods, and building a custom storefront from scratch is out of reach for a solo artisan. Buyers, meanwhile, want a straightforward way to browse a single maker's current pieces, see that each item is unique, and buy it before someone else does.

## Solution

A single-seller online store for handmade ceramics: a public catalog of one-of-a-kind pieces that anyone can browse, a cart and checkout flow for buyers who sign in to complete a purchase, and an order-management view for the store owner to track and fulfill orders. Because every piece is unique, a purchased item disappears from the catalog immediately so no two buyers can compete for the same piece.

## Actors

- **Shopper**: browses the public catalog, adds pieces to a cart, signs in to check out, places orders, and views their own order history.
- **Store Owner**: signs in to manage the product catalog (add/edit/remove one-of-a-kind listings) and to view and update the status of incoming orders.

## User Stories

1. As a Shopper, I want to browse the product catalog without signing in, so that I can explore available ceramics before committing to an account.
2. As a Shopper, I want to view a detailed product page (photos, description, price, availability), so that I can decide whether to purchase a piece.
3. As a Shopper, I want to add a piece to a cart, so that I can collect items before checking out.
4. As a Shopper, I want to review and adjust my cart (remove items, see line items and totals), so that I can confirm my order before paying.
5. As a Shopper, I want to sign in via SSO before completing checkout, so that my order is tied to my account.
6. As a Shopper, I want to enter shipping and payment details and place an order, so that I can purchase the pieces I've selected.
7. As a Shopper, I want to receive an order confirmation after purchase, so that I know my order went through.
8. As a Shopper, I want to view my past orders and their status, so that I can track a piece I bought.
9. As a Store Owner, I want to sign in via SSO, so that I can manage the store securely.
10. As a Store Owner, I want to add, edit, and remove product listings, so that I can keep the catalog current with the pieces actually available.
11. As a Store Owner, I want a purchased piece to be removed from the public catalog automatically, so that shoppers never see or buy a piece that is already sold.
12. As a Store Owner, I want to view incoming orders, so that I know what needs to be fulfilled.
13. As a Store Owner, I want to update an order's status (e.g. new → shipped → delivered), so that I can track fulfillment progress and keep buyers informed.

## Product Decisions

- **Single-seller store**: one store owner manages the entire catalog and fulfills all orders; there is no multi-vendor onboarding or per-seller payouts.
- **One-of-a-kind inventory model**: every listing is a unique piece, not a stocked SKU. A sale removes the piece from the catalog instead of decrementing a quantity.
- **Anonymous browsing, sign-in at checkout**: the catalog and product pages are public; Thunder SSO is only enforced when a Shopper proceeds to checkout, and always for the Store Owner's management views.
- **Flat-rate shipping, single region**: checkout charges one flat shipping fee and ships only within a single country/region for this phase.
- **Basic order management**: the Store Owner gets a view of incoming orders and can update order status; there is no returns/refunds workflow yet.
- **Transactional email on order confirmation** *assumed*: the store sends an email confirmation when an order is placed; the concrete provider is chosen at design time.
- **Online payment at checkout** *assumed*: checkout collects payment through a card-payment capability; the concrete provider is chosen at design time.

## Phasing

- **Phase 1 — Launch the single-seller ceramics store**: deliver the public catalog, cart, checkout with sign-in, order confirmation, buyer order history, and the store owner's catalog and order management. Stories: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13.

## Out of Scope

- Multi-vendor marketplace features (seller onboarding, per-seller storefronts, payouts).
- Restocked/quantity-based inventory; every listing remains one-of-a-kind.
- Calculated or international shipping; only flat-rate, single-region shipping is supported.
- Returns, refunds, or exchange workflows.
- Product reviews, ratings, or wishlists.
- Promotions, discount codes, or gift cards.

## Open Questions

None currently — all product-level decisions needed to start design have been resolved above.