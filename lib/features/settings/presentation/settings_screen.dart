import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../calendar/data/repositories/attendance_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/presentation/widgets/section_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final semesterStart = settingsRepo.getSemesterStartDate();

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
                  const SectionHeader(title: 'Semester'),
                  ListTile(
                    leading: const Icon(Icons.date_range_rounded),
                    title: const Text('Semester Start Date'),
                    subtitle: Text(
                      DateFormat('MMMM d, yyyy').format(semesterStart),
                    ),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: semesterStart,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        await settingsRepo.setSemesterStartDate(picked);
                        setState(() {});
                      }
                    },
                  ),
                  const Divider(),
                  const SectionHeader(title: 'Academics'),
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
                  const Divider(),
                  const SectionHeader(title: 'Backup & Restore'),
                  ListTile(
                    title: const Text('Share Backup'),
                    subtitle: const Text('Send backup file via other apps.'),
                    leading: const Icon(Icons.share_rounded),
                    onTap: () async {
                      await ref.read(backupServiceProvider).exportData();
                    },
                  ),
                  ListTile(
                    title: const Text('Save to Device'),
                    subtitle: const Text('Download backup to your files.'),
                    leading: const Icon(Icons.save_alt_rounded),
                    onTap: () async {
                      await ref
                          .read(backupServiceProvider)
                          .saveBackupToDevice();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Backup saved to Downloads!'),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Import Data'),
                    subtitle: const Text('Restore from a backup file.'),
                    leading: const Icon(Icons.file_download_rounded),
                    onTap: () async {
                      _importBackup(context, ref);
                    },
                  ),
                  const Divider(),
                  const SectionHeader(title: 'Danger Zone'),
                  ListTile(
                    title: const Text(
                      'Factory Reset App',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Delete all data and start fresh.'),
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    onTap: () async {
                      await _confirmReset(context, ref);
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

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will OVERWRITE all current data with the backup. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restoring backup...')));
      }

      try {
        await ref.read(backupServiceProvider).importData();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Restore successful!')));
          // Navigate to Home/Dashboard to refresh all providers
          context.go('/');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset App?'),
        content: const Text(
          'This will DELETE EVERYTHING: Subjects, Timetable, Logs, and Settings.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performing factory reset...')),
        );
      }

      // Clear all data
      await ref.read(attendanceRepositoryProvider).factoryReset();
      await ref.read(settingsRepositoryProvider).clearAllSettings();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App has been reset to fresh state.')),
        );
        // Navigate to Home to reflect changes and potentially refresh state
        context.go('/');
      }
    }
  }
}
