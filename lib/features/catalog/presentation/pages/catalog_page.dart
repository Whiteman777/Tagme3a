import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/page_top_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<CatalogBloc>().state.query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatalogBloc, CatalogState>(
      listenWhen: (previous, current) => previous.query != current.query,
      listener: (context, state) {
        if (_searchController.text != state.query) {
          _searchController.value = TextEditingValue(
            text: state.query,
            selection: TextSelection.collapsed(offset: state.query.length),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            PageTopBar(
              title: 'المتجر',
              subtitle: 'أسعار حية من أفضل متاجر مصر',
              actions: [
                CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: '3',
                  onTap: () => Navigator.of(context).push(AppRoutes.alerts()),
                ),
              ],
            ),
            ColoredBox(
              color: AppColors.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (query) => context.read<CatalogBloc>().add(
                            CatalogQueryChanged(query),
                          ),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ابحث بالاسم أو البراند أو القسم...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 21,
                            ),
                            suffixIcon: value.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<CatalogBloc>().add(
                                        const CatalogQueryChanged(''),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  BlocBuilder<CatalogBloc, CatalogState>(
                    buildWhen: (previous, current) =>
                        previous.category != current.category,
                    builder: (context, state) {
                      return CategoryFilterBar(
                        selected: state.category,
                        onSelected: (category) => context
                            .read<CatalogBloc>()
                            .add(CatalogCategorySelected(category)),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading ||
                      state.status == LoadStatus.initial) {
                    return const _CatalogLoading();
                  }
                  if (state.status == LoadStatus.failure) {
                    return EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'تعذر تحميل المتجر',
                      message: state.errorMessage ?? 'حاول مرة أخرى.',
                      actionLabel: 'إعادة المحاولة',
                      onAction: () => context.read<CatalogBloc>().add(
                        const CatalogStarted(),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                        child: Row(
                          children: [
                            Text(
                              '${state.visibleProducts.length} منتج',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            if (state.hasActiveFilters) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => context.read<CatalogBloc>().add(
                                  const CatalogFiltersCleared(),
                                ),
                                child: const Text(
                                  'مسح الفلاتر',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            _SortButton(
                              sort: state.sort,
                              onTap: () => _showSortSheet(context, state.sort),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: state.visibleProducts.isEmpty
                            ? EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'ما لقيناش نتائج',
                                message: 'جرّب اسمًا مختلفًا أو امسح الفلاتر وابدأ من كل المنتجات.',
                                actionLabel: 'مسح الفلاتر',
                                onAction: () => context.read<CatalogBloc>().add(
                                  const CatalogFiltersCleared(),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth > 1050
                                      ? 4
                                      : constraints.maxWidth > 720
                                      ? 3
                                      : 2;
                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      24,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 14,
                                          mainAxisExtent: 290,
                                        ),
                                    itemCount: state.visibleProducts.length,
                                    itemBuilder: (context, index) {
                                      final product =
                                          state.visibleProducts[index];
                                      return ProductCard(
                                        product: product,
                                        onTap: () => Navigator.of(context)
                                            .push(AppRoutes.product(product)),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSortSheet(BuildContext context, CatalogSort current) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lineStrong,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'ترتيب النتائج',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                for (final sort in CatalogSort.values)
                  _SortOption(
                    sort: sort,
                    selected: current == sort,
                    onTap: () {
                      context.read<CatalogBloc>().add(CatalogSortChanged(sort));
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onTap});

  final CatalogSort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.inkSoft),
              SizedBox(width: 4),
              Text(
                'ترتيب',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.sort,
    required this.selected,
    required this.onTap,
  });

  final CatalogSort sort;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (sort) {
      CatalogSort.recommended => ('الأنسب لك', Icons.auto_awesome_rounded),
      CatalogSort.priceLow => ('الأقل سعراً', Icons.south_rounded),
      CatalogSort.priceHigh => ('الأعلى سعراً', Icons.north_rounded),
      CatalogSort.discount => ('أكبر خصم', Icons.percent_rounded),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.softBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.inkSoft,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        mainAxisExtent: 290,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}
