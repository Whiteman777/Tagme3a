import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../../theme/app_colors.dart';
import '../category_icons.dart';

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({
    super.key,
    required this.product,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.radius = 18,
    this.padding = const EdgeInsets.all(10),
    this.background = const Color(0xFFF7F8FC),
  });

  final Product product;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final image = product.imageAsset;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  product.category.icon,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            )
          : Padding(
              padding: padding,
              child: Image.asset(
                image,
                fit: fit,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    product.category.icon,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
    );
  }
}

class PartArtwork extends StatelessWidget {
  const PartArtwork({
    super.key,
    required this.imageAsset,
    required this.fallbackIcon,
    this.size = 54,
  });

  final String? imageAsset;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageAsset == null
          ? Icon(fallbackIcon, color: AppColors.primary, size: size * 0.45)
          : Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                imageAsset!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  color: AppColors.primary,
                  size: size * 0.45,
                ),
              ),
            ),
    );
  }
}
