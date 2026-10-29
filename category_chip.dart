import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

/// شارة ملونة تعرض تصنيف الإشعار
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.compact = false});

  final Category category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
