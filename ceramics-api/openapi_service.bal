import ballerina/http;
import ballerina/log;

listener http:Listener ep0 = new (9090);

service / on ep0 {

    // ---- Catalog: public reads ----

    # List available (unsold) products
    #
    # + return - Paged list of available products
    resource function get products(int 'limit = 20, int offset = 0) returns inline_response_200|http:InternalServerError {
        do {
            int effectiveLimit = clampLimit('limit);
            [Product[], int] result = check listAvailableProducts(effectiveLimit, offset);
            Product[] products = result[0];
            int total = result[1];
            inline_response_200 page = {
                count: total,
                data: products
            };
            string? next = buildNextLink("/products", effectiveLimit, offset, total, ());
            if next is string {
                page.next = next;
            }
            string? previous = buildPreviousLink("/products", effectiveLimit, offset, ());
            if previous is string {
                page.previous = previous;
            }
            return page;
        } on fail error e {
            log:printError("failed to list products", 'error = e);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Get one product's detail
    #
    # + return - returns can be any of following types
    # http:Ok (Product detail)
    # http:NotFound (Product not found)
    resource function get products/[string productId]() returns Product|ErrorNotFound|http:InternalServerError {
        do {
            Product? product = check getProductById(productId);
            if product is () {
                return <ErrorNotFound>{body: {code: 404, message: "Product not found"}};
            }
            return product;
        } on fail error e {
            log:printError("failed to get product", 'error = e, productId = productId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    // ---- Catalog: Store-Owner-only management ----

    # Add a new one-of-a-kind product listing (Store Owner)
    #
    # + return - returns can be any of following types
    # http:Created (Product created)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Caller is not the Store Owner)
    resource function post products/manage(@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Groups, @http:Payload ProductInput payload)
            returns Product|ErrorUnauthorized|ErrorForbidden|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        if !isStoreOwner(X\-User\-Groups) {
            return <ErrorForbidden>{body: {code: 403, message: "Caller is not the Store Owner"}};
        }
        do {
            Product product = check insertProduct(payload);
            return product;
        } on fail error e {
            log:printError("failed to create product", 'error = e);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Update a product listing (Store Owner)
    #
    # + return - returns can be any of following types
    # http:Ok (Updated product)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Caller is not the Store Owner)
    # http:NotFound (Product not found)
    resource function put products/[string productId]/manage(@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Groups, @http:Payload ProductInput payload)
            returns Product|ErrorUnauthorized|ErrorForbidden|ErrorNotFound|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        if !isStoreOwner(X\-User\-Groups) {
            return <ErrorForbidden>{body: {code: 403, message: "Caller is not the Store Owner"}};
        }
        do {
            Product? product = check updateProductById(productId, payload);
            if product is () {
                return <ErrorNotFound>{body: {code: 404, message: "Product not found"}};
            }
            return product;
        } on fail error e {
            log:printError("failed to update product", 'error = e, productId = productId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Remove a product listing (Store Owner)
    #
    # + return - returns can be any of following types
    # http:NoContent (Product removed)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Caller is not the Store Owner)
    # http:NotFound (Product not found)
    resource function delete products/[string productId]/manage(@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Groups)
            returns http:NoContent|ErrorUnauthorized|ErrorForbidden|ErrorNotFound|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        if !isStoreOwner(X\-User\-Groups) {
            return <ErrorForbidden>{body: {code: 403, message: "Caller is not the Store Owner"}};
        }
        do {
            boolean removed = check deleteProductById(productId);
            if !removed {
                return <ErrorNotFound>{body: {code: 404, message: "Product not found"}};
            }
            return http:NO_CONTENT;
        } on fail error e {
            log:printError("failed to remove product", 'error = e, productId = productId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    // ---- Cart ----
    // openapi.yaml declares no `UserId` parameter and no 401/403 response on
    // any /carts/* operation — a cart is addressed solely by its opaque
    // cartId (generated client-side, per the issue), not by caller identity,
    // which also lets browsing-then-adding-to-cart work before sign-in.

    # Get a cart and its items
    #
    # + return - returns can be any of following types
    # http:Ok (Cart with line items)
    # http:NotFound (Cart not found)
    resource function get carts/[string cartId]() returns Cart|ErrorNotFound|http:InternalServerError {
        do {
            boolean exists = check cartExists(cartId);
            if !exists {
                return <ErrorNotFound>{body: {code: 404, message: "Cart not found"}};
            }
            return check buildCart(cartId);
        } on fail error e {
            log:printError("failed to get cart", 'error = e, cartId = cartId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Add a product to the cart
    #
    # + return - returns can be any of following types
    # http:Ok (Updated cart)
    # http:BadRequest (Product already sold or invalid)
    # http:NotFound (Cart or product not found)
    resource function post carts/[string cartId]/items(@http:Payload cartId_items_body payload)
            returns CartOk|ErrorBadRequest|ErrorNotFound|http:InternalServerError {
        do {
            string productId = payload.productId;
            string? status = check findProductStatus(productId);
            if status is () {
                return <ErrorNotFound>{body: {code: 404, message: "Product not found"}};
            }
            if status != "available" {
                return <ErrorBadRequest>{body: {code: 400, message: "Product already sold"}};
            }
            check ensureCart(cartId);
            check addItemToCart(cartId, productId);
            Cart cart = check buildCart(cartId);
            return <CartOk>{body: cart};
        } on fail error e {
            log:printError("failed to add cart item", 'error = e, cartId = cartId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Remove a product from the cart
    #
    # + return - returns can be any of following types
    # http:Ok (Updated cart)
    # http:NotFound (Cart or item not found)
    resource function delete carts/[string cartId]/items/[string productId]() returns Cart|ErrorNotFound|http:InternalServerError {
        do {
            boolean exists = check cartExists(cartId);
            if !exists {
                return <ErrorNotFound>{body: {code: 404, message: "Cart not found"}};
            }
            boolean itemExists = check cartItemExists(cartId, productId);
            if !itemExists {
                return <ErrorNotFound>{body: {code: 404, message: "Item not found in cart"}};
            }
            check removeItemFromCart(cartId, productId);
            return check buildCart(cartId);
        } on fail error e {
            log:printError("failed to remove cart item", 'error = e, cartId = cartId, productId = productId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    // ---- Orders ----

    # List orders (own orders for a Shopper, all orders for the Store Owner)
    #
    # + return - returns can be any of following types
    # http:Ok (Paged list of orders)
    # http:Unauthorized (Not signed in)
    resource function get orders(@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Groups,
            "new"|"shipped"|"delivered"? status, int 'limit = 20, int offset = 0)
            returns inline_response_200_1|ErrorUnauthorized|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        string callerId = X\-User\-Id;
        boolean owner = isStoreOwner(X\-User\-Groups);
        do {
            int effectiveLimit = clampLimit('limit);
            [Order[], int] result = check listOrders(callerId, owner, status, effectiveLimit, offset);
            Order[] orders = result[0];
            int total = result[1];
            inline_response_200_1 page = {
                count: total,
                data: orders
            };
            string? next = buildNextLink("/orders", effectiveLimit, offset, total, status);
            if next is string {
                page.next = next;
            }
            string? previous = buildPreviousLink("/orders", effectiveLimit, offset, status);
            if previous is string {
                page.previous = previous;
            }
            return page;
        } on fail error e {
            log:printError("failed to list orders", 'error = e);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Place an order from a cart (checkout)
    #
    # + return - returns can be any of following types
    # http:Created (Order created and payment charged)
    # http:BadRequest (Cart empty, item already sold, or payment declined)
    # http:Unauthorized (Not signed in)
    resource function post orders(@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Name, @http:Payload OrderInput payload)
            returns Order|ErrorBadRequest|ErrorUnauthorized|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        string shopperId = X\-User\-Id;
        do {
            CheckoutItem[] items = check getCheckoutItems(payload.cartId);
            if items.length() == 0 {
                return <ErrorBadRequest>{body: {code: 400, message: "Cart is empty"}};
            }
            foreach CheckoutItem item in items {
                if item.status != "available" {
                    return <ErrorBadRequest>{body: {code: 400, message: "Item " + item.productId + " is no longer available"}};
                }
            }
            decimal total = 0d;
            foreach CheckoutItem item in items {
                total += item.price;
            }
            PaymentResult paymentResult = check chargeCard(total, payload.paymentToken);
            if !paymentResult.succeeded {
                ErrorBadRequest declined = {body: {code: 400, message: "Payment declined"}};
                string? reason = paymentResult.failureReason;
                if reason is string {
                    declined.body.description = reason;
                }
                return declined;
            }
            Order createdOrder = check placeOrder(shopperId, payload.shippingAddress, payload.cartId, items, total);
            string? recipientEmail = asEmailAddress(X\-User\-Name);
            if recipientEmail is string {
                error? emailResult = sendOrderConfirmationEmail(recipientEmail, createdOrder);
                if emailResult is error {
                    log:printError("failed to send order confirmation email", 'error = emailResult, orderId = createdOrder.id);
                }
            } else {
                log:printWarn("no recipient email available for order confirmation", orderId = createdOrder.id);
            }
            return createdOrder;
        } on fail error e {
            log:printError("checkout failed", 'error = e);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Get one order's detail
    #
    # + return - returns can be any of following types
    # http:Ok (Order detail)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Caller does not own this order and is not the Store Owner)
    # http:NotFound (Order not found)
    resource function get orders/[string orderId](@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Groups)
            returns Order|ErrorUnauthorized|ErrorForbidden|ErrorNotFound|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        string callerId = X\-User\-Id;
        boolean owner = isStoreOwner(X\-User\-Groups);
        do {
            OrderDetail? detail = check getOrderDetail(orderId);
            if detail is () {
                return <ErrorNotFound>{body: {code: 404, message: "Order not found"}};
            }
            if !owner && detail.shopperId != callerId {
                return <ErrorForbidden>{body: {code: 403, message: "Caller does not own this order"}};
            }
            return toOrder(detail);
        } on fail error e {
            log:printError("failed to get order", 'error = e, orderId = orderId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }

    # Update an order's fulfillment status (Store Owner)
    #
    # + return - returns can be any of following types
    # http:Ok (Updated order)
    # http:Unauthorized (Not signed in)
    # http:Forbidden (Caller is not the Store Owner)
    # http:NotFound (Order not found)
    resource function patch orders/[string orderId](@http:Header string? X\-User\-Id, @http:Header string? X\-User\-Groups, @http:Payload orders_orderId_body payload)
            returns Order|ErrorUnauthorized|ErrorForbidden|ErrorNotFound|ErrorBadRequest|http:InternalServerError {
        if X\-User\-Id is () || X\-User\-Id.trim() == "" {
            return <ErrorUnauthorized>{body: {code: 401, message: "Not signed in"}};
        }
        if !isStoreOwner(X\-User\-Groups) {
            return <ErrorForbidden>{body: {code: 403, message: "Caller is not the Store Owner"}};
        }
        do {
            OrderDetail? detail = check getOrderDetail(orderId);
            if detail is () {
                return <ErrorNotFound>{body: {code: 404, message: "Order not found"}};
            }
            string targetStatus = payload.status;
            if !isValidOrderTransition(detail.status, targetStatus) {
                return <ErrorBadRequest>{body: {code: 400, message: "Invalid status transition from " + detail.status + " to " + targetStatus}};
            }
            check applyOrderStatus(orderId, targetStatus);
            OrderDetail? updated = check getOrderDetail(orderId);
            if updated is () {
                return <ErrorNotFound>{body: {code: 404, message: "Order not found"}};
            }
            return toOrder(updated);
        } on fail error e {
            log:printError("failed to update order status", 'error = e, orderId = orderId);
            return <http:InternalServerError>{body: {code: 500, message: "internal error"}};
        }
    }
}
