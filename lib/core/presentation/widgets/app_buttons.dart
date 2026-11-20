import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 20,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.border = true,
    this.badge,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final bool border;
  final String? badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: border
                  ? const BorderSide(color: AppColors.line)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: Center(
                child: Icon(icon, size: iconSize, color: foreground),
              ),
            ),
          ),
          if (badge != null)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 8.5,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class LimeButton extends StatelessWidget {
  const LimeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_back_rounded,
    this.height = 48,
    this.expand = false,
    this.fontSize = 13.5,
    this.background = AppColors.accent,
    this.foreground = AppColors.ink,
    this.showShadow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expand;
  final double fontSize;
  final Color background;
  final Color foreground;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: background.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
    if (!expand) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}

class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 48,
    this.background = AppColors.softBlue,
    this.foreground = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!expand) return content;
    return SizedBox(width: double.infinity, child: content);
  }
}
