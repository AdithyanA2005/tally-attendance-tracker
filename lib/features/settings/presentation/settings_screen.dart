import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/repositories/auth_repository.dart';
import '../../../../core/presentation/widgets/section_header.dart';
// import '../../../../core/services/backup_service.dart';
// import '../../../../core/services/sync_service.dart';
import 'package:tally/features/settings/data/repositories/semester_repository.dart';
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
                  // Profile Section (Visual only for now)
                  Consumer(
                    builder: (context, ref, _) {
                      final user = ref
                          .watch(authRepositoryProvider)
                          .currentUser;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                (user?.email?[0] ?? 'U').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    user?.email ?? 'Guest User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SectionHeader(title: 'Academics'),
                  ListTile(
                    leading: const Icon(Icons.school_rounded),
                    title: const Text('Manage Semesters'),
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
                      await ref.read(authRepositoryProvider).signOut();
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
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => const SemesterManagementSheet(),
    );
  }
}
