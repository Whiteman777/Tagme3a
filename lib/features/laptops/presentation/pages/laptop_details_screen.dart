import 'package:flutter/material.dart';

import '../../../../core/domain/entities/laptop.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/app_snack.dart';
import '../../../../core/presentation/widgets/page_top_bar.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';

class LaptopDetailsScreen extends StatelessWidget {
  const LaptopDetailsScreen({
    super.key,
    required this.recommendation,
    required this.useCase,
  });

  final LaptopRecommendation recommendation;
  final LaptopUseCase useCase;

  @override
  Widget build(BuildContext context) {
    final laptop = recommendation.laptop;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageTopBar(
            title: 'اللابتوب المناسب',
            subtitle: 'مقارنة وتفاصيل قبل الشراء',
            leading: CircleIconButton(
              icon: Icons.arrow_forward_rounded,
              tooltip: 'رجوع',
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              CircleIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'مشاركة',
                onTap: () => AppSnack.show(
                  context,
                  'تم نسخ رابط ${laptop.name}',
                  icon: Icons.link_rounded,
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              children: [
                Container(
                  height: 218,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF9FAFE), Color(0xFFF1F4FC)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        bottom: -40,
                        end: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Image.asset(
                            laptop.imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.laptop_mac_rounded,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 14,
                        start: 14,
                        child: TagPill(
                          label: 'تطابق ${recommendation.matchPercent}%',
                          icon: Icons.auto_awesome_rounded,
                          background: AppColors.accent,
                          foreground: AppColors.ink,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      laptop.brand,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      laptop.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TagPill(
                      label: laptop.inStock ? 'متوفر محلياً' : 'استيراد',
                      icon: laptop.inStock
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      background: laptop.inStock
                          ? AppColors.successSoft
                          : AppColors.warningSoft,
                      foreground: laptop.inStock
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 8.5,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  laptop.name,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 24,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatEgp(laptop.price),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (laptop.oldPrice != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          formatEgp(laptop.oldPrice!),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${laptop.stores} متاجر',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: recommendation.matchPercent / 100,
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.accent,
                              ),
                            ),
                            Text(
                              '${recommendation.matchPercent}%',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مناسب لاستخدام ${useCase.label}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'محسوب على الأداء، التوفر المحلي، والقيمة مقابل '
                              'ميزانيتك.',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 9.5,
                                height: 1.65,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'المواصفات',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 2.4,
                  children: [
                    _SpecTile(
                      icon: Icons.memory_rounded,
                      label: 'المعالج',
                      value: laptop.processor,
                    ),
                    _SpecTile(
                      icon: Icons.videogame_asset_rounded,
                      label: 'كارت الشاشة',
                      value: laptop.gpu,
                    ),
                    _SpecTile(
                      icon: Icons.view_module_rounded,
                      label: 'الرامات',
                      value: laptop.ram,
                    ),
                    _SpecTile(
                      icon: Icons.storage_rounded,
                      label: 'التخزين',
                      value: laptop.storage,
                    ),
                    _SpecTile(
                      icon: Icons.monitor_rounded,
                      label: 'الشاشة',
                      value: laptop.display,
                    ),
                    _SpecTile(
                      icon: Icons.storefront_rounded,
                      label: 'المتاجر',
                      value: '${laptop.stores} متاجر',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'ليه الاختيار ده؟',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < recommendation.reasons.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.successSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation.reasons[index],
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11,
                                  height: 1.7,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'أداء الاستخدامات',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      for (final entry in LaptopUseCase.values) ...[
                        _ScoreRow(
                          label: entry.label,
                          score: laptop.useCaseScores[entry] ?? 0,
                          highlighted: entry == useCase,
                        ),
                        if (entry != LaptopUseCase.values.last)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'نسبة التطابق ترشيح تجريبي وليست تقييماً نهائياً. '
                        'راجع المتجر قبل الشراء.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 9.5,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 50,
                  child: Material(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => AppSnack.show(
                        context,
                        'تمت إضافة ${laptop.name} للمفضلة',
                        icon: Icons.favorite_rounded,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: AppColors.primary,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LimeButton(
                    label: 'أضف للمقارنة',
                    icon: Icons.compare_arrows_rounded,
                    expand: true,
                    onPressed: () => AppSnack.show(
                      context,
                      'تمت إضافة ${laptop.name} لقائمة المقارنة',
                      icon: Icons.compare_arrows_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.score,
    required this.highlighted,
  });

  final String label;
  final int score;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: highlighted ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppColors.softBlue,
              valueColor: AlwaysStoppedAnimation(
                highlighted ? AppColors.primary : AppColors.lineStrong,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$score%',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: highlighted ? AppColors.primary : AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
