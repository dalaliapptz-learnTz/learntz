import {
  computeHmacSha256Hex,
  handleMobileMoneyWebhookRequest,
  normalizeMobileMoneyCallback,
  type NormalizedCallback,
} from "../_shared/mobile_money.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const TEST_SECRET = "learntz-sandbox-hmac-secret-2026";

Deno.test("rejects missing or invalid HMAC signature", async () => {
  const rawBody = JSON.stringify({
    provider: "mpesa_tz",
    reference: "LTZ-1234567890",
    status: "succeeded",
    amount: 1500000,
    currency: "TZS",
  });
  const req = new Request("https://edge.local/mobile-money-webhook", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-learntz-signature": "0".repeat(64),
    },
    body: rawBody,
  });

  const resp = await handleMobileMoneyWebhookRequest(req, {
    resolveSecret: () => TEST_SECRET,
    settleWebhook: () => Promise.resolve({ ok: true }),
  });
  assertEquals(resp.status, 401);
});

Deno.test("rejects replayed timestamp outside allowed window", async () => {
  const rawBody = JSON.stringify({
    provider: "tigo_pesa",
    reference: "LTZ-TIGO-999",
    status: "succeeded",
    amount: 1500000,
    currency: "TZS",
  });
  const staleTs = "1700000000";
  const sig = await computeHmacSha256Hex(TEST_SECRET, `${staleTs}.${rawBody}`);
  const req = new Request("https://edge.local/mobile-money-webhook/tigo-pesa", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-learntz-timestamp": staleTs,
      "x-learntz-signature": `sha256=${sig}`,
    },
    body: rawBody,
  });

  const resp = await handleMobileMoneyWebhookRequest(req, {
    resolveSecret: () => TEST_SECRET,
    settleWebhook: () => Promise.resolve({ ok: true }),
    nowSeconds: () => 1700001000,
  });
  assertEquals(resp.status, 401);
});

Deno.test("verifies valid timestamped HMAC and settles M-Pesa TZ, M-Pesa KE, Airtel Money, and Tigo Pesa idempotently", async () => {
  const settled: NormalizedCallback[] = [];
  const seenRefs = new Set<string>();
  const deps = {
    resolveSecret: () => TEST_SECRET,
    nowSeconds: () => 1762950000,
    settleWebhook: (cb: NormalizedCallback) => {
      const duplicate = seenRefs.has(cb.reference);
      seenRefs.add(cb.reference);
      settled.push(cb);
      return Promise.resolve({
        ok: true,
        idempotent: duplicate,
        reference: cb.reference,
        transaction_status: cb.status,
        subscription_status: cb.status === "succeeded" ? "active" : "past_due",
      });
    },
  };

  // 1. Vodacom M-Pesa TZ (plus duplicate replay within skew)
  const mpesaBody = JSON.stringify({
    reference: "LTZ-MPESA-TZ-01",
    ResultCode: 0,
    Amount: 1500000,
    Currency: "TZS",
    TransactionID: "MPE998877",
  });
  const ts = "1762950000";
  const mpesaSig = await computeHmacSha256Hex(TEST_SECRET, `${ts}.${mpesaBody}`);

  const r1 = await handleMobileMoneyWebhookRequest(
    new Request("https://edge.local/mobile-money-webhook/mpesa-tz", {
      method: "POST",
      headers: {
        "x-learntz-timestamp": ts,
        "x-learntz-signature": mpesaSig,
      },
      body: mpesaBody,
    }),
    deps,
  );
  assertEquals(r1.status, 200);
  const j1 = await r1.json();
  assertEquals(j1.idempotent, false);
  assertEquals(j1.subscription_status, "active");

  const rDup = await handleMobileMoneyWebhookRequest(
    new Request("https://edge.local/mobile-money-webhook/mpesa-tz", {
      method: "POST",
      headers: {
        "x-learntz-timestamp": ts,
        "x-learntz-signature": mpesaSig,
      },
      body: mpesaBody,
    }),
    deps,
  );
  assertEquals(rDup.status, 200);
  assertEquals((await rDup.json()).idempotent, true);

  // 2. Safaricom Daraja M-Pesa KE envelope
  const keNormalized = normalizeMobileMoneyCallback("mpesa_ke", {
    Body: {
      stkCallback: {
        MerchantRequestID: "LTZ-KE-88",
        ResultCode: 0,
        CallbackMetadata: {
          Item: [{ Name: "Amount", Value: 100000 }],
        },
      },
    },
  });
  assertEquals(keNormalized.reference, "LTZ-KE-88");
  assertEquals(keNormalized.amount, 100000);
  assertEquals(keNormalized.currency, "KES");
  assertEquals(keNormalized.status, "succeeded");

  // 3. Airtel Money nested transaction envelope
  const airtelBody = JSON.stringify({
    transaction: {
      id: "LTZ-AIRTEL-01",
      status_code: "TF",
      amount: 1500000,
      currency: "TZS",
    },
  });
  const airtelSig = await computeHmacSha256Hex(TEST_SECRET, airtelBody);
  const rAirtel = await handleMobileMoneyWebhookRequest(
    new Request("https://edge.local/mobile-money-webhook?provider=airtel_money", {
      method: "POST",
      headers: { "x-learntz-signature": airtelSig },
      body: airtelBody,
    }),
    deps,
  );
  assertEquals(rAirtel.status, 200);
  assertEquals((await rAirtel.json()).transaction_status, "failed");
  assertEquals(settled.length, 3);
});
