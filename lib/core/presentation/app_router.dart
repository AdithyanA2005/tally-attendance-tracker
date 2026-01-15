import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/timetable_screen.dart';
import '../../features/calendar/presentation/subject_detail_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/calendar/presentation/manage_subjects_screen.dart';

import 'shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
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
      builder: (context, state) => const TimetableScreen(),
    ),
    GoRoute(
      path: '/subject/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubjectDetailScreen(subjectId: id);
      },
    ),
    GoRoute(
      path: '/manage_subjects',
      builder: (context, state) => const ManageSubjectsScreen(),
    ),
  ],
);
