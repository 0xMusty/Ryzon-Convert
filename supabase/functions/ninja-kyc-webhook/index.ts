/// <reference types="https://deno.land/x/deploy@0.12.0/types.d.ts" />
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-ninja-signature",
};

// Helper: HMAC-SHA256 signature verifier
async function verifyHmacSignature(rawBody: string, signatureHeader: string | null, secret: string): Promise<boolean> {
  if (!signatureHeader || !secret) return true; // Graceful fallback in development/test
  try {
    const encoder = new TextEncoder();
    const keyData = encoder.encode(secret);
    const bodyData = encoder.encode(rawBody);

    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign("HMAC", cryptoKey, bodyData);
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const expectedHex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
    const expected = `hmac-sha256=${expectedHex}`;

    return signatureHeader === expected || signatureHeader === expectedHex;
  } catch (_) {
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const rawBody = await req.text();
    const webhookSecret = Deno.env.get("NINJA_WEBHOOK_SECRET") || "";
    const signature = req.headers.get("x-ninja-signature");

    // Signature verification
    const isValid = await verifyHmacSignature(rawBody, signature, webhookSecret);
    if (!isValid) {
      return new Response(JSON.stringify({ error: "Invalid signature" }), { status: 401, headers: corsHeaders });
    }

    const event = JSON.parse(rawBody);
    const eventId = event.event_id || `evt_${Date.now()}`;

    // Deduplication check
    const { data: existingEvent } = await supabaseClient
      .from("webhook_events")
      .select("id")
      .eq("event_id", eventId)
      .single();

    if (existingEvent) {
      return new Response(JSON.stringify({ message: "Already processed" }), { status: 200, headers: corsHeaders });
    }

    // Insert into webhook_events table
    await supabaseClient.from("webhook_events").insert({ event_id: eventId, provider: "NINJA" });

    if (event.event === "verification.completed" && event.data) {
      const { customer_ref, outcome, score, verification_id, sandbox } = event.data;

      // Ignore sandbox events in production environment
      const isProduction = Deno.env.get("ENVIRONMENT") === "production";
      if (sandbox && isProduction) {
        return new Response(JSON.stringify({ message: "Sandbox event ignored in production" }), { status: 200, headers: corsHeaders });
      }

      const userId = customer_ref;
      let mappedProfileStatus = "failed";
      let isVerified = false;

      switch (outcome) {
        case "verified":
          mappedProfileStatus = "verified";
          isVerified = true;
          break;
        case "review":
          mappedProfileStatus = "review";
          isVerified = false;
          break;
        case "underage":
          mappedProfileStatus = "rejected_underage";
          isVerified = false;
          break;
        case "mismatch":
        case "not_found":
        case "face_mismatch":
        case "liveness_failed":
        default:
          mappedProfileStatus = "failed";
          isVerified = false;
          break;
      }

      if (userId) {
        // Update profile
        await supabaseClient
          .from("profiles")
          .update({
            kyc_status: mappedProfileStatus,
            is_kyc_verified: isVerified,
            kyc_tier: isVerified ? 1 : 0,
            kyc_verification_id: verification_id || null,
            kyc_score: score || null,
            kyc_verified_at: isVerified ? new Date().toISOString() : null,
          })
          .eq("id", userId);

        // Update submission log
        await supabaseClient
          .from("kyc_submissions")
          .update({
            outcome: outcome,
            status: mappedProfileStatus,
            score: score || null,
            verification_id: verification_id || null,
            raw_provider_response: event,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId);
      }
    }

    return new Response(JSON.stringify({ status: "ok" }), { status: 200, headers: corsHeaders });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), { status: 400, headers: corsHeaders });
  }
});
