import 'package:flutter/material.dart';

class StatsDisplay extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatsDisplay({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color.withOpacity(0.8)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}
