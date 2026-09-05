/// <reference types="https://deno.land/x/deploy@0.12.0/types.d.ts" />
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-breet-signature",
};

async function verifyHmacSignature(rawBody: string, signatureHeader: string, secret: string): Promise<boolean> {
  if (!signatureHeader || !secret || secret.includes("your_breet")) return true; // Skip if secret not configured or default placeholder
  try {
    const encoder = new TextEncoder();
    const key = await crypto.subcrypto.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signatureBuffer = await crypto.subcrypto.sign("HMAC", key, encoder.encode(rawBody));
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const calculatedSignature = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
    return calculatedSignature.toLowerCase() === signatureHeader.toLowerCase();
  } catch (err: any) {
    console.error("Signature verification exception:", err.message);
    return false;
  }
}

Deno.serve(async (req) => {
  // 1. Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 2. Handle GET / HEAD verification requests (Breet ping check when saving URL)
  if (req.method === "GET" || req.method === "HEAD") {
    return new Response(
      JSON.stringify({ status: "success", message: "Breet webhook endpoint is active" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    const rawBody = await req.text();
    const signature = req.headers.get("x-breet-signature") || "";
    const webhookSecret = Deno.env.get("BREET_WEBHOOK_SECRET") || "";

    // 3. Handle empty body or test ping requests during webhook URL creation
    if (!rawBody || rawBody.trim() === "") {
      return new Response(
        JSON.stringify({ status: "success", message: "Webhook endpoint verified" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let payload: any = {};
    try {
      payload = JSON.parse(rawBody);
    } catch (_e) {
      // Return 200 OK for plain text verification ping
      return new Response(
        JSON.stringify({ status: "success", message: "Webhook URL verified" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log("Breet Webhook received:", JSON.stringify(payload));

    const event = payload.event || payload.type || "trade.completed";

    // 4. Handle verification / test events sent when saving in Breet Dashboard
    if (
      event === "ping" ||
      event === "url_verification" ||
      event === "webhook.test" ||
      event === "verification" ||
      payload.challenge != null
    ) {
      return new Response(
        JSON.stringify({
          status: "success",
          message: "Breet webhook URL verified successfully",
          challenge: payload.challenge || undefined,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Signature verification for live production trade events
    if (webhookSecret && signature && !webhookSecret.includes("your_breet")) {
      const isValid = await verifyHmacSignature(rawBody, signature, webhookSecret);
      if (!isValid) {
        return new Response(JSON.stringify({ error: "Invalid HMAC signature" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const data = payload.data || payload.trade || payload;

    // 6. Deduplication check
    const eventId = payload.id || data.id || data.reference || `evt_${Date.now()}`;
    const { data: existingEvent } = await supabaseAdmin
      .from("webhook_events")
      .select("id")
      .eq("event_id", eventId)
      .maybeSingle();

    if (existingEvent) {
      return new Response(JSON.stringify({ status: "already_processed", eventId }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    await supabaseAdmin.from("webhook_events").insert({
      event_id: eventId,
      provider: "BREET",
      received_at: new Date().toISOString(),
    });

    // 7. Extract trade details
    const label = data.label || payload.label || "";
    const reference = data.reference || data.id || data.tradeId || `breet_${Date.now()}`;
    const rawFiatAmount = Number(data.fiatAmount || data.amountInNgn || data.convertedAmount || 0);
    const cryptoAmount = Number(data.cryptoAmount || data.amount || 0);
    const coinSymbol = data.coin || data.symbol || data.asset || "USDT";
    const walletAddress = data.walletAddress || data.address || "";
    const rate = Number(data.rate || data.exchangeRate || 0);

    // Compute Ryzon Markup: 1% capped at ₦50
    const markupRate = Number(Deno.env.get("BREET_MARKUP_PERCENT") || "1.0") / 100.0;
    const markupCap = Number(Deno.env.get("BREET_MARKUP_CAP_NGN") || "50.0");
    const calculatedFee = Math.min(rawFiatAmount * markupRate, markupCap);
    const netPayoutAmount = Math.max(0, rawFiatAmount - calculatedFee);

    // Resolve user ID
    let userId = label.replace("ryzon_user_", "").replace("user-", "").trim();

    if (!userId && walletAddress) {
      const { data: addressRow } = await supabaseAdmin
        .from("crypto_deposit_addresses")
        .select("user_id")
        .eq("address", walletAddress)
        .maybeSingle();
      if (addressRow) userId = addressRow.user_id;
    }

    if ((event === "trade.completed" || event === "deposit.confirmed") && userId) {
      // Fetch user settlement mode
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("settlement_mode, wallet_balance_ngn")
        .eq("id", userId)
        .maybeSingle();

      const userSettlementMode = profile?.settlement_mode || "AUTO_SETTLEMENT";

      // Log transaction in ledger
      await supabaseAdmin.from("transactions").insert({
        user_id: userId,
        reference: reference,
        breet_trade_id: reference,
        type: "DEPOSIT_CONVERT",
        status: "COMPLETED",
        crypto_token: coinSymbol.includes("USDC") ? "USDC" : "USDT",
        crypto_amount: cryptoAmount,
        chain: "BSC",
        exchange_rate: rate,
        naira_amount: rawFiatAmount,
        fee_naira: calculatedFee,
        net_naira_payout: netPayoutAmount,
        settlement_mode: userSettlementMode,
        completed_at: new Date().toISOString(),
      });

      // Update NGN balance if Manual Balance mode
      if (userSettlementMode === "MANUAL_BALANCE") {
        const currentBalance = Number(profile?.wallet_balance_ngn || 0);
        const newBalance = currentBalance + netPayoutAmount;
        await supabaseAdmin
          .from("profiles")
          .update({ wallet_balance_ngn: newBalance, updated_at: new Date().toISOString() })
          .eq("id", userId);
      }
    }

    return new Response(
      JSON.stringify({
        status: "success",
        reference: reference,
        netPayout: netPayoutAmount,
        ryzonFee: calculatedFee,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Error processing Breet webhook:", error.message);
    // Always return HTTP 200 for verification requests or log error
    return new Response(
      JSON.stringify({ status: "error", message: error.message }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
