// Small helpers for the `next`/`previous` relative-URI pagination links on
// the two paged list responses (`/products`, `/orders`).

isolated function clampLimit(int requestedLimit) returns int {
    if requestedLimit > 100 {
        return 100;
    }
    if requestedLimit < 0 {
        return 0;
    }
    return requestedLimit;
}

isolated function buildPageLink(string basePath, int 'limit, int offset, string? status) returns string {
    string link = basePath + "?limit=" + 'limit.toString() + "&offset=" + offset.toString();
    if status is string {
        link = link + "&status=" + status;
    }
    return link;
}

isolated function buildNextLink(string basePath, int 'limit, int offset, int total, string? status) returns string? {
    int nextOffset = offset + 'limit;
    if 'limit <= 0 || nextOffset >= total {
        return ();
    }
    return buildPageLink(basePath, 'limit, nextOffset, status);
}

isolated function buildPreviousLink(string basePath, int 'limit, int offset, string? status) returns string? {
    if offset <= 0 {
        return ();
    }
    int previousOffset = offset - 'limit;
    if previousOffset < 0 {
        previousOffset = 0;
    }
    return buildPageLink(basePath, 'limit, previousOffset, status);
}
