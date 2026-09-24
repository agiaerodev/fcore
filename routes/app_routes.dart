import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/routes/auth_routes.dart';
import '../../modules/auth/routes/auth_route_names.dart';
import '../../modules/auth/providers/auth_provider.dart';
import '../../modules/notifications/routes/notification_route_names.dart';
import '../../modules/notifications/routes/notifications_routes.dart';
import '../../modules/onboarding/routes/onboarding_routes.dart';
import '../../modules/onboarding/routes/onboarding_route_names.dart';
import '../../modules/chat/routes/chat_routes.dart';
import '../../modules/sliders/routes/sliders_routes.dart';
import '../../modules/reminders/routes/reminder_routes.dart';
import 'pending_deep_link.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> defaultRouteObserver = RouteObserver<ModalRoute<void>>();
final String onboardingSystemName = dotenv.env['ONBOARDING_SYSTEM_NAME'] ?? '';
GoRouter appRouter(AuthProvider authProvider) => GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [defaultRouteObserver],
  initialLocation: AuthRouteNames.splash,
  refreshListenable: authProvider,
  redirect: (context, state) => _handleRedirect(state, authProvider),
  onException: _handleRouteException,
  routes: [
    ...authRoutes,
    ...notificationsRoutes,
    ...onboardingRoutes(onboardingSystemName),
    ...chatRoutes,
    ...slidersRoutes,
    ...reminderRoutes,
  ],
);

void _handleRouteException(BuildContext context, GoRouterState state, GoRouter router) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();
    if (currentLocation == NotificationRouteNames.notifications) return;
    router.push(NotificationRouteNames.notifications);
  });
}

String? _handleRedirect(GoRouterState state, AuthProvider authProvider) {
  final bool loggedIn = authProvider.isAuthenticated;
  final bool isInitialLoading = authProvider.isInitialLoading;
  final bool hasSeenWelcome = authProvider.hasSeenWelcome;
  final String location = state.matchedLocation;
  final bool isAtSplash = location == AuthRouteNames.splash;
  final bool isAtOnboarding = location == OnboardingRouteNames.onboarding;
  final bool isAtLogin = location == AuthRouteNames.login;

  if (kDebugMode) {
    print("DEBUG: Loading: $isInitialLoading, Auth: $loggedIn, Location: $location  hasSeenWelcome: $hasSeenWelcome");
  }

  if (isInitialLoading) {
    _capturePendingDeepLink(state);
    return isAtSplash ? null : AuthRouteNames.splash;
  }

  if (!loggedIn) {
    _capturePendingDeepLink(state);
    if (!hasSeenWelcome) {
      return isAtOnboarding ? null : OnboardingRouteNames.onboarding;
    }
    if (!isAtLogin && !isAtOnboarding) {
      return AuthRouteNames.login;
    }

    return null;
  }
  if (loggedIn && (isAtSplash || isAtLogin || isAtOnboarding)) {
    return AuthRouteNames.home;
  }

  return null;
}

// These routes are ignored if it is a saved route pending redirection.
// Scenario: You open the app normally, without a notification and without being logged in; 
// the app sends you to the login screen and records /login.
// You log in and enter the app; you reach the home screen, which reads the 
// saved route (/login) and opens the login screen again, on top of the 
// home screen.
const Set<String> _sessionLocations = {
  AuthRouteNames.splash,
  AuthRouteNames.welcome,
  AuthRouteNames.login,
  AuthRouteNames.otp,
  AuthRouteNames.home,
  OnboardingRouteNames.onboarding,
};

// Recuerda a dónde quería ir el usuario cuando todavía no hay sesión.
void _capturePendingDeepLink(GoRouterState state) {
  if (_sessionLocations.contains(state.matchedLocation)) return;
  PendingDeepLink.save(state.uri.toString());
}
