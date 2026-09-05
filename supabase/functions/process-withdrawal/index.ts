/// <reference types="https://deno.land/x/deploy@0.12.0/types.d.ts" />
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function computeHmacSha256(text: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subcrypto.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signatureBuffer = await crypto.subcrypto.sign("HMAC", key, encoder.encode(text));
  const hashArray = Array.from(new Uint8Array(signatureBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

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
    const bankAccountId = body.bankAccountId;
    const amount = Number(body.amount || 0);
    const pinCode = body.pinCode;

    if (!amount || amount <= 0) {
      return new Response(JSON.stringify({ error: "Invalid withdrawal amount" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!pinCode || pinCode.length !== 4) {
      return new Response(JSON.stringify({ error: "4-digit Transaction PIN is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    // 1. Fetch user profile
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("pin_hash, kyc_tier, kyc_status, wallet_balance_ngn")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return new Response(JSON.stringify({ error: "User profile not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Verify Transaction PIN
    const pinSecret = Deno.env.get("PIN_HMAC_SECRET") || "ryzon_pin_secret_key";
    const expectedPinHash = await computeHmacSha256(pinCode, pinSecret);

    if (profile.pin_hash && profile.pin_hash !== expectedPinHash) {
      return new Response(JSON.stringify({ error: "Incorrect Transaction PIN" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Check KYC Limits
    if (profile.kyc_status !== "verified" && (profile.kyc_tier ?? 0) < 1) {
      return new Response(
        JSON.stringify({ error: "KYC verification required before making bank withdrawals. Please complete Ninja KYC." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Atomically Deduct Balance using RPC
    const { data: newBalance, error: deductError } = await supabaseAdmin.rpc("deduct_user_balance", {
      p_user_id: user.id,
      p_amount: amount,
    });

    if (deductError) {
      return new Response(
        JSON.stringify({ error: deductError.message || "Insufficient wallet balance" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Log Transaction
    const reference = `RYZ-WTH-${Date.now()}`;
    await supabaseAdmin.from("transactions").insert({
      user_id: user.id,
      reference: reference,
      type: "WITHDRAWAL",
      status: "COMPLETED",
      crypto_token: "USDT",
      crypto_amount: 0,
      chain: "BSC",
      exchange_rate: 1.0,
      naira_amount: amount,
      fee_naira: 20.0, // Standard NGN transfer fee
      payout_reference: reference,
      completed_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        status: "success",
        reference: reference,
        amountWithdrawn: amount,
        fee: 20.0,
        newBalance: newBalance,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Withdrawal error:", error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
