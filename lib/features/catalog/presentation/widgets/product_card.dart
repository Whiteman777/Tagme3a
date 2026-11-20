import 'package:flutter/material.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/category_icons.dart';
import '../../../../core/presentation/widgets/price_text.dart';
import '../../../../core/presentation/widgets/product_artwork.dart';
import '../../../../core/presentation/widgets/surface_card.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      radius: 20,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ProductArtwork(
                product: product,
                width: double.infinity,
                height: 112,
                radius: 14,
                padding: const EdgeInsets.all(7),
              ),
              if (product.discountPercent != null)
                PositionedDirectional(
                  top: 7,
                  start: 7,
                  child: DiscountBadge(
                    percent: product.discountPercent!,
                    compact: true,
                  ),
                ),
              PositionedDirectional(
                top: 7,
                end: 7,
                child: TagPill(
                  label: product.category.label,
                  icon: product.category.icon,
                  background: Colors.white.withValues(alpha: 0.92),
                  foreground: AppColors.inkSoft,
                  fontSize: 7.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
              const SizedBox(width: 2),
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              height: 1.4,
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
          const Spacer(),
          PriceText(
            value: product.price,
            oldValue: product.oldPrice,
            size: 15.5,
            oldSize: 9,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 12,
                color: AppColors.muted,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${product.stores} متاجر · ${product.offers.length} عروض',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
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
