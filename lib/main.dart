import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/presentation/app_router.dart';
import 'core/data/local_storage_service.dart';
import 'features/calendar/data/repositories/attendance_repository.dart';
import 'features/settings/data/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage separate from Provider if needed,
  // or use a ProviderContainer to init before running app.
  // For simplicity here, we'll let the provider init lazily or init synchronously if possible.
  // Converting init to standard main init for Hive.
  final localStorage = LocalStorageService();
  await localStorage.init();

  // Initialize Settings Repository
  final settingsRepo = await SettingsRepository.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: const AttendanceApp(),
    ),
  );
}

class AttendanceApp extends ConsumerWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Tally',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Forces light theme as requested
      routerConfig: appRouter,
    );
  }
}
