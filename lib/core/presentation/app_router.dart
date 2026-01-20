import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

import 'widgets/skeleton_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/timetable_screen.dart';
import '../../features/calendar/presentation/subject_detail_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/calendar/presentation/manage_subjects_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

import 'shell_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    redirect: (context, state) {
      // 1. Check Loading State
      if (authState.isLoading) {
        return '/loading';
      }

      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';
      final isLoadingRoute = state.uri.toString() == '/loading';

      // 2. Unauthenticated -> Login
      if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
        return '/login';
      }

      // 3. Authenticated -> Home (if currently on login/signup/loading)
      if (isLoggedIn && (isLoggingIn || isSigningUp || isLoadingRoute)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const SkeletonScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Routes that cover the entire screen (no bottom nav)
      GoRoute(
        path: '/timetable',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/subject/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SubjectDetailScreen(subjectId: id);
        },
      ),
      GoRoute(
        path: '/manage_subjects',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageSubjectsScreen(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
