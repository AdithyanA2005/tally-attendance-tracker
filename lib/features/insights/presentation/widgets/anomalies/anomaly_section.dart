import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/anomaly_provider.dart';
import 'anomaly_card.dart';
import '../../../../../core/presentation/animations/fade_in_slide.dart';

class AnomalySection extends ConsumerWidget {
  const AnomalySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomalies = ref.watch(attendanceAnomaliesProvider);

    if (anomalies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Anomalies',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${anomalies.length} Subjects',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: anomalies.length,
          itemBuilder: (context, index) {
            return FadeInSlide(
              duration: const Duration(milliseconds: 600),
              delay: Duration(milliseconds: index * 100),
              child: AnomalyCard(summary: anomalies[index]),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
