import 'package:flutter/material.dart';

import '../../../../core/domain/entities/product_category.dart';
import '../../../../core/presentation/category_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  static const _categories = [
    ProductCategory.cpu,
    ProductCategory.gpu,
    ProductCategory.motherboard,
    ProductCategory.ram,
    ProductCategory.storage,
    ProductCategory.psu,
    ProductCategory.cooler,
    ProductCategory.pcCase,
    ProductCategory.laptop,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterPill(
              label: 'الكل',
              icon: Icons.grid_view_rounded,
              active: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final category = _categories[index - 1];
          return _FilterPill(
            label: category.label,
            icon: category.icon,
            active: selected == category,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : AppColors.inkSoft;
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
