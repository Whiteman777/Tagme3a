import 'package:flutter/material.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/widgets/price_text.dart';
import '../../../../core/presentation/widgets/product_artwork.dart';
import '../../../../core/presentation/widgets/surface_card.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class HomeDealCard extends StatelessWidget {
  const HomeDealCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 252,
      height: 302,
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        radius: 22,
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
                  radius: 15,
                ),
                if (product.discountPercent != null)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: DiscountBadge(percent: product.discountPercent!),
                  ),
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 15,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 2),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              product.tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  value: product.price,
                  oldValue: product.oldPrice,
                  size: 17,
                ),
                const Spacer(),
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 13,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  'متوفر في ${product.stores} متاجر',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
