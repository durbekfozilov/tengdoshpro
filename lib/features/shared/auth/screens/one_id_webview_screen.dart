import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';

class OneIdWebViewScreen extends StatefulWidget {
  const OneIdWebViewScreen({super.key});

  @override
  State<OneIdWebViewScreen> createState() => _OneIdWebViewScreenState();
}

class _OneIdWebViewScreenState extends State<OneIdWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use your central backend URL for OneID initiation
    // Corrected to use the standard v1 API path
    const loginUrl = "https://tengdosh.uzjoku.uz/api/v1/auth/one-id/login";
    const redirectUrl = "https://tengdosh.uzjoku.uz/api/v1/auth/one-id/callback";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            // Intercept the callback redirect to get the authorization code
            if (request.url.startsWith(redirectUrl)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              
              if (code != null) {
                _handleCallback(code);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  void _handleCallback(String code) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // This will trigger OneIdAuthRepository.loginWithToken(code)
    final error = await authProvider.loginWithToken(code);

    if (mounted) {
      if (error == null) {
        // Success: Close WebView and return to Dashboard
        Navigator.pop(context);
      } else {
        // Show error and close
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $error"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OneID Authentication"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
