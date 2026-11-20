import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/entities/home_feed.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/product_category.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/section_header.dart';
import '../../../../core/presentation/widgets/surface_card.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/presentation/bloc/catalog_bloc.dart';
import '../../../catalog/presentation/bloc/catalog_event.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/build_hero_card.dart';
import '../widgets/home_category_row.dart';
import '../widgets/home_deal_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_laptop_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          HomeHeader(
            onSearchTap: () => Navigator.of(context).push(AppRoutes.search()),
            onAlertsTap: () => Navigator.of(context).push(AppRoutes.alerts()),
            onProfileTap: () => context.read<NavigationCubit>().select(
              NavigationCubit.accountTab,
            ),
            onFilterTap: () => _openCatalog(context),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading ||
                      state.status == LoadStatus.initial) {
                    return const _HomeLoading();
                  }
                  if (state.status == LoadStatus.failure ||
                      state.feed == null) {
                    return EmptyState(
                      icon: Icons.wifi_tethering_off_rounded,
                      title: 'تعذر الوصول للأسعار',
                      message:
                          state.errorMessage ??
                          'تأكد من الاتصال وحاول تحميل الصفحة مرة أخرى.',
                      actionLabel: 'إعادة المحاولة',
                      onAction: () =>
                          context.read<HomeBloc>().add(const HomeStarted()),
                    );
                  }
                  return _HomeContent(
                    feed: state.feed!,
                    onRefresh: () async {
                      context.read<HomeBloc>().add(
                        const HomeRefreshRequested(),
                      );
                      await Future<void>.delayed(
                        const Duration(milliseconds: 550),
                      );
                    },
                    onOpenProduct: (product) =>
                        Navigator.of(context).push(AppRoutes.product(product)),
                    onCategorySelected: (category) {
                      context.read<CatalogBloc>().add(
                        CatalogCategorySelected(category),
                      );
                      context.read<NavigationCubit>().select(
                        NavigationCubit.storeTab,
                      );
                    },
                    onAllCategories: () => _openCatalog(context),
                    onViewAllDeals: () {
                      context.read<CatalogBloc>().add(
                        const CatalogFiltersCleared(),
                      );
                      context.read<NavigationCubit>().select(
                        NavigationCubit.storeTab,
                      );
                    },
                    onViewLaptops: () => context.read<NavigationCubit>().select(
                      NavigationCubit.laptopsTab,
                    ),
                    onBuildTap: () => context.read<NavigationCubit>().select(
                      NavigationCubit.builderTab,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCatalog(BuildContext context) {
    context.read<CatalogBloc>().add(const CatalogCategorySelected(null));
    context.read<NavigationCubit>().select(NavigationCubit.storeTab);
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.feed,
    required this.onRefresh,
    required this.onOpenProduct,
    required this.onCategorySelected,
    required this.onAllCategories,
    required this.onViewAllDeals,
    required this.onViewLaptops,
    required this.onBuildTap,
  });

  final HomeFeed feed;
  final Future<void> Function() onRefresh;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<ProductCategory> onCategorySelected;
  final VoidCallback onAllCategories;
  final VoidCallback onViewAllDeals;
  final VoidCallback onViewLaptops;
  final VoidCallback onBuildTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 26),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'صباح الخير، مصطفى',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 19,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'جاهز تبني جهاز أحلامك بأفضل سعر؟',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                const TagPill(
                  label: 'الدولار اليوم 49.20 ج.م',
                  icon: Icons.trending_up_rounded,
                  background: AppColors.successSoft,
                  foreground: AppColors.success,
                  fontSize: 9,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BuildHeroCard(onTap: onBuildTap),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: 'أقسام القطع والأجهزة',
              subtitle: 'اختار القطعة وابدأ تجميعتك',
              actionLabel: 'عرض الكل',
              onAction: onAllCategories,
            ),
          ),
          const SizedBox(height: 12),
          HomeCategoryRow(
            onCategorySelected: onCategorySelected,
            onAllTap: onAllCategories,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: 'أفضل العروض الحصرية اليوم',
              subtitle: 'أسعار محدثة من 6 متاجر موثوقة',
              actionLabel: 'عرض الكل',
              onAction: onViewAllDeals,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 304,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: feed.deals.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = feed.deals[index];
                return HomeDealCard(
                  product: product,
                  onTap: () => onOpenProduct(product),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TrustStrip(feed: feed),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: 'لابتوبات مختارة لك',
              subtitle: 'بميزانية 65,000 ج.م واهتمامك بالألعاب',
              actionLabel: 'كل اللابتوبات',
              onAction: onViewLaptops,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 166,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: feed.laptops.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = feed.laptops[index];
                return HomeLaptopCard(
                  product: product,
                  onTap: () => onOpenProduct(product),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 19,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'كل سعر له مصدر ووقت تحديث موثق. لا نعرض سعرًا قديمًا كسعر حي.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.5,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      radius: 20,
      child: Row(
        children: [
          _TrustItem(
            icon: Icons.storefront_rounded,
            value: '${feed.verifiedStores} متاجر',
            label: 'موثوقة',
          ),
          const _TrustDivider(),
          _TrustItem(
            icon: Icons.track_changes_rounded,
            value: '12,480',
            label: 'عرض متابع',
          ),
          const _TrustDivider(),
          _TrustItem(
            icon: Icons.sync_rounded,
            value: feed.updatedAt,
            label: 'آخر تحديث',
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: AppColors.line);
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _SkeletonBox(height: 22, width: 150),
        SizedBox(height: 8),
        _SkeletonBox(height: 12, width: 230),
        SizedBox(height: 18),
        _SkeletonBox(height: 214, radius: 26),
        SizedBox(height: 24),
        _SkeletonBox(height: 20, width: 170),
        SizedBox(height: 12),
        Row(
          children: [
            _SkeletonBox(height: 90, width: 76, radius: 20),
            SizedBox(width: 10),
            _SkeletonBox(height: 90, width: 76, radius: 20),
            SizedBox(width: 10),
            _SkeletonBox(height: 90, width: 76, radius: 20),
            SizedBox(width: 10),
            _SkeletonBox(height: 90, width: 76, radius: 20),
          ],
        ),
        SizedBox(height: 26),
        _SkeletonBox(height: 20, width: 200),
        SizedBox(height: 12),
        _SkeletonBox(height: 230, radius: 22),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    this.width = double.infinity,
    this.radius = 10,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
