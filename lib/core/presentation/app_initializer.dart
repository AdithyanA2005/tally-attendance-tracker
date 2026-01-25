import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/local_storage_service.dart';
import '../../core/services/supabase_service.dart';
import 'widgets/skeleton_screen.dart';
import '../../core/constants/env.dart';
import '../../main.dart';

import 'package:tally/features/settings/data/repositories/settings_repository.dart';

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
      // Initialize Supabase - Core for V1
      await SupabaseService().initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );

      // Re-enable LocalStorageService for Caching Strategy
      _localStorage = LocalStorageService();
      await _localStorage.init();

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
  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: _ErrorScreen(
          errorMessage: _errorMessage!,
          onRetry: () {
            setState(() {
              _errorMessage = null;
              _isInitialized = false;
            });
            _initializeApp();
          },
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SkeletonScreen(),
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

class _ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
