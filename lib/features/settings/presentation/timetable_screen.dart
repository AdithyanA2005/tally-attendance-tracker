import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/timetable_provider.dart';
import '../../calendar/presentation/providers/attendance_provider.dart';
import '../../calendar/data/repositories/attendance_repository.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';
import '../../../../core/presentation/animations/fade_in_slide.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:go_router/go_router.dart';
import '../../../../core/utils/string_utils.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedDay = 1; // Mon = 1

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(timetableProvider(_selectedDay));
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(timetableProvider(_selectedDay));
          ref.invalidate(subjectsStreamProvider);
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
                    'Timetable',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: false,
                ),
                // Day Selector as a pinned header or inside a SliverToBoxAdapter
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 70, // Increased height for better tap area
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final dayNum = index + 1;
                        final isSelected = _selectedDay == dayNum;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Center(
                            child: FilterChip(
                              label: Text(
                                _days[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedDay = dayNum);
                                }
                              },
                              showCheckmark: false,
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              side: isSelected
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.2),
                                    ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  sliver: subjectsAsync.when(
                    data: (subjects) {
                      final subjectMap = {for (var s in subjects) s.id: s};

                      return timetableAsync.when(
                        data: (entries) {
                          if (entries.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.weekend,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No classes today. Enjoy your freedom!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Sort by start time
                          entries.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                          );

                          return SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final entry = entries[index];
                              final subject = subjectMap[entry.subjectId];
                              if (subject == null) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: FadeInSlide(
                                  duration: const Duration(milliseconds: 500),
                                  delay: Duration(milliseconds: index * 100),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.1),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.02,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            constraints: const BoxConstraints(
                                              maxWidth: 600,
                                            ),
                                            builder: (context) =>
                                                _EditEntrySheet(
                                                  entry: entry,
                                                  subjects: subjects,
                                                ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: subject.color
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  subject.name.substring(0, 1),
                                                  style: TextStyle(
                                                    color: subject.color,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
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
                                                      subject.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .access_time_rounded,
                                                          size: 14,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${entry.startTime} • ${formatDuration(entry.durationMinutes / 60)}',
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .tertiary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
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
                                ),
                              );
                            }, childCount: entries.length),
                          );
                        },
                        loading: () => const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => SliverFillRemaining(
                          child: Center(child: Text('Error: $err')),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      child: Center(
                        child: Text('Error loading subjects: $err'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddEntrySheet(context, ref);
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3436),
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddEntrySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => _AddEntrySheet(selectedDay: _selectedDay),
    );
  }
}

class _AddEntrySheet extends ConsumerStatefulWidget {
  final int selectedDay;
  const _AddEntrySheet({required this.selectedDay});

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  Subject? _selectedSubject;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  double _duration = 1.0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Class on ${_dayName(widget.selectedDay)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subject Dropdown
            subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.subject_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Subjects Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add subjects first to create timetable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/manage_subjects');
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Subjects'),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<Subject>(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Select Subject',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  initialValue: _selectedSubject,
                  items: subjects
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Error loading subjects'),
            ),
            const SizedBox(height: 16),

            // Time and Duration Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (t != null) setState(() => _startTime = t);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                        ),
                      ),
                      child: Text(
                        _startTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    initialValue: _duration,
                    items: [0.5, 0.75, 50 / 60, 1.0, 1.5, 2.0, 3.0]
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(formatDuration(d)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _duration = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Add Button
            FilledButton(
              onPressed: (_selectedSubject == null || _isSaving)
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        final hour = _startTime.hour.toString().padLeft(2, '0');
                        final minute = _startTime.minute.toString().padLeft(
                          2,
                          '0',
                        );

                        await ref
                            .read(attendanceRepositoryProvider)
                            .addTimetableEntry(
                              subjectId: _selectedSubject!.id,
                              dayOfWeek: widget.selectedDay,
                              startTime: '$hour:$minute',
                              durationMinutes: (_duration * 60).toInt(),
                            );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Add Class',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isSaving ? Colors.transparent : null,
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _dayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }
}

class _EditEntrySheet extends ConsumerStatefulWidget {
  final TimetableEntry entry;
  final List<Subject> subjects;

  const _EditEntrySheet({required this.entry, required this.subjects});

  @override
  ConsumerState<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends ConsumerState<_EditEntrySheet> {
  late Subject _selectedSubject;
  late TimeOfDay _startTime;
  late double _duration;
  bool _isSaving = false;
  bool _hasChanges = false;

  void _checkForChanges() {
    final oldTime = widget.entry.startTime.split(':');
    final oldHour = int.parse(oldTime[0]);
    final oldMinute = int.parse(oldTime[1]);

    final hasChanges =
        _selectedSubject.id != widget.entry.subjectId ||
        _duration != (widget.entry.durationMinutes / 60) ||
        _startTime.hour != oldHour ||
        _startTime.minute != oldMinute;

    if (hasChanges != _hasChanges) setState(() => _hasChanges = hasChanges);
  }

  @override
  void initState() {
    super.initState();
    // Find subject matching ID
    try {
      _selectedSubject = widget.subjects.firstWhere(
        (s) => s.id == widget.entry.subjectId,
      );
    } catch (e) {
      // Fallback if subject not found (unlikely)
      _selectedSubject = widget.subjects.first;
    }

    final parts = widget.entry.startTime.split(':');
    _startTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    _duration = widget.entry.durationMinutes / 60;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Class',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subject Dropdown
            DropdownButtonFormField<Subject>(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(16),
              decoration: InputDecoration(
                labelText: 'Subject',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              initialValue: _selectedSubject,
              items: widget.subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSubject = val;
                    _checkForChanges();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Time and Duration Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (t != null) {
                        setState(() {
                          _startTime = t;
                          _checkForChanges();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                        ),
                      ),
                      child: Text(
                        _startTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    initialValue: _duration,
                    items: [0.5, 0.75, 50 / 60, 1.0, 1.5, 2.0, 3.0]
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(formatDuration(d)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _duration = val;
                          _checkForChanges();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Class?'),
                                content: Text(
                                  'Are you sure you want to delete this ${_selectedSubject.name} class at ${widget.entry.startTime}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && context.mounted) {
                              setState(() => _isSaving = true);
                              try {
                                await ref
                                    .read(attendanceRepositoryProvider)
                                    .deleteTimetableEntry(widget.entry.id);
                                if (context.mounted) Navigator.pop(context);
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: (_isSaving || !_hasChanges)
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            try {
                              final hour = _startTime.hour.toString().padLeft(
                                2,
                                '0',
                              );
                              final minute = _startTime.minute
                                  .toString()
                                  .padLeft(2, '0');

                              final updatedEntry = TimetableEntry(
                                id: widget.entry.id,
                                subjectId: _selectedSubject.id,
                                semesterId: widget.entry.semesterId,
                                dayOfWeek: widget.entry.dayOfWeek,
                                startTime: '$hour:$minute',
                                durationMinutes: (_duration * 60).toInt(),
                                isRecurring: widget.entry.isRecurring,
                              );

                              await ref
                                  .read(attendanceRepositoryProvider)
                                  .updateTimetableEntry(updatedEntry);
                              if (context.mounted) Navigator.pop(context);
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isSaving ? Colors.transparent : null,
                          ),
                        ),
                        if (_isSaving)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
