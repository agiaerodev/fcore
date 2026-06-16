import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:airport_butler_agents_app/modules/auth/routes/auth_routes.dart';
import 'package:airport_butler_agents_app/modules/auth/routes/auth_route_names.dart';
import 'package:airport_butler_agents_app/modules/auth/providers/auth_provider.dart';
import 'package:airport_butler_agents_app/modules/notifications/routes/notifications_routes.dart';
import 'package:airport_butler_agents_app/modules/onboarding/routes/onboarding_routes.dart';
import 'package:airport_butler_agents_app/modules/onboarding/routes/onboarding_route_names.dart';
import 'package:airport_butler_agents_app/modules/chat/routes/chat_routes.dart';
import 'package:airport_butler_agents_app/modules/sliders/routes/sliders_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> defaultRouteObserver = RouteObserver<ModalRoute<void>>();
final sliderIdAgent = 3;
GoRouter appRouter(AuthProvider authProvider) => GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [defaultRouteObserver],
  initialLocation: AuthRouteNames.splash,
  refreshListenable: authProvider,
  redirect: (context, state) => _handleRedirect(state, authProvider),
  routes: [
    ...authRoutes,
    ...notificationsRoutes,
    ...onboardingRoutes(sliderIdAgent),
    ...chatRoutes,
    ...slidersRoutes,
  ],
);

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
    return isAtSplash ? null : AuthRouteNames.splash;
  }

  if (!loggedIn) {
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
