import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.value,
    this.oldValue,
    this.size = 18,
    this.color = AppColors.ink,
    this.oldSize = 11,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.start,
    this.bold = true,
    this.showOldFirst = false,
  });

  final int value;
  final int? oldValue;
  final double size;
  final double oldSize;
  final Color color;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;
  final bool bold;
  final bool showOldFirst;

  @override
  Widget build(BuildContext context) {
    final price = Text(
      formatEgp(value),
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: size,
        height: 1.25,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      ),
    );
    final old = oldValue == null
        ? null
        : Text(
            formatEgp(oldValue!),
            textAlign: textAlign,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: oldSize,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.muted,
            ),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: showOldFirst
          ? [
              if (old != null) old,
              if (old != null) const SizedBox(height: 1),
              price,
            ]
          : [
              price,
              if (old != null) ...[const SizedBox(height: 1), old],
            ],
    );
  }
}
