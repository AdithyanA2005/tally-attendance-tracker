import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/repositories/auth_repository.dart';
import '../../../../core/presentation/widgets/section_header.dart';
// import '../../../../core/services/backup_service.dart';
// import '../../../../core/services/sync_service.dart';
import 'package:tally/features/settings/data/repositories/semester_repository.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:tally/core/data/repositories/profile_repository.dart';
import '../../../../core/data/models/user_profile_model.dart';
import 'account_screen.dart';
import 'widgets/semester_management_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                title: Text(
                  'Settings',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: false,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // Profile Section
                  Consumer(
                    builder: (context, ref, _) {
                      final user = ref
                          .watch(authRepositoryProvider)
                          .currentUser;
                      // Watch profile for name/photo updates
                      final profileStream = ref.watch(
                        profileRepositoryProvider.select(
                          (repo) => repo.watchProfile(),
                        ),
                      );

                      return StreamBuilder<UserProfile?>(
                        stream: profileStream,
                        initialData: ref
                            .read(profileRepositoryProvider)
                            .getProfileSync(),
                        builder: (context, snapshot) {
                          final profile = snapshot.data;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: ClipOval(
                                      child: Container(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        child: profile?.photoUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: profile!.photoUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Center(
                                                  child: Text(
                                                    ((profile?.name?.isNotEmpty ==
                                                                    true
                                                                ? profile!
                                                                      .name![0]
                                                                : null) ??
                                                            (user?.email?.isNotEmpty ==
                                                                    true
                                                                ? user!
                                                                      .email![0]
                                                                : 'U'))
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Center(
                                                  child: Text(
                                                    ((profile?.name?.isNotEmpty ==
                                                                    true
                                                                ? profile!
                                                                      .name![0]
                                                                : null) ??
                                                            (user?.email?.isNotEmpty ==
                                                                    true
                                                                ? user!
                                                                      .email![0]
                                                                : 'U'))
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  ((profile?.name?.isNotEmpty ==
                                                                  true
                                                              ? profile!
                                                                    .name![0]
                                                              : null) ??
                                                          (user?.email?.isNotEmpty ==
                                                                  true
                                                              ? user!.email![0]
                                                              : 'U'))
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Account',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                              ),
                                        ),
                                        Text(
                                          profile?.name ??
                                              user?.email ??
                                              'Guest User',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (profile?.name != null)
                                          Text(
                                            user?.email ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SectionHeader(title: 'Academics'),
                  ListTile(
                    leading: const Icon(Icons.school_rounded),
                    title: const Text('Current Semester'),
                    subtitle: Consumer(
                      builder: (context, ref, _) {
                        final activeAsync = ref.watch(activeSemesterProvider);
                        final active = activeAsync.value;
                        if (active == null) {
                          return const Text('No active semester');
                        }
                        return Text('Current: ${active.name}');
                      },
                    ),
                    trailing: const Icon(Icons.swap_horiz_rounded),
                    onTap: () => _showSemesterSwitcher(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.class_rounded),
                    title: const Text('Subjects'),
                    subtitle: const Text('Manage subjects & criteria'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/manage_subjects'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: const Text('Timetable'),
                    subtitle: const Text('Edit weekly schedule'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/timetable'),
                  ),

                  const SizedBox(height: 16),
                  const SectionHeader(title: 'General'),
                  Consumer(
                    builder: (context, ref, _) {
                      final themeMode = ref.watch(themeProvider);
                      return ListTile(
                        leading: const Icon(Icons.dark_mode_rounded),
                        title: const Text('Appearance'),
                        subtitle: Text(
                          themeMode == ThemeMode.system
                              ? 'System'
                              : themeMode == ThemeMode.light
                              ? 'Light'
                              : 'Dark',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showAppearanceSelector(context, ref),
                      );
                    },
                  ),
                  const ListTile(
                    leading: Icon(Icons.notifications_rounded),
                    title: Text('Notifications'),
                    subtitle: Text('Smart reminders (Coming Soon)'),
                    trailing: Switch(value: false, onChanged: null),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About'),
                    subtitle: const Text('Attendance Intelligence v1.0'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Tally',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Copyright © 2026',
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Account'),
                  ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () async {
                      await _showSignOutDialog(context, ref);
                    },
                  ),
                ]),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSemesterSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => const SemesterManagementSheet(),
    );
  }

  void _showAppearanceSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildThemeOptionSheetItem(
                context,
                ref,
                'System Default',
                'Matches your device settings',
                ThemeMode.system,
                Icons.brightness_auto_rounded,
              ),
              const SizedBox(height: 12),
              _buildThemeOptionSheetItem(
                context,
                ref,
                'Light Mode',
                'Clean and bright interface',
                ThemeMode.light,
                Icons.light_mode_rounded,
              ),
              const SizedBox(height: 12),
              _buildThemeOptionSheetItem(
                context,
                ref,
                'Dark Mode',
                'Easier on the eyes',
                ThemeMode.dark,
                Icons.dark_mode_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(fontSize: 16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  Widget _buildThemeOptionSheetItem(
    BuildContext context,
    WidgetRef ref,
    String label,
    String description,
    ThemeMode mode,
    IconData icon,
  ) {
    final currentMode = ref.watch(themeProvider);
    final isSelected = currentMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
