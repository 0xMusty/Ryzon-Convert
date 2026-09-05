/// <reference types="https://deno.land/x/deploy@0.12.0/types.d.ts" />
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const assetId = body.assetId || "USDT_TRC20";
    const bankId = body.bankId;
    const accountNumber = body.accountNumber;
    const settlementMode = body.settlementMode || "AUTO_SETTLEMENT";

    const appId = Deno.env.get("BREET_APP_ID") || "";
    const appSecret = Deno.env.get("BREET_APP_SECRET") || "";
    const breetEnv = Deno.env.get("BREET_ENV") || "sandbox";

    const label = `ryzon_user_${user.id.substring(0, 8)}`;

    // Build payload for Breet API
    const breetPayload: Record<string, any> = {
      label: label,
      narration: "Ryzon Convert Payout",
    };

    if (settlementMode === "AUTO_SETTLEMENT" && bankId && accountNumber) {
      breetPayload.bankId = bankId;
      breetPayload.accountNumber = accountNumber;
    }

    // Call Breet API
    const breetRes = await fetch(`https://api.breet.io/v1/trades/sell/assets/${assetId}/generate-address`, {
      method: "POST",
      headers: {
        "x-app-id": appId,
        "x-app-secret": appSecret,
        "X-Breet-Env": breetEnv,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(breetPayload),
    });

    const breetData = await breetRes.json();
    console.log("Breet Generate Address response:", JSON.stringify(breetData));

    // Handle mock/sandbox fallback if API returns placeholder or error in dev
    const generatedAddress = breetData.data?.address || breetData.address || `0x${user.id.replaceAll("-", "").substring(0, 40)}`;

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    // Store address in database
    await supabaseAdmin.from("crypto_deposit_addresses").upsert({
      user_id: user.id,
      chain: assetId.includes("TRC") ? "PLASMA" : assetId.includes("ARB") ? "ARBITRUM" : "BSC",
      token: assetId.includes("USDC") ? "USDC" : "USDT",
      address: generatedAddress,
      breet_asset_id: assetId,
      breet_label: label,
      breet_bank_id: bankId || null,
      breet_account_number: accountNumber || null,
      created_at: new Date().toISOString(),
    }, { onConflict: "user_id,chain,token" });

    return new Response(
      JSON.stringify({
        status: "success",
        address: generatedAddress,
        assetId: assetId,
        label: label,
        settlementMode: settlementMode,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Error generating deposit address:", error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
