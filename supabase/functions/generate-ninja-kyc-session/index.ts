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
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) throw new Error("Unauthorized access");

    const { id_type, id_number } = await req.json();
    if (!id_type || (id_type !== "NIN" && id_type !== "BVN")) {
      throw new Error("Invalid id_type. Must be NIN or BVN.");
    }

    const clientKey = Deno.env.get("NINJA_CLIENT_KEY") || "pk_2108c812-2e5f-4aa0-adf1-e5306d163d9d";
    const clientSecret = Deno.env.get("NINJA_CLIENT_SECRET") || "sk_0fa5805c-4f86-4a3b-9dbc-173acafd7e15";
    const flowId = Deno.env.get("NINJA_FLOW_ID") || "vs_hinFgLR0ItroL7PcoMnStl7GMXTCF";
    const baseUrl = Deno.env.get("NINJA_BASE_URL") || "https://api.sandbox.ninja.boucloud.io";

    // 1. Get session token from Ninja Auth
    const sessionRes = await fetch(`${baseUrl}/auth/session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_key: clientKey,
        client_secret: clientSecret,
      }),
    });

    const sessionData = await sessionRes.json().catch(() => ({}));

    if (!sessionRes.ok || !sessionData.token) {
      console.error("Ninja auth session failed:", sessionRes.status, JSON.stringify(sessionData));
      throw new Error(`Ninja auth session failed: ${sessionData.error || sessionData.message || sessionRes.status}`);
    }

    const sessionToken = sessionData.token;

    // 2. Create actual verification link via /api/flows/:flow_id/links per Ninja Spec
    const linkRes = await fetch(`${baseUrl}/api/flows/${flowId}/links`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${sessionToken}`,
      },
      body: JSON.stringify({
        customer_ref: user.id,
      }),
    });

    const linkData = await linkRes.json().catch(() => ({}));

    if (!linkRes.ok || !linkData.url) {
      console.error("Ninja link creation failed:", linkRes.status, JSON.stringify(linkData));
      throw new Error(`Ninja link creation failed: ${linkData.error || linkData.message || linkRes.status}`);
    }

    const hostedUrl = linkData.url;
    const sessionLinkId = linkData.id || `ninja_sess_${Date.now()}`;

    const maskedId = id_number && id_number.length === 11
      ? `${id_number.substring(0, 4)}****${id_number.substring(7)}`
      : "1234****890";

    // Insert audit record into kyc_submissions
    await supabaseClient.from("kyc_submissions").insert({
      user_id: user.id,
      id_type: id_type,
      id_number_masked: maskedId,
      provider: "NINJA_HOSTED",
      session_id: sessionLinkId,
      status: "verifying",
    });

    // Update user profile kyc_status to verifying
    await supabaseClient
      .from("profiles")
      .update({ kyc_status: "verifying" })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({
        success: true,
        url: hostedUrl,
        hosted_url: hostedUrl,
        id: sessionLinkId,
        id_type: id_type,
        provider: "NINJA_HOSTED",
        environment: "sandbox",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    );
  }
});
