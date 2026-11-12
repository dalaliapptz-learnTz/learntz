export type MobileMoneyProvider =
  | "mpesa_tz"
  | "mpesa_ke"
  | "airtel_money"
  | "tigo_pesa";

export type NormalizedCallback = {
  provider: MobileMoneyProvider;
  reference: string;
  status: "succeeded" | "failed";
  amount: number;
  currency: string;
  rawResponse: Record<string, unknown>;
};

export interface WebhookDependencies {
  resolveSecret: (provider: MobileMoneyProvider) => string | undefined;
  settleWebhook: (
    callback: NormalizedCallback,
  ) => Promise<Record<string, unknown>>;
  nowSeconds?: () => number;
}

const VALID_PROVIDERS = new Set<MobileMoneyProvider>([
  "mpesa_tz",
  "mpesa_ke",
  "airtel_money",
  "tigo_pesa",
]);

const ROUTE_PROVIDER_MAP: Record<string, MobileMoneyProvider> = {
  "mpesa-tz": "mpesa_tz",
  "mpesa_tz": "mpesa_tz",
  "mpesa-ke": "mpesa_ke",
  "mpesa_ke": "mpesa_ke",
  "airtel-money": "airtel_money",
  "airtel_money": "airtel_money",
  "tigo-pesa": "tigo_pesa",
  "tigo_pesa": "tigo_pesa",
};

export function resolveProviderFromRequest(
  url: URL,
  body: Record<string, unknown> | null,
): MobileMoneyProvider | null {
  const queryProvider = url.searchParams.get("provider");
  if (queryProvider && ROUTE_PROVIDER_MAP[queryProvider.trim().toLowerCase()]) {
    return ROUTE_PROVIDER_MAP[queryProvider.trim().toLowerCase()];
  }

  const segments = url.pathname.split("/").filter(Boolean);
  const tail = segments[segments.length - 1]?.toLowerCase();
  if (tail && ROUTE_PROVIDER_MAP[tail]) {
    return ROUTE_PROVIDER_MAP[tail];
  }

  const bodyProvider =
    typeof body?.provider === "string"
      ? body.provider.trim().toLowerCase()
      : "";
  if (bodyProvider && ROUTE_PROVIDER_MAP[bodyProvider]) {
    return ROUTE_PROVIDER_MAP[bodyProvider];
  }
  return null;
}

export async function computeHmacSha256Hex(
  secret: string,
  payload: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signatureBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );
  return Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function constantTimeHexEquals(a: string, b: string): boolean {
  const cleanA = a.trim().toLowerCase();
  const cleanB = b.trim().toLowerCase();
  if (cleanA.length === 0 || cleanA.length !== cleanB.length) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < cleanA.length; i++) {
    diff |= cleanA.charCodeAt(i) ^ cleanB.charCodeAt(i);
  }
  return diff === 0;
}

export async function verifyWebhookHmacSignature(params: {
  secret: string;
  signatureHeader: string | null;
  timestampHeader: string | null;
  rawBody: string;
  nowSeconds?: number;
  maxSkewSeconds?: number;
}): Promise<{ ok: true } | { ok: false; reason: string }> {
  const signature = params.signatureHeader?.replace(/^sha256=/i, "").trim();
  if (!signature || !/^[0-9a-fA-F]{64}$/.test(signature)) {
    return { ok: false, reason: "Missing or malformed HMAC signature" };
  }

  let signedMessage = params.rawBody;
  if (params.timestampHeader) {
    const parsedTs = Number(params.timestampHeader);
    if (!Number.isFinite(parsedTs)) {
      return { ok: false, reason: "Invalid webhook timestamp header" };
    }
    const now = params.nowSeconds ?? Math.floor(Date.now() / 1000);
    const maxSkew = params.maxSkewSeconds ?? 300;
    if (Math.abs(now - parsedTs) > maxSkew) {
      return { ok: false, reason: "Webhook timestamp outside allowed window" };
    }
    signedMessage = `${params.timestampHeader}.${params.rawBody}`;
  }

  const expected = await computeHmacSha256Hex(params.secret, signedMessage);
  if (!constantTimeHexEquals(signature, expected)) {
    return { ok: false, reason: "Invalid webhook HMAC signature" };
  }
  return { ok: true };
}

function asIntegerAmount(value: unknown): number {
  const num = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(num) || num <= 0) {
    throw new Error("Webhook payload is missing a valid positive amount");
  }
  return Math.round(num);
}

function normalizeGenericStatus(rawStatus: unknown, resultCode?: unknown): "succeeded" | "failed" {
  if (resultCode !== undefined && resultCode !== null) {
    return Number(resultCode) === 0 ? "succeeded" : "failed";
  }
  const s = String(rawStatus ?? "").trim().toLowerCase();
  if (["succeeded", "success", "completed", "paid", "ts"].includes(s)) {
    return "succeeded";
  }
  if (["failed", "fail", "cancelled", "rejected", "tf"].includes(s)) {
    return "failed";
  }
  throw new Error(`Unrecognized mobile money callback status: ${s}`);
}

export function normalizeMobileMoneyCallback(
  provider: MobileMoneyProvider,
  payload: Record<string, unknown>,
): NormalizedCallback {
  if (!VALID_PROVIDERS.has(provider)) {
    throw new Error(`Unsupported provider: ${provider}`);
  }

  // Safaricom Daraja STK callback envelope support
  if (provider === "mpesa_ke" && typeof payload.Body === "object" && payload.Body !== null) {
    const bodyObj = payload.Body as Record<string, unknown>;
    const stk = bodyObj.stkCallback as Record<string, unknown> | undefined;
    if (stk) {
      const metaItems =
        ((stk.CallbackMetadata as Record<string, unknown> | undefined)?.Item as
          | Array<Record<string, unknown>>
          | undefined) ?? [];
      const amountItem = metaItems.find((item) => item.Name === "Amount");
      const ref = String(
        payload.reference ??
          stk.ThirdPartyReference ??
          stk.MerchantRequestID ??
          stk.CheckoutRequestID ??
          "",
      ).trim();
      const amount = asIntegerAmount(payload.amount ?? amountItem?.Value);
      return {
        provider,
        reference: ref,
        status: normalizeGenericStatus(payload.status, stk.ResultCode),
        amount,
        currency: String(payload.currency ?? "KES").trim().toUpperCase(),
        rawResponse: payload,
      };
    }
  }

  // Airtel Money nested transaction envelope support
  if (provider === "airtel_money" && typeof payload.transaction === "object" && payload.transaction !== null) {
    const tx = payload.transaction as Record<string, unknown>;
    const ref = String(tx.reference ?? tx.id ?? payload.reference ?? "").trim();
    if (!ref) {
      throw new Error("Airtel Money callback missing transaction reference");
    }
    return {
      provider,
      reference: ref,
      status: normalizeGenericStatus(tx.status_code ?? tx.status),
      amount: asIntegerAmount(tx.amount ?? payload.amount),
      currency: String(tx.currency ?? payload.currency ?? "TZS").trim().toUpperCase(),
      rawResponse: payload,
    };
  }

  // Standard M-Pesa TZ/KE and Tigo Pesa normalized envelope
  const defaultCurrency = provider === "mpesa_ke" ? "KES" : "TZS";
  const reference = String(
    payload.reference ??
      payload.ReferenceID ??
      payload.ThirdPartyConversationID ??
      payload.TransactionID ??
      "",
  ).trim();
  if (!reference) {
    throw new Error(`Missing transaction reference for ${provider}`);
  }

  const amount = asIntegerAmount(payload.amount ?? payload.Amount ?? payload.TransAmount);
  const currency = String(payload.currency ?? payload.Currency ?? defaultCurrency)
    .trim()
    .toUpperCase();
  const status = normalizeGenericStatus(
    payload.status ?? payload.Status,
    payload.ResultCode,
  );

  return {
    provider,
    reference,
    status,
    amount,
    currency,
    rawResponse: payload,
  };
}

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export async function handleMobileMoneyWebhookRequest(
  req: Request,
  deps: WebhookDependencies,
): Promise<Response> {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const rawBody = await req.text();
  let parsedBody: Record<string, unknown>;
  try {
    const decoded = JSON.parse(rawBody);
    if (!decoded || typeof decoded !== "object" || Array.isArray(decoded)) {
      return jsonResponse(400, { error: "Webhook payload must be a JSON object" });
    }
    parsedBody = decoded as Record<string, unknown>;
  } catch {
    return jsonResponse(400, { error: "Malformed JSON webhook payload" });
  }

  const url = new URL(req.url);
  const provider = resolveProviderFromRequest(url, parsedBody);
  if (!provider) {
    return jsonResponse(400, { error: "Unsupported or missing mobile money provider" });
  }

  const secret = deps.resolveSecret(provider);
  if (!secret) {
    return jsonResponse(500, { error: "Webhook signing secret is not configured" });
  }

  const signatureCheck = await verifyWebhookHmacSignature({
    secret,
    signatureHeader:
      req.headers.get("x-learntz-signature") ?? req.headers.get("x-webhook-signature"),
    timestampHeader: req.headers.get("x-learntz-timestamp"),
    rawBody,
    nowSeconds: deps.nowSeconds ? deps.nowSeconds() : undefined,
  });
  if (!signatureCheck.ok) {
    return jsonResponse(401, { error: signatureCheck.reason });
  }

  let normalized: NormalizedCallback;
  try {
    normalized = normalizeMobileMoneyCallback(provider, parsedBody);
  } catch (err) {
    return jsonResponse(400, {
      error: err instanceof Error ? err.message : "Invalid callback payload",
    });
  }

  try {
    const result = await deps.settleWebhook(normalized);
    return jsonResponse(200, result);
  } catch (err) {
    return jsonResponse(422, {
      error: err instanceof Error ? err.message : "Webhook settlement failed",
    });
  }
}
