// Role resolution per security.md: the gateway injects the caller's verified
// identity as headers. `X-User-Id` (the `UserId` parameter in openapi.yaml)
// is required on every protected op; its absence means the request did not
// come through the gateway. `X-User-Groups` is not part of the documented
// contract (openapi.yaml only declares `UserId`), but the platform still
// injects it — see api-management/thunder-authentication — so the Store
// Owner claim is read straight off the header rather than a token we never
// see.

// Case-insensitive substring match on "owner" against the caller's groups —
// survives the org renaming its groups, unlike an equality check.
isolated function isStoreOwner(string? groupsHeader) returns boolean {
    string[] groups = parseUserGroups(groupsHeader);
    foreach string group in groups {
        string lowerGroup = group.toLowerAscii();
        if lowerGroup.includes("owner") {
            return true;
        }
    }
    return false;
}

// `X-User-Groups` arrives as a JSON array (e.g. ["Store Owner"]); a
// comma-separated string is accepted as a fallback parse.
isolated function parseUserGroups(string? groupsHeader) returns string[] {
    if groupsHeader is () {
        return [];
    }
    string trimmedHeader = groupsHeader.trim();
    if trimmedHeader == "" {
        return [];
    }
    json|error parsedHeader = trimmedHeader.fromJsonString();
    if parsedHeader is json[] {
        string[] groups = [];
        foreach json item in parsedHeader {
            if item is string {
                groups.push(item);
            }
        }
        return groups;
    }
    string[] parts = re `,\s*`.split(trimmedHeader);
    string[] groups = [];
    foreach string part in parts {
        string trimmedPart = part.trim();
        if trimmedPart != "" {
            groups.push(trimmedPart);
        }
    }
    return groups;
}

// A username that looks like an email — Thunder commonly provisions the
// shopper's email as their username. openapi.yaml has no dedicated
// recipient-email field/header for the order-confirmation email, so this is
// the narrowest signal available; see the final report for the trade-off.
isolated function asEmailAddress(string? userName) returns string? {
    if userName is string && userName.includes("@") {
        return userName;
    }
    return ();
}
