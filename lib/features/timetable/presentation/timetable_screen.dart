import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/timetable_provider.dart';
import '../../attendance/presentation/providers/attendance_provider.dart';
import '../../attendance/data/repositories/attendance_repository.dart';
import '../../attendance/data/models/subject_model.dart';
import '../data/models/timetable_entry_model.dart';
import '../../../../core/presentation/animations/fade_in_slide.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
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
      body: CustomScrollView(
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
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedDay = dayNum);
                        },
                        showCheckmark: false,
                        selectedColor: const Color(0xFF2D3436), // Obsidian Grey
                        backgroundColor: Colors.white,
                        side: isSelected
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No classes today. Enjoy your freedom!',
                                style: Theme.of(context).textTheme.bodyLarge
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
                    entries.sort((a, b) => a.startTime.compareTo(b.startTime));

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = entries[index];
                        final subject = subjectMap[entry.subjectId];
                        if (subject == null) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: FadeInSlide(
                            duration: const Duration(milliseconds: 500),
                            delay: Duration(milliseconds: index * 100),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
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
                                      builder: (context) => _EditEntrySheet(
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
                                            color: subject.color.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 14,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.tertiary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${entry.startTime} • ${formatDuration(entry.durationInHours)}',
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary,
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
                child: Center(child: Text('Error loading subjects: $err')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddEntrySheet(context, ref);
        },
        backgroundColor: const Color(0xFF2D3436), // Obsidian Grey
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddEntrySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Class on ${_dayName(widget.selectedDay)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          subjectsAsync.when(
            data: (subjects) => DropdownButtonFormField<Subject>(
              initialValue: _selectedSubject,
              hint: const Text('Select Subject'),
              items: subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading subjects'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (t != null) setState(() => _startTime = t);
                  },
                  child: Text('Start: ${_startTime.format(context)}'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<double>(
                  initialValue: _duration,
                  decoration: const InputDecoration(labelText: 'Duration'),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selectedSubject == null
                ? null
                : () async {
                    final hour = _startTime.hour.toString().padLeft(2, '0');
                    final minute = _startTime.minute.toString().padLeft(2, '0');

                    await ref
                        .read(attendanceRepositoryProvider)
                        .addTimetableEntry(
                          subjectId: _selectedSubject!.id,
                          dayOfWeek: widget.selectedDay,
                          startTime: '$hour:$minute',
                          durationInHours: _duration,
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
            child: const Text('Add Class'),
          ),
          const SizedBox(height: 24),
        ],
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

    _duration = widget.entry.durationInHours;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Class', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<Subject>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: widget.subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSubject = val);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (t != null) setState(() => _startTime = t);
                  },
                  child: Text('Start: ${_startTime.format(context)}'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<double>(
                  initialValue: _duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration (hrs)',
                  ),
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    await ref
                        .read(attendanceRepositoryProvider)
                        .deleteTimetableEntry(widget.entry.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () async {
                    final hour = _startTime.hour.toString().padLeft(2, '0');
                    final minute = _startTime.minute.toString().padLeft(2, '0');

                    final updatedEntry = TimetableEntry(
                      id: widget.entry.id,
                      subjectId: _selectedSubject.id,
                      dayOfWeek: widget.entry.dayOfWeek,
                      startTime: '$hour:$minute',
                      durationInHours: _duration,
                      isRecurring: widget.entry.isRecurring,
                    );

                    await ref
                        .read(attendanceRepositoryProvider)
                        .updateTimetableEntry(updatedEntry);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
