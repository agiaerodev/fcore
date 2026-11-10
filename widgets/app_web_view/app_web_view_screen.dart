import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigation_app_bar.dart';
import 'app_web_view.dart';

/// Full-screen [AppWebView] with the app's navigation bar.
///
/// When a redirect URL is reached the screen closes and returns `true`.
class AppWebViewScreen extends StatelessWidget {
  const AppWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.redirectUrls = const [],
  });

  final String url;
  final String title;
  final List<String> redirectUrls;

  /// Opens the screen and completes with `true` if the web flow reached one
  /// of [redirectUrls], or `null` if the user closed it manually.
  static Future<bool?> navigateTo(
    BuildContext context, {
    required String url,
    required String title,
    List<String> redirectUrls = const [],
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppWebViewScreen(
          url: url,
          title: title,
          redirectUrls: redirectUrls,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep the WKWebView viewport stable while iOS reveals the keyboard.
      resizeToAvoidBottomInset: defaultTargetPlatform != TargetPlatform.iOS,
      appBar: NavigationAppBar(title: title),
      body: SafeArea(
        maintainBottomViewPadding: defaultTargetPlatform == TargetPlatform.iOS,
        child: AppWebView(
          url: url,
          redirectUrls: redirectUrls,
          onRedirect: () {
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            if (rootNavigator.canPop()) {
              rootNavigator.pop(true);
              return;
            }
            Navigator.of(context).maybePop(true);
          },
        ),
      ),
    );
  }
}
