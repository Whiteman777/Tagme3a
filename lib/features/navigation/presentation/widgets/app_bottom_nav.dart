import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/navigation_cubit.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

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
        child: SizedBox(
          height: 74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'الرئيسية',
                      selected: selectedIndex == NavigationCubit.homeTab,
                      onTap: () => onSelected(NavigationCubit.homeTab),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront_rounded,
                      label: 'المتجر',
                      selected: selectedIndex == NavigationCubit.storeTab,
                      onTap: () => onSelected(NavigationCubit.storeTab),
                    ),
                  ),
                  const SizedBox(width: 148),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.laptop_mac_outlined,
                      activeIcon: Icons.laptop_mac_rounded,
                      label: 'اللابتوب',
                      selected: selectedIndex == NavigationCubit.laptopsTab,
                      onTap: () => onSelected(NavigationCubit.laptopsTab),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'حسابي',
                      selected: selectedIndex == NavigationCubit.accountTab,
                      onTap: () => onSelected(NavigationCubit.accountTab),
                    ),
                  ),
                ],
              ),
              _BuilderButton(
                selected: selectedIndex == NavigationCubit.builderTab,
                onTap: () => onSelected(NavigationCubit.builderTab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 27,
            decoration: BoxDecoration(
              color: selected ? AppColors.softBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(selected ? activeIcon : icon, size: 21, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.5,
              height: 1.4,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuilderButton extends StatelessWidget {
  const _BuilderButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.accentDeep,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory_rounded, size: 19, color: AppColors.ink),
              const SizedBox(width: 7),
              Text(
                'جمّع جهازك',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.3,
                  decoration: selected ? TextDecoration.none : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
