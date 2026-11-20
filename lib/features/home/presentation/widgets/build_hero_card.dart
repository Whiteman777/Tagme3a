import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class BuildHeroCard extends StatelessWidget {
  const BuildHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CircuitPatternPainter()),
            ),
          ),
          PositionedDirectional(
            bottom: -26,
            end: -18,
            child: Icon(
              Icons.memory_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: AppColors.ink,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ذكاء تجميعة',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TagPill(
                      label: 'وفّر حتى 4,600 ج.م',
                      icon: Icons.savings_outlined,
                      background: Colors.white.withValues(alpha: 0.13),
                      foreground: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.16),
                      fontSize: 9.5,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'جمّع جهازك\nبميزانيتك',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 27,
                    height: 1.28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'حدد ميزانيتك واستخدامك، وإحنا نختار القطع المتوافقة '
                  'بأفضل سعر في مصر.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 17),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: 43,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ابدأ التجميعة الآن',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 17,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircuitPatternPainter extends CustomPainter {
  const _CircuitPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.22);

    final paths = <Path>[
      Path()
        ..moveTo(size.width * 0.64, 0)
        ..lineTo(size.width * 0.64, size.height * 0.18)
        ..lineTo(size.width * 0.82, size.height * 0.18)
        ..lineTo(size.width * 0.82, size.height * 0.38),
      Path()
        ..moveTo(size.width * 0.9, size.height * 0.1)
        ..lineTo(size.width * 0.94, size.height * 0.1)
        ..lineTo(size.width * 0.94, size.height * 0.3),
      Path()
        ..moveTo(size.width, size.height * 0.66)
        ..lineTo(size.width * 0.82, size.height * 0.66)
        ..lineTo(size.width * 0.82, size.height * 0.8)
        ..lineTo(size.width * 0.68, size.height * 0.8),
      Path()
        ..moveTo(size.width * 0.6, size.height)
        ..lineTo(size.width * 0.6, size.height * 0.86)
        ..lineTo(size.width * 0.5, size.height * 0.86),
    ];

    for (final path in paths) {
      canvas.drawPath(path, linePaint);
    }

    for (final offset in [
      Offset(size.width * 0.64, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.38),
      Offset(size.width * 0.94, size.height * 0.3),
      Offset(size.width * 0.82, size.height * 0.8),
      Offset(size.width * 0.6, size.height * 0.86),
    ]) {
      canvas.drawCircle(offset, 2.2, dotPaint);
    }

    final chipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.44, 54, 42),
      const Radius.circular(8),
    );
    canvas.drawRRect(chipRect, linePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72 + 6, size.height * 0.44 + 6, 42, 30),
        const Radius.circular(5),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
