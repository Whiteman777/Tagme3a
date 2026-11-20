import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/category_icons.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/app_snack.dart';
import '../../../../core/presentation/widgets/price_text.dart';
import '../../../../core/presentation/widgets/product_artwork.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../alerts/presentation/bloc/alerts_event.dart';
import '../../../builder/presentation/bloc/builder_bloc.dart';
import '../../../builder/presentation/bloc/builder_event.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../../product/domain/usecases/get_product_details.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/offers_card.dart';
import '../widgets/price_history_chart.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(
        getProductDetails: GetProductDetails(context.read<ProductRepository>()),
      )..add(ProductRequested(product.id)),
      child: _ProductDetailsView(preview: product),
    );
  }
}

class _ProductDetailsView extends StatelessWidget {
  const _ProductDetailsView({required this.preview});

  final Product preview;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final product = state.product ?? preview;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                backgroundColor: AppColors.surface,
                surfaceTintColor: AppColors.surface,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: Center(
                    child: CircleIconButton(
                      icon: Icons.arrow_forward_rounded,
                      tooltip: 'رجوع',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                titleSpacing: 6,
                title: Row(
                  children: [
                    Text(
                      'تفاصيل المنتج',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (state.status == LoadStatus.loading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                    ],
                  ],
                ),
                actions: [
                  CircleIconButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'مشاركة',
                    onTap: () => AppSnack.show(
                      context,
                      'تم نسخ رابط ${product.name}',
                      icon: Icons.link_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.favorite_border_rounded,
                    tooltip: 'المفضلة',
                    onTap: () => AppSnack.show(
                      context,
                      'تمت إضافة ${product.name} للمفضلة',
                      icon: Icons.favorite_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              SliverToBoxAdapter(child: _ProductBody(product: product)),
            ],
          ),
          bottomNavigationBar: _BottomCta(product: product),
        );
      },
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ArtworkPanel(product: product),
          const SizedBox(height: 18),
          Row(
            children: [
              TagPill(
                label: product.category.label,
                icon: product.category.icon,
                background: AppColors.softBlue,
                foreground: AppColors.primary,
                fontSize: 10,
              ),
              const SizedBox(width: 6),
              TagPill(
                label: product.brand,
                background: AppColors.surface,
                foreground: AppColors.inkSoft,
                borderColor: AppColors.line,
                fontSize: 10,
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 17, color: AppColors.gold),
              const SizedBox(width: 3),
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '(${product.reviews})',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 23,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            product.tagline,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          if (product.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final badge in product.badges)
                  TagPill(
                    label: badge,
                    icon: Icons.verified_rounded,
                    background: AppColors.accentSoft,
                    foreground: AppColors.ink,
                    fontSize: 9.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _PricePanel(product: product),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'أهم المواصفات',
            subtitle: 'الملخص السريع قبل ما تشتري',
          ),
          const SizedBox(height: 10),
          _HighlightsCard(product: product),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'العروض المتاحة',
            subtitle: '${product.stores} متاجر موثوقة · الأسعار محدثة',
            trailing: TagPill(
              label: 'أفضل سعر ${formatEgp(product.lowestOffer)}',
              background: AppColors.successSoft,
              foreground: AppColors.success,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          OffersCard(
            offers: product.offers,
            onOfferTap: (offer) => AppSnack.show(
              context,
              'فتح عرض ${offer.merchant} بسعر ${formatEgp(offer.price)}',
              icon: Icons.storefront_rounded,
            ),
          ),
          if (product.priceHistory.length > 1) ...[
            const SizedBox(height: 22),
            _SectionTitle(
              title: 'تاريخ السعر',
              subtitle: 'آخر 30 يوم · نتابع التغير يومياً',
              trailing: TagPill(
                label: product.change30dPercent == null
                    ? 'مستقر'
                    : '${product.change30dPercent!}%',
                icon: (product.change30dPercent ?? 0) <= 0
                    ? Icons.south_east_rounded
                    : Icons.north_east_rounded,
                background: (product.change30dPercent ?? 0) <= 0
                    ? AppColors.successSoft
                    : AppColors.dangerSoft,
                foreground: (product.change30dPercent ?? 0) <= 0
                    ? AppColors.success
                    : AppColors.danger,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PriceStat(
                        label: 'أقل سعر',
                        value: product.low30d ?? product.price,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 18),
                      _PriceStat(
                        label: 'أعلى سعر',
                        value: product.high30d ?? product.price,
                        color: AppColors.muted,
                      ),
                      const Spacer(),
                      const Text(
                        'السعر الحالي',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatEgp(product.price),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PriceHistoryChart(points: product.priceHistory),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          _SectionTitle(title: 'عن المنتج'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              product.description,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                height: 1.9,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
              ),
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
                  'كل سعر معروض له مصدر ووقت تحقق. الأسعار استرشادية '
                  'وقابلة للتغير من المتجر.',
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
    );
  }
}

class _ArtworkPanel extends StatelessWidget {
  const _ArtworkPanel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 245,
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
            top: -40,
            start: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -50,
            end: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: ProductArtwork(
              product: product,
              width: double.infinity,
              height: 210,
              radius: 22,
              padding: const EdgeInsets.all(14),
              background: Colors.transparent,
            ),
          ),
          if (product.discountPercent != null)
            PositionedDirectional(
              top: 14,
              start: 14,
              child: DiscountBadge(percent: product.discountPercent!),
            ),
          PositionedDirectional(
            top: 14,
            end: 14,
            child: TagPill(
              label: '${product.stores} متاجر',
              icon: Icons.storefront_rounded,
              background: Colors.white.withValues(alpha: 0.94),
              foreground: AppColors.inkSoft,
              borderColor: AppColors.line,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(
                value: product.price,
                oldValue: product.oldPrice,
                size: 28,
                oldSize: 12,
              ),
              const SizedBox(width: 8),
              if (product.change30dPercent != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: TagPill(
                    label: '${product.change30dPercent!}% هذا الشهر',
                    icon: (product.change30dPercent ?? 0) <= 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    background: (product.change30dPercent ?? 0) <= 0
                        ? AppColors.successSoft
                        : AppColors.dangerSoft,
                    foreground: (product.change30dPercent ?? 0) <= 0
                        ? AppColors.success
                        : AppColors.danger,
                    fontSize: 8.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                  ),
                ),
              const Spacer(),
              if (product.discountPercent != null)
                DiscountBadge(percent: product.discountPercent!, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.offers.isEmpty
                          ? 'أفضل سعر متاح'
                          : 'أفضل سعر من ${product.offers.first.merchant}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'آخر تحديث ${product.offers.isEmpty ? 'منذ 12 دقيقة' : product.offers.first.lastSeen} · شامل الضمان',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              TagPill(
                label: 'متوفر',
                icon: Icons.check_circle_rounded,
                background: AppColors.successSoft,
                foreground: AppColors.success,
                fontSize: 9,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final highlight in product.highlights)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    highlight,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PriceStat extends StatelessWidget {
  const _PriceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          formatEgp(value),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    onTap: () {
                      context.read<AlertsBloc>().add(
                        AlertAddedForProduct(product),
                      );
                      AppSnack.show(
                        context,
                        'سننبهك عند انخفاض سعر ${product.name}',
                        icon: Icons.notifications_active_rounded,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LimeButton(
                  label: product.isLaptop
                      ? 'أضف اللابتوب للمقارنة'
                      : 'أضف إلى التجميعة',
                  icon: product.isLaptop
                      ? Icons.compare_arrows_rounded
                      : Icons.add_rounded,
                  expand: true,
                  onPressed: () {
                    if (product.isLaptop) {
                      AppSnack.show(
                        context,
                        'تمت إضافة ${product.name} لقائمة المقارنة',
                        icon: Icons.compare_arrows_rounded,
                      );
                      return;
                    }
                    context.read<BuilderBloc>().add(
                      BuilderProductAdded(product),
                    );
                    final navigator = Navigator.of(context);
                    final navigation = context.read<NavigationCubit>();
                    AppSnack.show(
                      context,
                      'تمت إضافة ${product.name} إلى تجميعتك',
                      icon: Icons.check_circle_rounded,
                      actionLabel: 'عرض',
                      onAction: () {
                        navigator.pop();
                        navigation.select(NavigationCubit.builderTab);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
