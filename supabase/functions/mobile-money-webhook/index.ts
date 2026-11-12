import {
  handleMobileMoneyWebhookRequest,
  type MobileMoneyProvider,
  type NormalizedCallback,
} from "../_shared/mobile_money.ts";

function resolveSecret(provider: MobileMoneyProvider): string | undefined {
  switch (provider) {
    case "mpesa_tz":
    case "mpesa_ke":
      return (
        Deno.env.get("MPESA_WEBHOOK_SECRET") ??
        Deno.env.get("MOBILE_MONEY_WEBHOOK_SECRET")
      );
    case "airtel_money":
      return (
        Deno.env.get("AIRTEL_MONEY_WEBHOOK_SECRET") ??
        Deno.env.get("MOBILE_MONEY_WEBHOOK_SECRET")
      );
    case "tigo_pesa":
      return (
        Deno.env.get("TIGO_PESA_WEBHOOK_SECRET") ??
        Deno.env.get("MOBILE_MONEY_WEBHOOK_SECRET")
      );
  }
}

async function settleWebhook(
  callback: NormalizedCallback,
): Promise<Record<string, unknown>> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Supabase service credentials are not configured");
  }

  const response = await fetch(
    `${supabaseUrl}/rest/v1/rpc/process_mobile_money_webhook`,
    {
      method: "POST",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        p_provider: callback.provider,
        p_reference: callback.reference,
        p_status: callback.status,
        p_amount: callback.amount,
        p_currency: callback.currency,
        p_raw_response: callback.rawResponse,
      }),
    },
  );

  const rawText = await response.text();
  if (!response.ok) {
    throw new Error(`RPC process_mobile_money_webhook failed (${response.status}): ${rawText}`);
  }
  return rawText ? JSON.parse(rawText) : { ok: true };
}

Deno.serve((req: Request) =>
  handleMobileMoneyWebhookRequest(req, {
    resolveSecret,
    settleWebhook,
  })
);
