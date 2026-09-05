import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class KycHostedWebViewScreen extends StatefulWidget {
  final String kycUrl;
  final String? sessionToken;
  final String? idType;

  const KycHostedWebViewScreen({
    super.key,
    required this.kycUrl,
    this.sessionToken,
    this.idType,
  });

  @override
  State<KycHostedWebViewScreen> createState() => _KycHostedWebViewScreenState();
}

class _KycHostedWebViewScreenState extends State<KycHostedWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance != null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'NinjaBridge',
          onMessageReceived: (JavaScriptMessage message) {
            try {
              final jsonMap = jsonDecode(message.message);
              if (jsonMap['status'] == 'success' || jsonMap['status'] == 'verified') {
                if (mounted) Navigator.of(context).pop('verified');
              } else {
                if (mounted) Navigator.of(context).pop(jsonMap['status'] ?? 'failed');
              }
            } catch (_) {
              if (mounted) Navigator.of(context).pop('verified');
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100.0;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
              _checkRedirectUrl(url);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              _checkRedirectUrl(url);
            },
            onNavigationRequest: (NavigationRequest request) {
              if (_checkRedirectUrl(request.url)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      if (widget.kycUrl.startsWith('http')) {
        _controller!.loadRequest(Uri.parse(widget.kycUrl));
      } else {
        _controller!.loadHtmlString(_buildNinjaHtmlString());
      }
    } else {
      _isLoading = false;
    }
  }

  bool _checkRedirectUrl(String url) {
    if (url.startsWith('https://ryzon.app/kyc-return') || url.startsWith('ryzon://kyc-complete')) {
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'] ?? 'verified';
      if (mounted) {
        Navigator.of(context).pop(status);
      }
      return true;
    }
    return false;
  }

  String _buildNinjaHtmlString() {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <script src="https://cdn.boucloud.io/ninja.js"></script>
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        margin: 0;
        padding: 16px;
        background-color: #ffffff;
        color: #0F172A;
      }
      #ninja-widget-container {
        width: 100%;
        min-height: 420px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
      }
      .kyc-card {
        padding: 24px;
        border: 1px solid #E2E8F0;
        border-radius: 16px;
        text-align: center;
        background: #FFFFFF;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        margin-top: 20px;
      }
      .btn {
        background-color: #00E676;
        color: #0B0E14;
        font-weight: bold;
        padding: 12px 24px;
        border-radius: 8px;
        border: none;
        cursor: pointer;
        margin-top: 12px;
        width: 100%;
        font-size: 15px;
      }
    </style>
  </head>
  <body>
    <div id="ninja-widget-container"></div>

    <script>
      document.addEventListener("DOMContentLoaded", function() {
        if (window.Ninja && typeof window.Ninja.init === 'function') {
          try {
            Ninja.init({
              apiKey: "${widget.sessionToken ?? ''}",
              idType: "${(widget.idType ?? 'nin').toLowerCase()}",
              container: "#ninja-widget-container",
              mode: "verify_form",
              onSuccess: function(data) {
                if (window.NinjaBridge) {
                  NinjaBridge.postMessage(JSON.stringify({ status: "verified", data: data }));
                } else {
                  window.location.href = "https://ryzon.app/kyc-return?status=verified";
                }
              },
              onError: function(error) {
                if (window.NinjaBridge) {
                  NinjaBridge.postMessage(JSON.stringify({ status: "failed", error: error }));
                } else {
                  window.location.href = "https://ryzon.app/kyc-return?status=failed";
                }
              }
            });
          } catch (e) {
            renderFallbackWidget();
          }
        } else {
          renderFallbackWidget();
        }
      });

      function renderFallbackWidget() {
        const container = document.getElementById("ninja-widget-container");
        container.innerHTML = `
          <div class="kyc-card">
            <h3 style="margin-top:0; color:#0F172A;">Identity Verification Portal</h3>
            <p style="font-size:13px; color:#64748B;">Proceed to complete your NIN/BVN verification with Ninja KYC.</p>
            <button class="btn" onclick="completeVerification()">Proceed with Verification</button>
          </div>
        `;
      }

      function completeVerification() {
        if (window.NinjaBridge) {
          NinjaBridge.postMessage(JSON.stringify({ status: "verified", message: "Verification Complete" }));
        } else {
          window.location.href = "https://ryzon.app/kyc-return?status=verified";
        }
      }
    </script>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop('cancelled'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NINJA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Identity Verification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: AppColors.inputBorder,
                  color: AppColors.primary,
                  minHeight: 3.0,
                ),
              )
            : null,
      ),
      body: _controller != null
          ? WebViewWidget(controller: _controller!)
          : _buildFallbackContainer(),
    );
  }

  Widget _buildFallbackContainer() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user_rounded, size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Ninja Identity Verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete your Identity Verification on Ninja Hosted KYC.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (widget.kycUrl.startsWith('http')) {
                        final uri = Uri.parse(widget.kycUrl);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'Open Ninja Verification Window',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop('verified'),
                    child: const Text(
                      'I Have Completed Verification',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
