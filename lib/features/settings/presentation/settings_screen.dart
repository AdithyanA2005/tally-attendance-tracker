import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
                  const Divider(),
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
                        return Text(
                          '${active.name} (${DateFormat('MMM d, yyyy').format(active.startDate)})',
                        );
                      },
                    ),
                    trailing: const Icon(Icons.swap_horiz_rounded),
                    onTap: () => _showSemesterSwitcher(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Timetable'),
                    subtitle: const Text('Edit your weekly schedule'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/timetable'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.class_),
                    title: const Text('Subjects'),
                    subtitle: const Text('Add or edit subjects'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/manage_subjects'),
                  ),
                  // Data Management removed as part of V1 Cleanup
                  // const SectionHeader(title: 'Data Management'),
                  // ... removed tiles ...
                  const Divider(),
                  ListTile(
                    title: const Text('Sign Out'),
                    leading: const Icon(Icons.logout_rounded),
                    onTap: () async {
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                  const Divider(),
                  const SectionHeader(title: 'App'),
                  const ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Notifications'),
                    subtitle: Text('Smart reminders (Coming Soon)'),
                    trailing: Switch(value: false, onChanged: null),
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About'),
                    subtitle: Text('Attendance Intelligence v1.0'),
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
