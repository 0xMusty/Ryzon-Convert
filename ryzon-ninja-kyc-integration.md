# RYZON — Ninja KYC Integration Spec

This document specifies how RYZON (Flutter mobile fintech wallet app) integrates Ninja's Hosted KYC
product to verify user identity (NIN) before unlocking wallet features. Follow this spec exactly
when implementing.

## Overview

- **Provider:** Ninja (ninja.ng) — Nigerian BVN/NIN/CAC verification API
- **Approach:** Hosted KYC (Ninja-hosted verification page opened inside a Flutter WebView).
  RYZON's backend never receives or stores raw NIN/BVN numbers.
- **Flow:** backend creates a verification link → Flutter opens it in a WebView → user completes
  ID + selfie/liveness on Ninja's page → Ninja sends a signed webhook to RYZON's backend with the
  outcome → backend updates user's KYC status → Flutter polls (or is pushed) the result.

> **⚠️ Critical step — do not skip:** Getting a session token from `/auth/session` is NOT enough
> to open the hosted KYC page. You must also call `POST /api/flows/:flow_id/links` to create an
> actual verification link. Building a hosted URL by hand (e.g. appending the session token as a
> query param to a guessed URL) will fail with "invalid request" on Ninja's page — this is not a
> valid session. Always use the exact `url` field returned by the links endpoint. See sections 3
> and 5 for the correct implementation.

## Base URLs

```
Live:    https://api.ninja.boucloud.io
Sandbox: https://api.sandbox.ninja.boucloud.io
```

Build and test everything against sandbox first. Sandbox test NIN `77777777777` returns a match
for James Bond, DOB 1975-01-01. `55555555555` is not_found. `00000000000` simulates a 500.

## 1. Authentication

Backend exchanges Client Key + Client Secret for a session token before every batch of API calls.
Token expires in 5 minutes — fetch fresh, do not cache long-term.

```
POST /auth/session
Body: { "client_key": "...", "client_secret": "..." }
Response: { "token": "...", "expiry": "..." }
```

Client Secret must never leave the backend or be shipped in the Flutter app.

## 2. Flow Configuration (create once)

Create this flow once via the dashboard or API. Reuse its `flow_id` for every user.

```json
POST /api/flows
{
  "name": "RYZON Wallet KYC",
  "id_types": ["nin"],
  "rules": {
    "allow_transposed_names": true,
    "accept_score": 0.90,
    "review_score": 0.60,
    "min_age": 18,
    "fields": [
      { "field": "first_name",    "match": "name", "required": true, "source": "business" },
      { "field": "last_name",     "match": "name", "required": true, "source": "business" },
      { "field": "date_of_birth", "match": "date", "required": true, "source": "customer" }
    ]
  },
  "selfie_required": true,
  "liveness_required": true,
  "branding": { "display_name": "RYZON", "primary_color": "REPLACE_WITH_BRAND_COLOR" },
  "redirect_url": "https://ryzon.app/kyc-return",
  "webhook_url":  "https://api.ryzon.app/webhooks/ninja"
}
```

Notes:
- `first_name` / `last_name` are supplied by RYZON (`source: business`) since they're already
  collected at signup. Only `date_of_birth` is entered by the user on Ninja's page.
- `min_age: 18` rejects underage users outright, before scoring — kept as a distinct `underage`
  outcome, separate from a mismatch.
- `selfie_required` + `liveness_required` are on: NIN lookup alone only confirms a record exists
  with that name, it does not prove the person holding the phone is that person. Liveness is
  required for a wallet app moving money.
- No AML screening (`global_aml` / `local_aml` intentionally omitted).
- `webhook_url` generates a signing secret in the dashboard — store it as `NINJA_WEBHOOK_SECRET`.

## 3. Generate a Verification Link (per user)

Called from RYZON's backend when a user starts KYC.

```
POST /api/flows/:flow_id/links
Headers: Authorization: Bearer <session_token>
Body:
{
  "customer_ref": "<ryzon_user_id>",
  "values": { "first_name": "<from signup>", "last_name": "<from signup>" }
}

Response:
{ "id": "vs_...", "url": "https://ninja.boucloud.io/kyc/?t=...", "expires_at": "...", "status": "pending" }
```

- `url` is shown once — pass it straight to the Flutter app, do not try to reconstruct it later.
- `customer_ref` must be RYZON's internal user id — it comes back on the webhook for reconciliation.
- Default link lifetime is 72 hours.
- **Never hand-build this URL from the session token.** The session token from `/auth/session`
  alone does not create a valid hosted KYC page — only the `url` returned by this endpoint works.
  Skipping this call and guessing a URL is what produces "invalid request" on Ninja's page.

### RYZON's actual implementation — Supabase Edge Function

RYZON runs this as a Supabase Edge Function (`ninja-kyc-webhook`, despite the name it's the
**session-start** function, called when the user taps "Verify"):

```typescript
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

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

    const clientKey = Deno.env.get("NINJA_CLIENT_KEY") ?? "";
    const clientSecret = Deno.env.get("NINJA_CLIENT_SECRET") ?? "";
    const flowId = Deno.env.get("NINJA_FLOW_ID") ?? ""; // set after creating the flow (section 2)

    // 1. Get session token
    const sessionRes = await fetch("https://api.sandbox.ninja.boucloud.io/auth/session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ client_key: clientKey, client_secret: clientSecret }),
    });
    const { token } = await sessionRes.json();
    if (!token) throw new Error("Failed to get Ninja session token");

    // 2. Create the actual verification link — this step was previously missing
    const linkRes = await fetch(`https://api.sandbox.ninja.boucloud.io/api/flows/${flowId}/links`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ customer_ref: user.id }),
    });
    const linkData = await linkRes.json();
    if (!linkData.url) throw new Error(`Ninja link creation failed: ${JSON.stringify(linkData)}`);

    const maskedId = id_number && id_number.length === 11
      ? `${id_number.substring(0, 4)}****${id_number.substring(7)}`
      : null;

    // Audit record
    await supabaseClient.from("kyc_submissions").insert({
      user_id: user.id,
      id_type,
      id_number_masked: maskedId,
      provider: "NINJA_HOSTED",
      session_id: linkData.id,
      status: "verifying",
    });

    await supabaseClient.from("profiles").update({ kyc_status: "verifying" }).eq("id", user.id);

    return new Response(
      JSON.stringify({
        success: true,
        url: linkData.url,
        id: linkData.id,
        id_type,
        environment: "sandbox",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    // Do NOT fall back to a fake token/url on failure — surface the real error to the app
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
```

Key fixes vs. an earlier version of this function:
- Actually calls `/api/flows/:flow_id/links` — previously it only fetched a session token and
  returned a hand-built URL, which is why Ninja rejected it as "invalid request."
- Requires `NINJA_FLOW_ID` as an env var — this is the `id` returned when you created the flow
  in section 2. Must be set before this function will work.
- No silent fallback to a fake sandbox token on failure — errors are returned as real `400`
  responses so the Flutter app can show a real message instead of opening a broken URL.

### Flutter data source calling this function

```dart
class KycRemoteDataSourceLive implements KycRemoteDataSource {
  final Dio dio;
  KycRemoteDataSourceLive({Dio? dio}) : dio = dio ?? Dio();

  @override
  Future<Map<String, String>> createNinjaHostedSession({
    required String idType,
    required String idNumber,
  }) async {
    final supabaseUrl = dotenv.env['SUPABASE_FUNCTION_URL'] ??
        'https://esghqmyyofjylgzveggj.supabase.co/functions/v1/ninja-kyc-webhook';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    final response = await dio.post(
      supabaseUrl,
      data: {'id_type': idType, 'id_number': idNumber},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final url = response.data?['url'] as String?;
    final id = response.data?['id'] as String?;

    if (url == null || url.isEmpty) {
      throw ValidationException('Could not start identity verification. Please try again.');
    }

    return {
      'url': url,
      'hosted_url': url,
      'id': id ?? '',
      'id_type': idType,
      'environment': 'sandbox',
    };
  }
}
```

No silent `catch (_) {}` fallback here either — a failed call throws a real exception the UI
can show, instead of quietly opening a broken hosted URL.

## 4. Flutter: Open the Hosted Link

### Setup required

**1. Add the dependency** — `pubspec.yaml`:

```yaml
dependencies:
  webview_flutter: ^4.7.0
```

Run `flutter pub get` after adding.

**2. Android setup** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Also confirm `minSdkVersion` in `android/app/build.gradle` is at least `19` (webview_flutter
requires this):

```gradle
android {
    defaultConfig {
        minSdkVersion 19
    }
}
```

If the flow ever needs camera access in-webview (selfie/liveness step runs on Ninja's hosted
page, but some Android WebViews block camera permission requests from web content by default),
add:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

And make sure `setMediaPlaybackRequiresUserGesture` / permission callback is handled if you see
the liveness step fail to access the camera on Android — this is a common snag with hosted
KYC pages that request camera access inside a WebView.

**3. iOS setup** (`ios/Runner/Info.plist`):

```xml
<key>NSCameraUsageDescription</key>
<string>RYZON needs camera access to complete identity verification</string>
```

Required because the liveness/selfie step requests camera access inside the WebView — iOS will
silently block it and the step will hang without this key.

**4. Minimum Flutter/Dart version** — `webview_flutter: ^4.x` requires Flutter 3.x+. Confirm
your `pubspec.yaml` `environment: sdk:` constraint is compatible before adding it.

Once these are in place, the WebView screen below will work. Treat the redirect as UX only — never trust it for real status.

```dart
import 'package:webview_flutter/webview_flutter.dart';

class KycWebViewScreen extends StatefulWidget {
  final String kycUrl;
  const KycWebViewScreen({required this.kycUrl});

  @override
  State<KycWebViewScreen> createState() => _KycWebViewScreenState();
}

class _KycWebViewScreenState extends State<KycWebViewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith("https://ryzon.app/kyc-return")) {
              final uri = Uri.parse(request.url);
              final status = uri.queryParameters['status']; // UX only, not source of truth
              Navigator.pop(context, status);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.kycUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify your identity")),
      body: WebViewWidget(controller: controller),
    );
  }
}
```

Trigger flow from the app:

```dart
final kycUrl = await api.startKyc(userId); // calls RYZON backend POST /kyc/start
await Navigator.push(context, MaterialPageRoute(
  builder: (_) => KycWebViewScreen(kycUrl: kycUrl),
));
// After WebView closes, poll /kyc/status/:userId until it resolves
```

## 5. Backend: Webhook Handler (source of truth)

The webhook — not the app redirect — is authoritative. Must verify signature on the **raw**
request body before parsing.

```javascript
const crypto = require("crypto");
const FLOW_WEBHOOK_SECRET = process.env.NINJA_WEBHOOK_SECRET;

app.post("/webhooks/ninja", express.raw({ type: "application/json" }), async (req, res) => {
  const rawBody = req.body;

  const signature = req.headers["x-ninja-signature"];
  const expected = "hmac-sha256=" +
    crypto.createHmac("sha256", FLOW_WEBHOOK_SECRET).update(rawBody).digest("hex");

  if (signature !== expected) {
    return res.status(401).send("invalid signature");
  }

  const event = JSON.parse(rawBody);

  // Dedupe: Ninja retries on non-2xx/timeout (1m, 5m, 30m, 2h, 6h)
  const alreadyProcessed = await db.webhookEvents.findOne({ eventId: event.event_id });
  if (alreadyProcessed) return res.status(200).send("already processed");
  await db.webhookEvents.insert({ eventId: event.event_id, receivedAt: new Date() });

  if (event.event === "verification.completed") {
    const { customer_ref, outcome, score, verification_id, sandbox } = event.data;

    if (sandbox && process.env.NODE_ENV === "production") {
      return res.status(200).send("sandbox event ignored");
    }

    const userId = customer_ref;

    switch (outcome) {
      case "verified":
        await db.users.update(userId, {
          kycStatus: "verified",
          kycVerificationId: verification_id,
          kycScore: score,
          kycVerifiedAt: new Date(),
        });
        // unlock wallet features / send push notification
        break;

      case "review":
        await db.users.update(userId, { kycStatus: "review", kycVerificationId: verification_id });
        // route to manual review queue — do NOT unlock wallet yet
        break;

      case "mismatch":
      case "not_found":
        await db.users.update(userId, { kycStatus: "failed" });
        break;

      case "underage":
        await db.users.update(userId, { kycStatus: "rejected_underage" });
        break;

      case "face_mismatch":
      case "liveness_failed":
        await db.users.update(userId, { kycStatus: "failed" });
        break;

      default:
        console.warn("Unhandled outcome:", outcome);
    }
  }

  res.status(200).send("ok"); // must respond 2xx quickly or Ninja retries
});
```

Important implementation details:
- This route must receive the **raw** body — exclude it from any global `express.json()` middleware.
- `review` is not a rejection. It means a human should look at it. Do not auto-fail these users.
- The webhook never contains the raw ID number or typed values — only outcome, scores, and ids.

## 6. Backend: Status Endpoint (for Flutter polling)

```javascript
app.get("/kyc/status/:userId", async (req, res) => {
  const user = await db.users.findById(req.params.userId);
  res.json({ status: user.kycStatus });
});
```

Flutter polls this every few seconds after the WebView closes until status resolves to
`verified`, `review`, or `failed`. Move to a push-notification model (FCM) once available,
triggered from the webhook handler instead of polling.

## Outcomes Reference

| Outcome | Meaning | Action |
|---|---|---|
| `verified` | Score ≥ accept_score (0.90) | Unlock wallet |
| `review` | Score between review_score and accept_score, or selfie/registry issue | Manual review queue |
| `mismatch` | Score below review_score | Let user retry with fresh link |
| `not_found` | No registry record for the NIN | Let user retry / check number |
| `underage` | Registry DOB puts user under 18 | Reject, do not allow retry |
| `face_mismatch` | Selfie didn't match ID photo | Let user retry |
| `liveness_failed` | Liveness check failed (spoof/photo/replay suspected) | Let user retry |

## Explicitly Out of Scope (for now)

- **AML screening (`global_aml` / `local_aml`)** — intentionally not enabled on this flow.
- Direct REST integration with custom in-app forms — not used; hosted KYC handles this instead.
- KYB (business verification) — not needed for individual wallet users.

## Compliance Note (non-technical, flag to a human)

RYZON converts crypto to naira, which falls under CBN/SEC-relevant activity in Nigeria. Confirm
with a lawyer/compliance advisor whether this KYC tier (NIN + selfie + liveness, no AML) satisfies
requirements for your planned transaction limits, and whether additional licensing applies to the
conversion service itself. This is not something to infer from the Ninja docs alone.
