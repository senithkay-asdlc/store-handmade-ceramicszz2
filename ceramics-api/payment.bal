import ballerina/http;
import ballerinax/stripe;

// ballerinax/stripe is a real, published connector (bal search confirmed it)
// so it is used directly rather than a hand-rolled http:Client — the
// design.json `npm:stripe@^14` package id is the Node SDK and does not apply
// to this Ballerina service.
final stripe:Client stripeClient = check new ({
    auth: {token: stripeApiKey}
});

public type PaymentResult record {|
    boolean succeeded;
    string? failureReason;
|};

// Creates and immediately confirms a PaymentIntent for the cart total. A
// decline surfaces from the connector as an `http:ApplicationResponseError`
// (Stripe returns 402 with `error.type: card_error` in the body) — that is
// translated into a non-throwing `succeeded: false` result so the caller can
// return 400 without treating it as an infrastructure failure.
isolated function chargeCard(decimal amountInStoreCurrency, string paymentToken) returns PaymentResult|error {
    int amountInCents = <int>(amountInStoreCurrency * 100);
    stripe:payment_intents_body chargeRequest = {
        amount: amountInCents,
        currency: "usd",
        payment_method: paymentToken,
        confirm: true,
        automatic_payment_methods: {enabled: true, allow_redirects: "never"}
    };
    stripe:Payment_intent|error result = stripeClient->/payment_intents.post(chargeRequest);
    if result is http:ApplicationResponseError {
        string failureReason = describeStripeError(result);
        return {succeeded: false, failureReason: failureReason};
    }
    if result is error {
        return result;
    }
    if result.status == "succeeded" {
        return {succeeded: true, failureReason: ()};
    }
    return {succeeded: false, failureReason: "payment not completed, status: " + result.status};
}

type StripeErrorDetail record {
    string message?;
    string 'type?;
    string code?;
};

type StripeErrorBody record {
    StripeErrorDetail 'error?;
};

isolated function describeStripeError(http:ApplicationResponseError responseError) returns string {
    anydata errorBody = responseError.detail().body;
    StripeErrorBody|error parsed = errorBody.cloneWithType(StripeErrorBody);
    if parsed is StripeErrorBody {
        StripeErrorDetail? detail = parsed?.'error;
        if detail is StripeErrorDetail {
            string? message = detail?.message;
            if message is string {
                return message;
            }
        }
    }
    return responseError.message();
}
