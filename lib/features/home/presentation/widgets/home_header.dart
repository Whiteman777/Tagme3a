import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/brand_wordmark.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onSearchTap,
    required this.onAlertsTap,
    required this.onProfileTap,
    required this.onFilterTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            children: [
              Row(
                children: [
                  const BrandWordmark(size: 25),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap,
                    tooltip: 'البحث',
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: onAlertsTap,
                    badge: '3',
                    tooltip: 'التنبيهات',
                  ),
                  const SizedBox(width: 8),
                  _ProfileAvatar(onTap: onProfileTap),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 21,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'ابحث عن معالج، كارت شاشة، لابتوب أو متجر',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: AppColors.line),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onFilterTap,
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF375DFF), Color(0xFF0F1E5C)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
