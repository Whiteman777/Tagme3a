import 'package:flutter/material.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';

class PriceHistoryChart extends StatelessWidget {
  const PriceHistoryChart({
    super.key,
    required this.points,
    this.color = AppColors.success,
  });

  final List<PricePoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }
    final prices = points.map((point) => point.price).toList();
    final low = prices.reduce((a, b) => a < b ? a : b);
    final high = prices.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        SizedBox(
          height: 94,
          width: double.infinity,
          child: CustomPaint(
            painter: _PriceLinePainter(points: points, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              formatEgp(low),
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Text(
              formatEgp(high),
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceLinePainter extends CustomPainter {
  const _PriceLinePainter({required this.points, required this.color});

  final List<PricePoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final prices = points.map((point) => point.price.toDouble()).toList();
    final low = prices.reduce((a, b) => a < b ? a : b);
    final high = prices.reduce((a, b) => a > b ? a : b);
    final range = (high - low).clamp(1, double.infinity);
    const topPadding = 10.0;
    const bottomPadding = 8.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width;

    double xFor(int index) {
      if (points.length == 1) return chartWidth;
      return chartWidth - (index / (points.length - 1)) * chartWidth;
    }

    double yFor(double price) {
      final normalized = (price - low) / range;
      return topPadding + normalized * chartHeight;
    }

    final gridPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final linePath = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = Offset(xFor(i), yFor(prices[i]));
      if (i == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, size.height);
        fillPath.lineTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        fillPath.lineTo(offset.dx, offset.dy);
      }
    }
    fillPath
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final last = Offset(xFor(points.length - 1), yFor(prices.last));
    canvas.drawCircle(last, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 3.3, Paint()..color = color);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset((x + dashWidth).clamp(start.dx, end.dx), start.dy),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PriceLinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
