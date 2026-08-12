import ballerina/http;
import ballerinax/sendgrid;

// ballerinax/sendgrid is a real, published connector (bal search confirmed
// it) so it is used directly rather than a hand-rolled http:Client — the
// design.json `npm:@sendgrid/mail@^8` package id is the Node SDK and does
// not apply to this Ballerina service.
final sendgrid:Client sendgridClient = check new ({
    auth: {token: sendgridApiKey}
});

// Best-effort order-confirmation email; a delivery failure is logged by the
// caller and never fails checkout — the order is already committed by the
// time this runs.
isolated function sendOrderConfirmationEmail(string recipientEmail, Order placedOrder) returns error? {
    string itemLines = "";
    foreach OrderItem item in placedOrder.items {
        itemLines = itemLines + "\n - " + item.name + " ($" + item.price.toString() + ")";
    }
    string shippingAddress = placedOrder?.shippingAddress ?: "";
    string bodyText = "Thanks for your order!\n\nOrder: " + placedOrder.id +
        "\nTotal: $" + placedOrder.total.toString() +
        "\nShipping to: " + shippingAddress +
        "\nItems:" + itemLines;
    sendgrid:SendEmailRequest emailRequest = {
        personalizations: [{to: [{email: recipientEmail}]}],
        'from: {email: sendgridFromEmail},
        subject: "Your ceramics order is confirmed",
        content: [{'type: "text/plain", value: bodyText}]
    };
    http:Response|error result = sendgridClient->sendMail(emailRequest);
    if result is error {
        return result;
    }
}
