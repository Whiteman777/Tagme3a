import 'package:flutter/material.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/widgets/price_text.dart';
import '../../../../core/presentation/widgets/product_artwork.dart';
import '../../../../core/presentation/widgets/surface_card.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class HomeLaptopCard extends StatelessWidget {
  const HomeLaptopCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 164,
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        radius: 22,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TagPill(
                    label: 'ترشيح ذكي',
                    icon: Icons.auto_awesome_rounded,
                    background: AppColors.accentSoft,
                    foreground: AppColors.ink,
                    fontSize: 8.5,
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
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
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      PriceText(value: product.price, size: 15.5),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.storefront_outlined,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product.stores} متاجر',
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
              ),
            ),
            const SizedBox(width: 10),
            ProductArtwork(
              product: product,
              width: 116,
              height: 138,
              radius: 16,
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
      ),
    );
  }
}
