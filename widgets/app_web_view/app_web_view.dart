import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'redirect_bridge_script.dart';
import 'redirect_matcher.dart';

/// Embedded web view with a loading progress bar.
///
/// When [redirectUrls] is not empty, any attempt to navigate to one of them
/// is blocked and reported once through [onRedirect]. This lets external
/// web flows (payments, account recovery, ...) hand control back to the app.
class AppWebView extends StatefulWidget {
  const AppWebView({
    super.key,
    required this.url,
    this.redirectUrls = const [],
    this.onRedirect,
    this.clearSessionData = true,
  });

  final String url;
  final List<String> redirectUrls;
  final VoidCallback? onRedirect;

  /// Clears cache and local storage before loading, so each session starts
  /// clean.
  final bool clearSessionData;

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  static const String _redirectChannel = 'AppRedirectBridge';

  late final WebViewController _controller;
  late final RedirectMatcher _redirectMatcher;

  /// Page load progress between 0 and 1, or `null` when not loading.
  double? _progress = 0;
  bool _hasHandledRedirect = false;

  @override
  void initState() {
    super.initState();
    _redirectMatcher = RedirectMatcher(widget.redirectUrls);
    _controller = _buildController();
  }

  WebViewController _buildController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _setProgress(0),
          onProgress: (progress) => _setProgress(progress / 100),
          onPageFinished: (_) => _onPageFinished(),
          onNavigationRequest: _onNavigationRequest,
          onUrlChange: (change) => _handleUrl(change.url),
          onWebResourceError: _onWebResourceError,
        ),
      );

    if (!_redirectMatcher.isEmpty) {
      controller.addJavaScriptChannel(
        _redirectChannel,
        onMessageReceived: (_) => _notifyRedirect(),
      );
    }

    if (widget.clearSessionData) {
      controller
        ..clearCache()
        ..clearLocalStorage();
    }

    return controller..loadRequest(Uri.parse(widget.url));
  }

  void _setProgress(double? progress) {
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  void _onPageFinished() {
    _setProgress(null);

    if (!_redirectMatcher.isEmpty) {
      _controller.runJavaScript(
        buildRedirectBridgeScript(
          redirectUrls: widget.redirectUrls,
          channelName: _redirectChannel,
        ),
      );
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (_handleUrl(request.url)) return NavigationDecision.prevent;
    return NavigationDecision.navigate;
  }

  /// Platforms without a handler for the redirect's custom scheme report it
  /// as an "unknown scheme" error instead of a navigation request.
  void _onWebResourceError(WebResourceError error) {
    debugPrint('WebView error: ${error.description}');

    final url = error.url;
    if (url != null &&
        _isUnknownSchemeError(error) &&
        _redirectMatcher.hasRedirectScheme(url)) {
      _notifyRedirect();
    }
  }

  bool _isUnknownSchemeError(WebResourceError error) {
    final description = error.description.toLowerCase();
    return description.contains('err_unknown_url_scheme') ||
        description.contains('unknown url scheme') ||
        description.contains('unsupported scheme');
  }

  /// Returns `true` when [url] is a redirect URL and was handled.
  bool _handleUrl(String? url) {
    if (url == null || !_redirectMatcher.matches(url)) return false;

    _notifyRedirect();
    return true;
  }

  void _notifyRedirect() {
    if (_hasHandledRedirect || !mounted) return;

    _hasHandledRedirect = true;
    widget.onRedirect?.call();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (progress != null) LinearProgressIndicator(value: progress),
      ],
    );
  }
}
