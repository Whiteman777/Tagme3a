import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/product_category.dart';
import '../../../../core/presentation/category_icons.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/price_text.dart';
import '../../../../core/presentation/widgets/product_artwork.dart';
import '../../../../core/presentation/widgets/surface_card.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  static const _popularSearches = [
    'RTX 4070',
    'Intel Core i7',
    'DDR5',
    'لابتوب ألعاب',
    'ASUS TUF',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<CatalogBloc>().state;
    _controller = TextEditingController(text: state.query);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    context.read<CatalogBloc>().add(CatalogQueryChanged(query));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatalogBloc, CatalogState>(
      listenWhen: (previous, current) => previous.query != current.query,
      listener: (context, state) {
        if (_controller.text != state.query) {
          _controller.value = TextEditingValue(
            text: state.query,
            selection: TextSelection.collapsed(offset: state.query.length),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              color: AppColors.surface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_forward_rounded,
                        tooltip: 'رجوع',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
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
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن قطعة أو لابتوب...',
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final query = state.query.trim();
                  if (query.isEmpty) {
                    return _SearchSuggestions(
                      popularSearches: _popularSearches,
                      trending: state.allProducts
                          .where((product) => product.rating >= 4.7)
                          .take(4)
                          .toList(),
                      onSearch: _search,
                      onCategory: (category) => _search(category.label),
                      onOpenProduct: (product) =>
                          Navigator.of(context)
                              .push(AppRoutes.product(product)),
                    );
                  }
                  if (state.visibleProducts.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'ما لقيناش نتائج لـ "$query"',
                      message: 'جرّب اسم موديل مختلف، أو ابحث باسم البراند أو القسم.',
                      actionLabel: 'مسح البحث',
                      onAction: () => _search(''),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: state.visibleProducts.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Row(
                          children: [
                            Text(
                              'نتائج البحث',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            TagPill(
                              label: '${state.visibleProducts.length}',
                              background: AppColors.softBlue,
                              foreground: AppColors.primary,
                              fontSize: 9.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                            ),
                          ],
                        );
                      }
                      final product = state.visibleProducts[index - 1];
                      return _SearchResultTile(
                        product: product,
                        onTap: () =>
                            Navigator.of(context)
                                .push(AppRoutes.product(product)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({
    required this.popularSearches,
    required this.trending,
    required this.onSearch,
    required this.onCategory,
    required this.onOpenProduct,
  });

  final List<String> popularSearches;
  final List<Product> trending;
  final ValueChanged<String> onSearch;
  final ValueChanged<ProductCategory> onCategory;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Text(
          'الأكثر بحثاً هذا الأسبوع',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final term in popularSearches)
              _SuggestionChip(
                label: term,
                icon: Icons.search_rounded,
                onTap: () => onSearch(term),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'تصفح حسب القسم',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in [
              ProductCategory.cpu,
              ProductCategory.gpu,
              ProductCategory.motherboard,
              ProductCategory.ram,
              ProductCategory.storage,
              ProductCategory.laptop,
            ])
              _SuggestionChip(
                label: category.label,
                icon: category.icon,
                onTap: () => onCategory(category),
              ),
          ],
        ),
        if (trending.isNotEmpty) ...[
          const SizedBox(height: 26),
          const Text(
            'الأكثر رواجاً الآن',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final product in trending) ...[
            _SearchResultTile(
              product: product,
              onTap: () => onOpenProduct(product),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          ProductArtwork(
            product: product,
            width: 82,
            height: 82,
            radius: 13,
            padding: const EdgeInsets.all(5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(value: product.price, size: 14, oldSize: 9),
              const SizedBox(height: 5),
              const Icon(
                Icons.chevron_left_rounded,
                size: 17,
                color: AppColors.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
