import createClient from "openapi-fetch";
import type { paths, components } from "./generated/ceramics-api";
import { env } from "./env";
import { getAccessToken } from "./auth";

const BASE_URL = env.CERAMICS_API_URL;
if (!BASE_URL) {
  throw new Error("CERAMICS_API_URL not set in window._env_");
}

export const ceramicsApi = createClient<paths>({ baseUrl: BASE_URL });

export type Product = components["schemas"]["Product"];
export type ProductInput = components["schemas"]["ProductInput"];
export type Cart = components["schemas"]["Cart"];
export type Order = components["schemas"]["Order"];
export type OrderInput = components["schemas"]["OrderInput"];
export type ApiError = components["schemas"]["Error"];

async function authHeaders(): Promise<Record<string, string>> {
  const token = await getAccessToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

/**
 * `X-User-Id` is documented on the contract as "injected by the gateway from
 * the validated token" (see api-management / thunder-authentication) — the
 * gateway overwrites whatever a client sends here from the caller's verified
 * bearer token, so this placeholder only satisfies the generated type; it is
 * never the value the backend actually authorizes on.
 */
const GATEWAY_INJECTED_USER_ID = "gateway-injected";

export class ApiRequestError extends Error {
  status: number;
  body: ApiError | undefined;
  constructor(status: number, body?: ApiError) {
    super(body?.message ?? `Request failed with status ${status}`);
    this.status = status;
    this.body = body;
  }
}

// ---- Catalog (public) ----

export async function listAvailableProducts(): Promise<Product[]> {
  const { data, error } = await ceramicsApi.GET("/products", {
    params: { query: { limit: 100, offset: 0 } },
  });
  if (error) throw new ApiRequestError(500, error as ApiError);
  return data.data;
}

export async function getProduct(productId: string): Promise<Product> {
  const { data, error, response } = await ceramicsApi.GET("/products/{productId}", {
    params: { path: { productId } },
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

// ---- Cart (public — scoped by the client-generated cart id) ----

export async function getCart(cartId: string): Promise<Cart | null> {
  const { data, error, response } = await ceramicsApi.GET("/carts/{cartId}", {
    params: { path: { cartId } },
  });
  if (error) {
    if (response.status === 404) return null;
    throw new ApiRequestError(response.status, error);
  }
  return data;
}

export async function addCartItem(cartId: string, productId: string): Promise<Cart> {
  const { data, error, response } = await ceramicsApi.POST("/carts/{cartId}/items", {
    params: { path: { cartId } },
    body: { productId },
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

export async function removeCartItem(cartId: string, productId: string): Promise<Cart> {
  const { data, error, response } = await ceramicsApi.DELETE("/carts/{cartId}/items/{productId}", {
    params: { path: { cartId, productId } },
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

// ---- Orders (signed-in) ----

export async function listOrders(status?: "new" | "shipped" | "delivered"): Promise<Order[]> {
  const headers = await authHeaders();
  const { data, error, response } = await ceramicsApi.GET("/orders", {
    params: {
      header: { "X-User-Id": GATEWAY_INJECTED_USER_ID },
      query: { status, limit: 100, offset: 0 },
    },
    headers,
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data.data;
}

export async function createOrder(input: OrderInput): Promise<Order> {
  const headers = await authHeaders();
  const { data, error, response } = await ceramicsApi.POST("/orders", {
    params: { header: { "X-User-Id": GATEWAY_INJECTED_USER_ID } },
    headers,
    body: input,
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

export async function updateOrderStatus(
  orderId: string,
  status: "new" | "shipped" | "delivered",
): Promise<Order> {
  const headers = await authHeaders();
  const { data, error, response } = await ceramicsApi.PATCH("/orders/{orderId}", {
    params: { path: { orderId }, header: { "X-User-Id": GATEWAY_INJECTED_USER_ID } },
    headers,
    body: { status },
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

// ---- Owner catalog management (signed-in, Store-Owner) ----

export async function createProduct(input: ProductInput): Promise<Product> {
  const headers = await authHeaders();
  const { data, error, response } = await ceramicsApi.POST("/products/manage", {
    params: { header: { "X-User-Id": GATEWAY_INJECTED_USER_ID } },
    headers,
    body: input,
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

export async function updateProduct(productId: string, input: ProductInput): Promise<Product> {
  const headers = await authHeaders();
  const { data, error, response } = await ceramicsApi.PUT("/products/{productId}/manage", {
    params: { path: { productId }, header: { "X-User-Id": GATEWAY_INJECTED_USER_ID } },
    headers,
    body: input,
  });
  if (error) throw new ApiRequestError(response.status, error);
  return data;
}

export async function removeProduct(productId: string): Promise<void> {
  const headers = await authHeaders();
  const { error, response } = await ceramicsApi.DELETE("/products/{productId}/manage", {
    params: { path: { productId }, header: { "X-User-Id": GATEWAY_INJECTED_USER_ID } },
    headers,
  });
  if (error) throw new ApiRequestError(response.status, error);
}
