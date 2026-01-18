import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/local_storage_service.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/calendar/data/repositories/attendance_repository.dart'; // for localStorageServiceProvider
import '../../main.dart'; // To access AttendanceApp

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;
  late LocalStorageService _localStorage;
  late SettingsRepository _settingsRepo;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Local Storage
      _localStorage = LocalStorageService();
      await _localStorage.init();

      // Initialize Settings Repository
      _settingsRepo = await SettingsRepository.init();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Error State
    if (_errorMessage != null) {
      return MaterialApp(
        title: 'Tally Error',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize app',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. Loading State
    if (!_isInitialized) {
      return MaterialApp(
        title: 'Tally Loading',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // 3. Success State - Main App
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(_localStorage),
        settingsRepositoryProvider.overrideWithValue(_settingsRepo),
      ],
      child: const AttendanceApp(),
    );
  }
}
