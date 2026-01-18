import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/animations/fade_in_slide.dart';

import '../../../../core/presentation/widgets/timeline_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/string_utils.dart';
import 'package:tally/core/data/models/session_model.dart';

import 'widgets/future_impact_section.dart';

import '../../calendar/data/repositories/attendance_repository.dart';

import '../../calendar/presentation/widgets/edit_session_sheet.dart';
import '../../settings/presentation/providers/today_classes_provider.dart';

/// The dashboard of the application showing today's schedule.
///
/// Displays an overview of classes for the current day, allowing quick
/// attendance marking and navigation to session details.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayClassesAsyncValue = ref.watch(todayClassesProvider);
    final now = DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate the provider to trigger a refresh
          ref.invalidate(todayClassesProvider);
          // Wait a bit for the refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                  title: Text(
                    DateFormat('EEEE, d MMMM').format(now),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  centerTitle: false,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: todayClassesAsyncValue.maybeWhen(
                      data: (items) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items.isEmpty
                                ? 'No classes today'
                                : '${items.length} classes scheduled',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _BulkActionChip(
                                    icon: Icons.check_rounded,
                                    label: 'All Present',
                                    color: const Color(0xFF27AE60),
                                    onTap: () => _markAllClasses(
                                      ref,
                                      items,
                                      AttendanceStatus.present,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _BulkActionChip(
                                    icon: Icons.close_rounded,
                                    label: 'All Absent',
                                    color: const Color(0xFFC0392B),
                                    onTap: () => _markAllClasses(
                                      ref,
                                      items,
                                      AttendanceStatus.absent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _BulkActionChip(
                                    icon: Icons.block_rounded,
                                    label: 'All Cancelled',
                                    color: const Color(0xFF607D8B),
                                    onTap: () => _markAllClasses(
                                      ref,
                                      items,
                                      AttendanceStatus.cancelled,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _BulkActionChip(
                                    icon: Icons.restore_rounded,
                                    label: 'Reset to Scheduled',
                                    color: const Color(0xFF95A5A6),
                                    onTap: () => _markAllClasses(
                                      ref,
                                      items,
                                      AttendanceStatus.scheduled,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeInSlide(
                        duration: const Duration(milliseconds: 600),
                        child: todayClassesAsyncValue.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return _buildEmptyState(context);
                            }
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final isLast = index == items.length - 1;
                                return TimelineItem(
                                  isLast: isLast,
                                  child: _TodayClassCard(item: item),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => Text('Error: $e'),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const FadeInSlide(
                        duration: Duration(milliseconds: 800),
                        child: FutureImpactSection(),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markAllClasses(
    WidgetRef ref,
    List<TodayClassItem> items,
    AttendanceStatus status,
  ) async {
    HapticFeedback.mediumImpact();
    final repo = ref.read(attendanceRepositoryProvider);

    // Mark all classes with the given status
    for (final item in items) {
      final session = ClassSession(
        id: item.existingSession?.id.isNotEmpty == true
            ? item.existingSession!.id
            : const Uuid().v4(),
        subjectId: item.subject.id,
        date: item.scheduledTime,
        status: status,
        isExtraClass: item.existingSession?.isExtraClass ?? false,
        durationMinutes: (item.entry.durationInHours * 60).toInt(),
      );
      await repo.logSession(session);
    }

    // Show confirmation snackbar
    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text(
            'Marked all ${items.length} classes as ${status == AttendanceStatus.present
                ? 'Present'
                : status == AttendanceStatus.absent
                ? 'Absent'
                : status == AttendanceStatus.scheduled
                ? 'Scheduled'
                : 'Cancelled'}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final dayName = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    isWeekend
                        ? Icons.weekend_rounded
                        : Icons.free_breakfast_rounded,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              isWeekend ? 'Enjoy Your Weekend!' : 'No Classes Today!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              isWeekend
                  ? 'Relax and recharge for the week ahead'
                  : 'It\'s $dayName - Enjoy your free time',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Quick Actions
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            _EmptyStateActionButton(
              icon: Icons.calendar_month_rounded,
              label: 'View Timetable',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/timetable');
              },
            ),
            const SizedBox(height: 12),
            _EmptyStateActionButton(
              icon: Icons.insights_rounded,
              label: 'Check Insights',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/insights');
              },
            ),
            const SizedBox(height: 12),
            _EmptyStateActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Extra Class',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/calendar');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayClassCard extends ConsumerWidget {
  final TodayClassItem item;
  const _TodayClassCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMarked = item.currentStatus != AttendanceStatus.scheduled;
    final theme = Theme.of(context);

    final nowTime = DateTime.now();
    final startTime = item.scheduledTime;
    final endTime = startTime.add(
      Duration(minutes: (item.entry.durationInHours * 60).toInt()),
    );

    final isNow = nowTime.isAfter(startTime) && nowTime.isBefore(endTime);

    if (isMarked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(item.currentStatus),
              size: 20,
              color: _getStatusColor(item.currentStatus).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.subject.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _showEditDialog(context, ref);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isNow
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                width: 1,
              )
            : Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          if (isNow)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: ValueKey('${item.subject.id}_${item.entry.startTime}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Swipe Right -> Present
              _mark(context, ref, AttendanceStatus.present);
              HapticFeedback.mediumImpact();
            } else {
              // Swipe Left -> Absent
              _mark(context, ref, AttendanceStatus.absent);
              HapticFeedback.mediumImpact();
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            color: const Color(0xFF27AE60), // Green for Present
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: const Color(0xFFC0392B), // Red for Absent
            child: const Icon(
              Icons.cancel_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _showEditDialog(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Minimal Color Strip Indicator
                          Container(
                            width: 4,
                            height: 48,
                            decoration: BoxDecoration(
                              color: item.subject.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.entry.startTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNow
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                formatDuration(item.entry.durationInHours),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.subject.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isNow) ...[
                                      const SizedBox(width: 8),
                                      const _PulseIndicator(),
                                    ],
                                  ],
                                ),
                                if (item.subject.id != item.originalSubject.id)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Substituted for ${item.originalSubject.name}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniActionButton(
                            label: 'Present',
                            icon: Icons.check_rounded,
                            color: const Color(0xFF27AE60),
                            onTap: () =>
                                _mark(context, ref, AttendanceStatus.present),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniActionButton(
                            label: 'Absent',
                            icon: Icons.close_rounded,
                            color: const Color(0xFFC0392B),
                            onTap: () =>
                                _mark(context, ref, AttendanceStatus.absent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.cancelled:
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    return AppTheme.statusColors[status] ?? Colors.black;
  }

  void _mark(
    BuildContext context,
    WidgetRef ref,
    AttendanceStatus status,
  ) async {
    HapticFeedback.lightImpact();

    // Save the previous state to restore if undone
    final previousStatus = item.existingSession?.status;
    final isNew = item.existingSession == null;

    final session = ClassSession(
      id: item.existingSession?.id.isNotEmpty == true
          ? item.existingSession!.id
          : const Uuid().v4(),
      subjectId: item.subject.id,
      date: item.scheduledTime,
      status: status,
      isExtraClass: item.existingSession?.isExtraClass ?? false,
      durationMinutes: (item.entry.durationInHours * 60).toInt(),
    );

    final repo = ref.read(attendanceRepositoryProvider);
    await repo.logSession(session);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Marked as ${status.name.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            if (isNew) {
              // If it was new, we should delete it to "unmark" it.
              // Assuming repo has deleteSession. If not, we set to cancelled.
              // For now, we'll try to delete if the ID exists.
              await repo.deleteSession(session.id);
            } else if (previousStatus != null) {
              // Restore previous status
              await repo.logSession(session.copyWith(status: previousStatus));
            }
          },
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    // Re-use existing dialog logic
    final repo = ref.read(attendanceRepositoryProvider);
    final allSubjects = repo.getSubjects();

    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => EditSessionSheet(
        session:
            item.existingSession ??
            ClassSession(
              id: const Uuid().v4(),
              subjectId: item.subject.id,
              date: item.scheduledTime,
              status: AttendanceStatus.scheduled,
              durationMinutes: 60,
            ),
        initialSubject: item.subject,
        allSubjects: allSubjects,
        isNew: item.existingSession == null,
      ),
    );
    // Auto-updates via stream
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Standard rounded shape
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // Use the specific color tint to differentiate (Green tint vs Red tint)
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color, // Text matches status color for clarity
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EmptyStateActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: CustomPaint(
        painter: _RadarPainter(_controller, primary),
        size: const Size(12, 12),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> _animation;
  final Color _color;

  _RadarPainter(this._animation, this._color) : super(repaint: _animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw expanding ring
    final ringPaint = Paint()
      ..color = _color.withValues(alpha: 0.3 * (1 - _animation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final ringRadius = radius * 0.4 + (radius * 1.6 * _animation.value);
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Draw main solid dot
    final dotPaint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
