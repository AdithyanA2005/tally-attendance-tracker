import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'providers/calendar_provider.dart';
import 'providers/pending_attendance_provider.dart';
import '../../settings/data/models/timetable_entry_model.dart';
import '../../settings/data/repositories/settings_repository.dart';
import '../data/models/session_model.dart';

import 'widgets/edit_session_sheet.dart';
import '../data/models/subject_model.dart';
import '../../../../core/presentation/animations/fade_in_slide.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../../core/theme/app_theme.dart';

/// The main calendar interface for the application.
///
/// Displays a monthly view using [TableCalendar] and a daily schedule list.
/// Handles session interactions, substitutions, and extra class creation.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    final subjectMap = ref.watch(allSubjectsMapProvider);
    final timetableAsync = ref.watch(fullTimetableStreamProvider);
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final semesterStartDate = settingsRepo.getSemesterStartDate();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate providers to trigger refresh
          ref.invalidate(calendarEventsProvider);
          ref.invalidate(fullTimetableStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'Calendar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showAddExtraClassDialog(context);
                  },
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add Class',
                ),
                const SizedBox(width: 8),
              ],
            ),
            eventsAsync.when(
              data: (events) {
                return timetableAsync.when(
                  data: (timetable) {
                    final combinedEvents = _getCombinedDailySchedule(
                      _selectedDay ?? _focusedDay,
                      events,
                      timetable,
                      semesterStartDate,
                    );

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        TableCalendar<ClassSession>(
                          firstDay: DateTime.utc(2023, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          eventLoader: (day) {
                            // Use combined schedule to show markers for both saved and virtual sessions
                            return timetableAsync.maybeWhen(
                              data: (timetable) => _getCombinedDailySchedule(
                                day,
                                events,
                                timetable,
                                semesterStartDate,
                              ),
                              orElse: () => _getEventsForDay(day, events),
                            );
                          },
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            weekendTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            tablePadding: EdgeInsets.only(bottom: 12),
                          ),
                          daysOfWeekHeight: 40,
                          calendarBuilders: CalendarBuilders(
                            selectedBuilder: (context, date, events) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.primary
                                      : const Color(0xFF2D3436),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Theme.of(context).colorScheme.surface
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                            todayBuilder: (context, date, events) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.12)
                                      : const Color(
                                          0xFF2D3436,
                                        ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Theme.of(context).colorScheme.primary
                                        : const Color(0xFF2D3436),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return null;

                              final sessions = events.cast<ClassSession>();
                              final uniqueStatuses = sessions
                                  .where(
                                    (s) =>
                                        s.status != AttendanceStatus.cancelled,
                                  )
                                  .map((s) => s.status)
                                  .toSet();

                              if (uniqueStatuses.isEmpty ||
                                  uniqueStatuses.length == 1) {
                                return const SizedBox(); // Singular state or cancelled = No Dot
                              }

                              // Mixed state only
                              const dotColor = Color(0xFF2D3436); // Obsidian

                              // Check if this date is the selected date
                              final isSelected = isSameDay(date, _selectedDay);

                              return Positioned(
                                bottom: 10,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : dotColor, // Use calculated color
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Divider(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        if (combinedEvents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: EmptyState(
                              icon: Icons.event_note_rounded,
                              title: 'No records for this day',
                              subtitle:
                                  'Attendance marking is disabled for future dates.',
                            ),
                          )
                        else
                          ...combinedEvents.asMap().entries.map((entry) {
                            final index = entry.key;
                            final session = entry.value;
                            final subject =
                                subjectMap[session.subjectId] ??
                                Subject(
                                  id: '?',
                                  name: 'Unknown',
                                  minimumAttendancePercentage: 0,
                                  weeklyHours: 0,
                                  colorTag: 0xFF95A5A6, // Concrete Grey
                                );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: FadeInSlide(
                                duration: const Duration(milliseconds: 500),
                                delay: Duration(milliseconds: index * 100),
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Theme.of(context).cardColor,
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _showEditDialog(
                                        context,
                                        session,
                                        subject,
                                        subjectMap.values.toList(),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16, // Consistent padding
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: subject.color,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: subject.color
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  subject.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat.jm().format(
                                                    session.date,
                                                  ),
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Builder(
                                                  builder: (context) {
                                                    // Check for substitution
                                                    final scheduled = timetable
                                                        .where((t) {
                                                          if (t.dayOfWeek !=
                                                              session
                                                                  .date
                                                                  .weekday) {
                                                            return false;
                                                          }
                                                          final parts = t
                                                              .startTime
                                                              .split(':');
                                                          final h = int.parse(
                                                            parts[0],
                                                          );
                                                          final m = int.parse(
                                                            parts[1],
                                                          );
                                                          return h ==
                                                                  session
                                                                      .date
                                                                      .hour &&
                                                              m ==
                                                                  session
                                                                      .date
                                                                      .minute;
                                                        })
                                                        .firstOrNull;

                                                    if (scheduled != null &&
                                                        scheduled.subjectId !=
                                                            session.subjectId) {
                                                      final originalSubject =
                                                          subjectMap[scheduled
                                                              .subjectId] ??
                                                          Subject(
                                                            id: '?',
                                                            name: 'Unknown',
                                                            minimumAttendancePercentage:
                                                                0,
                                                            weeklyHours: 0,
                                                            colorTag:
                                                                0xFF95A5A6,
                                                          );
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 4,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .orange
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Substituted: ${originalSubject.name}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .orange,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox.shrink();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusBadge(
                                            text: session.status.name
                                                .toUpperCase(),
                                            color: _getStatusColor(
                                              session.status,
                                            ),
                                            isOutlined: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 40),
                      ]),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading timetable: $e')),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  List<ClassSession> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<ClassSession>> events,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  Color _getStatusColor(AttendanceStatus status) {
    return AppTheme.statusColors[status] ?? Colors.black;
  }

  List<ClassSession> _getCombinedDailySchedule(
    DateTime day,
    Map<DateTime, List<ClassSession>> allEvents,
    List<TimetableEntry> timetable,
    DateTime semesterStart,
  ) {
    // Optimization: Skip calculations for dates well before app usage
    if (day.year < 2023) return [];

    final dayEvents = _getEventsForDay(day, allEvents);

    // If selected day is before the official semester start, ignore the timetable
    // and only show manually logged extra sessions.
    final checkDate = DateTime(day.year, day.month, day.day);
    if (checkDate.isBefore(semesterStart)) {
      return dayEvents..sort((a, b) => a.date.compareTo(b.date));
    }

    final weekday = day.weekday;
    final scheduledForDay = timetable.where((e) => e.dayOfWeek == weekday);
    final combined = <ClassSession>[];
    final usedSessionIds = <String>{};

    for (var entry in scheduledForDay) {
      // Find matching session by time (Time takes precedence over SubjectId for swaps)
      ClassSession? match;
      try {
        match = dayEvents.firstWhere((s) {
          final timeParts = entry.startTime.split(':');
          if (timeParts.length < 2) return false;
          final h = int.parse(timeParts[0]);
          final m = int.parse(timeParts[1]);

          // Match Timetable slot with Session record.
          // If a session exists at this exact time, it overrides the default timetable subject
          // (e.g. a substitution or swap).
          return s.date.hour == h && s.date.minute == m;
        });
      } catch (_) {}

      if (match != null) {
        combined.add(match);
        usedSessionIds.add(match.id);
      } else {
        // No session marked for this timeslot. Show pending (Unmarked).
        final timeParts = entry.startTime.split(':');
        final h = int.parse(timeParts[0]);
        final m = int.parse(timeParts[1]);
        final d = DateTime(day.year, day.month, day.day, h, m);

        combined.add(
          ClassSession(
            id: 'virtual_${entry.id}_${day.toIso8601String()}',
            subjectId: entry.subjectId,
            date: d,
            status: AttendanceStatus.unmarked,
          ),
        );
      }
    }

    // Add extra sessions (not in timetable)
    for (var s in dayEvents) {
      if (!usedSessionIds.contains(s.id)) {
        combined.add(s);
      }
    }

    combined.sort((a, b) => a.date.compareTo(b.date));
    return combined;
  }

  void _showEditDialog(
    BuildContext context,
    ClassSession session,
    Subject currentSubject,
    List<Subject> allSubjects,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSessionSheet(
        session: session,
        initialSubject: currentSubject,
        allSubjects: allSubjects,
      ),
    );
  }

  void _showAddExtraClassDialog(BuildContext context) {
    // Determine time: if selected day is today, use now(), else use 9:00 AM of selected day
    DateTime baseTime = _selectedDay ?? DateTime.now();
    final now = DateTime.now();
    if (isSameDay(baseTime, now)) {
      baseTime = now;
    } else {
      baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 9, 0);
    }

    // Default subject (first one or placeholder)
    final allSubjects = ref.read(allSubjectsMapProvider).values.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSessionSheet(
        session: ClassSession(
          id: const Uuid().v4(),
          subjectId: allSubjects.isNotEmpty ? allSubjects.first.id : '',
          date: baseTime,
          status: AttendanceStatus.present,
          isExtraClass: true,
        ),
        initialSubject: allSubjects.isNotEmpty ? allSubjects.first : null,
        allSubjects: allSubjects,
        isNew: true,
      ),
    );
  }
}
