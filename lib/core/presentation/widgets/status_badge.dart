import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool isOutlined;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? null : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: isOutlined ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
