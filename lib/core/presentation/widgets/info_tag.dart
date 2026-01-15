import 'package:flutter/material.dart';

class InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoTag({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
