import 'package:flutter/material.dart';

import '../../../../core/domain/entities/laptop.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';

class LaptopRecommendationCard extends StatelessWidget {
  const LaptopRecommendationCard({
    super.key,
    required this.recommendation,
    required this.rank,
    required this.onTap,
  });

  final LaptopRecommendation recommendation;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final laptop = recommendation.laptop;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rank == 1
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.line,
          width: rank == 1 ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? AppColors.accent
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (rank == 1) ...[
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 12,
                              color: AppColors.ink,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            rank == 1 ? 'الاختيار الأول' : '#$rank',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TagPill(
                      label: 'تطابق ${recommendation.matchPercent}%',
                      icon: Icons.auto_awesome_rounded,
                      background: AppColors.successSoft,
                      foreground: AppColors.success,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 112,
                      height: 106,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          laptop.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.laptop_mac_rounded,
                                size: 38,
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            laptop.brand,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            laptop.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                laptop.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Icon(
                                Icons.circle,
                                size: 3,
                                color: AppColors.muted.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 7),
                              Icon(
                                laptop.inStock
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                size: 11,
                                color: laptop.inStock
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                laptop.inStock ? 'متوفر محلياً' : 'استيراد',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: laptop.inStock
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatEgp(laptop.price),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (laptop.oldPrice != null) ...[
                                const SizedBox(width: 5),
                                Text(
                                  formatEgp(laptop.oldPrice!),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final spec in [
                      laptop.processor,
                      laptop.gpu,
                      laptop.ram,
                    ])
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          spec,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${laptop.stores} متاجر',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (recommendation.reasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 13,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          recommendation.reasons.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 9,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'شوف التفاصيل والمقارنة',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const Spacer(),
                    Text(
                      'آخر تحديث منذ 12 دقيقة',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
