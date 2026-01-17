import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:tally/core/data/models/session_model.dart';
import '../../../../core/presentation/widgets/empty_state.dart';

class SubjectHistoryList extends StatelessWidget {
  final List<ClassSession> history;

  const SubjectHistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: 'No history yet',
          subtitle: 'Classes will appear here once marked.',
        ),
      );
    }

    // Sort history by date descending
    final sortedHistory = List<ClassSession>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    return GroupedListView<ClassSession, DateTime>(
      elements: sortedHistory,
      groupBy: (element) => DateTime(element.date.year, element.date.month),
      groupSeparatorBuilder: (DateTime groupByValue) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          DateFormat('MMMM yyyy').format(groupByValue).toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      itemBuilder: (context, ClassSession session) {
        Color color;
        IconData icon;
        String label;

        switch (session.status) {
          case AttendanceStatus.present:
            color = const Color(0xFF27AE60);
            icon = Icons.check_circle_rounded;
            label = 'Present';
            break;
          case AttendanceStatus.absent:
            color = const Color(0xFFC0392B);
            icon = Icons.cancel_rounded;
            label = 'Absent';
            break;
          case AttendanceStatus.cancelled:
            color = Theme.of(context).disabledColor;
            icon = Icons.block_rounded;
            label = 'Cancelled';
            break;
          case AttendanceStatus.unmarked:
            color = const Color(0xFF2D3436);
            icon = Icons.help_outline_rounded;
            label = 'Unmarked';
            break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Optional: Add tap functionality if needed
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('d').format(session.date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, h:mm a').format(session.date),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(icon, color: color, size: 22),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      useStickyGroupSeparators: true,
      floatingHeader: true,
      order: GroupedListOrder.DESC,
      physics: const NeverScrollableScrollPhysics(), // Important for Sliver
      shrinkWrap: true, // Important for Sliver
    );
  }
}
