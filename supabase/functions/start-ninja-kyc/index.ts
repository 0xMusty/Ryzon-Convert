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

    // 1. Authenticate user JWT
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) throw new Error("Unauthorized access");

    // 2. Fetch user profile signup names
    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("first_name, last_name")
      .eq("id", user.id)
      .single();

    const firstName = profile?.first_name || "Valued";
    const lastName = profile?.last_name || "Customer";

    // 3. Ninja API Credentials & Flow Configuration
    const baseUrl = Deno.env.get("NINJA_BASE_URL") || "https://api.sandbox.ninja.boucloud.io";
    const clientKey = Deno.env.get("NINJA_CLIENT_KEY") || "pk_2108c812-2e5f-4aa0-adf1-e5306d163d9d";
    const clientSecret = Deno.env.get("NINJA_CLIENT_SECRET") || "sk_0fa5805c-4f86-4a3b-9dbc-173acafd7e15";
    const flowId = Deno.env.get("NINJA_FLOW_ID") || "vs_hinFgLR0ItroL7PcoMnStl7GMXTCF";

    // 4. STEP 1: Fetch fresh session token (5 min TTL)
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

    // 5. STEP 2: Generate Hosted Verification Link
    const linkRes = await fetch(`${baseUrl}/api/flows/${flowId}/links`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${sessionToken}`,
      },
      body: JSON.stringify({
        customer_ref: user.id,
        values: {
          first_name: firstName,
          last_name: lastName,
        },
      }),
    });

    const linkData = await linkRes.json().catch(() => ({}));

    if (!linkRes.ok || !linkData.url) {
      console.error("Ninja link creation failed:", linkRes.status, JSON.stringify(linkData));
      throw new Error(`Ninja link creation failed: ${linkData.error || linkData.message || linkRes.status}`);
    }

    const hostedUrl = linkData.url;
    const linkId = linkData.id || `vs_${Date.now()}`;

    // 6. Record submission in DB
    await supabaseClient.from("kyc_submissions").insert({
      user_id: user.id,
      link_id: linkId,
      hosted_url: hostedUrl,
      status: "pending",
    });

    // Update profile kyc_status to pending
    await supabaseClient
      .from("profiles")
      .update({ kyc_status: "pending" })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({
        success: true,
        url: hostedUrl,
        link_id: linkId,
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
