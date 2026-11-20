import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/app_snack.dart';
import '../../../../core/presentation/widgets/brand_wordmark.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final alertsState = context.watch<AlertsBloc>().state;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
          children: [
            _ProfileHeader(alertsCount: alertsState.enabledCount),
            const SizedBox(height: 16),
            _SavedBuildCard(
              onOpen: () => context.read<NavigationCubit>().select(
                NavigationCubit.builderTab,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'وصول سريع',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.85,
              children: [
                _QuickCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'تنبيهات الأسعار',
                  subtitle: '${alertsState.alerts.length} منتجات مرصودة',
                  color: AppColors.primary,
                  background: AppColors.softBlue,
                  onTap: () => Navigator.of(context).push(AppRoutes.alerts()),
                ),
                _QuickCard(
                  icon: Icons.favorite_border_rounded,
                  title: 'المفضلة',
                  subtitle: '7 قطع محفوظة',
                  color: AppColors.danger,
                  background: AppColors.dangerSoft,
                  onTap: () => AppSnack.show(
                    context,
                    'المفضلة هتتوفر في النسخة الكاملة',
                    icon: Icons.favorite_rounded,
                  ),
                ),
                _QuickCard(
                  icon: Icons.compare_arrows_rounded,
                  title: 'المقارنات',
                  subtitle: '3 مقارنات محفوظة',
                  color: AppColors.success,
                  background: AppColors.successSoft,
                  onTap: () => AppSnack.show(
                    context,
                    'قارن حتى 4 منتجات في النسخة الكاملة',
                    icon: Icons.compare_arrows_rounded,
                  ),
                ),
                _QuickCard(
                  icon: Icons.show_chart_rounded,
                  title: 'سجل الأسعار',
                  subtitle: 'تتبع آخر 30 يوم',
                  color: AppColors.warning,
                  background: AppColors.warningSoft,
                  onTap: () => AppSnack.show(
                    context,
                    'سجل الأسعار متاح من صفحة أي منتج',
                    icon: Icons.show_chart_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'الإعدادات',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'بيانات الحساب',
                    subtitle: 'الاسم، البريد، رقم الموبايل',
                    onTap: () => AppSnack.show(
                      context,
                      'تعديل البيانات متاح في النسخة الكاملة',
                      icon: Icons.person_rounded,
                    ),
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 14),
                  _MenuTile(
                    icon: Icons.language_rounded,
                    title: 'اللغة',
                    subtitle: 'العربية (مصر)',
                    onTap: () => AppSnack.show(
                      context,
                      'الواجهة عربية بالكامل — RTL',
                      icon: Icons.language_rounded,
                    ),
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 14),
                  _MenuTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'الإشعارات',
                    subtitle: 'تنبيهات الأسعار والعروض',
                    trailing: TagPill(
                      label: 'مفعّلة',
                      background: AppColors.successSoft,
                      foreground: AppColors.success,
                      fontSize: 8.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(AppRoutes.alerts()),
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 14),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'المساعدة والدعم',
                    subtitle: 'أسئلة شائعة وتواصل معنا',
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) => Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.lineStrong,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Icon(
                                Icons.support_agent_rounded,
                                size: 42,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'إزاي نساعدك؟',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'ده تطبيق تجريبي للواجهات. للدعم الحقيقي '
                                'استخدم بيانات المتجر الرسمية.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11,
                                  height: 1.7,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              LimeButton(
                                label: 'تمام',
                                icon: null,
                                expand: true,
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 14),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'عن تجميعة',
                    subtitle: 'إصدار تجريبي 1.0.0',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'تجميعة',
                      applicationVersion: '1.0.0 (Demo)',
                      applicationLegalese:
                          'نسخة واجهات فقط · بيانات وهمية · بدون باك إند',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => AppSnack.show(
                context,
                'تسجيل الخروج غير مفعّل في النسخة التجريبية',
                icon: Icons.logout_rounded,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: BrandWordmark(
                size: 17,
                tagline: false,
                color: AppColors.muted,
                alignment: CrossAxisAlignment.center,
              ),
            ),
            const SizedBox(height: 5),
            const Center(
              child: Text(
                'نسخة تجريبية · واجهات فقط · بيانات وهمية',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.alertsCount});

  final int alertsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'حسابي',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              CircleIconButton(
                icon: Icons.settings_outlined,
                size: 38,
                iconSize: 18,
                background: Colors.white.withValues(alpha: 0.14),
                foreground: Colors.white,
                border: false,
                tooltip: 'الإعدادات',
                onTap: () => AppSnack.show(
                  context,
                  'الإعدادات متاحة في النسخة الكاملة',
                  icon: Icons.settings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  PositionedDirectional(
                    bottom: -1,
                    end: -1,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مصطفى محمود',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'mostafa@tagme3a.demo',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TagPill(
                      label: 'عضو موثّق منذ 2024',
                      icon: Icons.verified_rounded,
                      background: Colors.white.withValues(alpha: 0.14),
                      foreground: AppColors.accent,
                      fontSize: 8,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(value: '2', label: 'تجميعاتي'),
              _HeaderDivider(),
              _HeaderStat(value: '$alertsCount', label: 'تنبيهات نشطة'),
              _HeaderDivider(),
              const _HeaderStat(value: '7', label: 'مفضلة'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

class _SavedBuildCard extends StatelessWidget {
  const _SavedBuildCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  size: 19,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تجميعة الجيمنج المحفوظة',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'آخر تعديل أمس · 6 من 8 قطع',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatEgp(88000),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TagPill(
                label: 'i7-14700K',
                background: AppColors.background,
                foreground: AppColors.inkSoft,
                fontSize: 8,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
              const SizedBox(width: 5),
              TagPill(
                label: 'RTX 4070 Ti Super',
                background: AppColors.background,
                foreground: AppColors.inkSoft,
                fontSize: 8,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onOpen,
                child: Row(
                  children: [
                    const Text(
                      'فتح التجميعة',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
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
              if (trailing != null) trailing!,
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
