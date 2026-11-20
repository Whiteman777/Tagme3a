import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/domain/entities/price_alert.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/app_snack.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/page_top_bar.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../catalog/presentation/bloc/catalog_bloc.dart';
import '../bloc/alerts_bloc.dart';
import '../bloc/alerts_event.dart';
import '../bloc/alerts_state.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageTopBar(
            title: 'تنبيهات الأسعار',
            subtitle: 'هنقولك أول ما السعر ينزل لهدفك',
            leading: CircleIconButton(
              icon: Icons.arrow_forward_rounded,
              tooltip: 'رجوع',
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'التنبيهات',
                onTap: () => AppSnack.show(
                  context,
                  'كل التنبيهات بتوصلك على الإشعارات',
                  icon: Icons.notifications_active_rounded,
                ),
              ),
            ],
          ),
          Expanded(
            child: BlocBuilder<AlertsBloc, AlertsState>(
              builder: (context, state) {
                if (state.status == LoadStatus.loading ||
                    state.status == LoadStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == LoadStatus.failure) {
                  return EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'تعذر تحميل التنبيهات',
                    message: state.errorMessage ?? 'حاول مرة أخرى.',
                    actionLabel: 'إعادة المحاولة',
                    onAction: () =>
                        context.read<AlertsBloc>().add(const AlertsStarted()),
                  );
                }
                return _AlertsContent(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsContent extends StatelessWidget {
  const _AlertsContent({required this.state});

  final AlertsState state;

  @override
  Widget build(BuildContext context) {
    if (state.alerts.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'مفيش تنبيهات لسه',
        message:
            'افتح أي منتج واضغط على جرس التنبيه، وإحنا هنرصد السعر ونبلغك '
            'أول ما ينزل.',
        actionLabel: 'تصفح المنتجات',
        onAction: () => Navigator.of(context).pop(),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      children: [
        _AlertsSummary(state: state),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text(
              'تنبيهاتك',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 7),
            TagPill(
              label: '${state.enabledCount} مفعّل',
              background: AppColors.successSoft,
              foreground: AppColors.success,
              fontSize: 9,
            ),
            const Spacer(),
            Text(
              'إجمالي ${state.alerts.length}',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final alert in state.alerts) ...[
          _AlertCard(alert: alert),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'بنراجع الأسعار كل 15 دقيقة من المتاجر الموثوقة. التنبيه '
                  'بيوصلك بمجرد وصول السعر لهدفك.',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertsSummary extends StatelessWidget {
  const _AlertsSummary({required this.state});

  final AlertsState state;

  @override
  Widget build(BuildContext context) {
    final allEnabled =
        state.alerts.isNotEmpty && state.enabledCount == state.alerts.length;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 19,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'رصد ذكي على مدار الساعة',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              TagPill(
                label: allEnabled ? 'الكل مفعّل' : 'مفعّل جزئياً',
                background: Colors.white.withValues(alpha: 0.14),
                foreground: Colors.white,
                fontSize: 8.5,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryStat(value: '${state.enabledCount}', label: 'تنبيه نشط'),
              const SizedBox(width: 24),
              _SummaryStat(
                value: '${state.alerts.length}',
                label: 'منتج مرصود',
              ),
              const SizedBox(width: 24),
              const _SummaryStat(value: '4,600', label: 'وفر محتمل ج.م'),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  allEnabled
                      ? 'كل التنبيهات شغالة. هنبلغك فور نزول السعر.'
                      : 'في تنبيهات متوقفة. شغّلها عشان متفوّتش العرض.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  context.read<AlertsBloc>().add(AlertsAllToggled(!allEnabled));
                  AppSnack.show(
                    context,
                    !allEnabled
                        ? 'تم تفعيل كل التنبيهات'
                        : 'تم إيقاف كل التنبيهات مؤقتاً',
                    icon: Icons.notifications_rounded,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    allEnabled ? 'إيقاف الكل' : 'تفعيل الكل',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final PriceAlert alert;

  @override
  Widget build(BuildContext context) {
    final remaining = (alert.currentPrice - alert.targetPrice).clamp(0, 999999);
    final progress = alert.currentPrice == 0
        ? 0.0
        : (alert.targetPrice / alert.currentPrice).clamp(0.0, 1.0);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: alert.enabled ? 1 : 0.62,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: alert.enabled
                ? AppColors.line
                : AppColors.lineStrong.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: alert.imageAsset == null
                        ? const Icon(
                            Icons.memory_rounded,
                            size: 28,
                            color: AppColors.primary,
                          )
                        : Image.asset(
                            alert.imageAsset!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.memory_rounded,
                                  size: 28,
                                  color: AppColors.primary,
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openProduct(context, alert),
                        child: Text(
                          alert.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            formatEgp(alert.currentPrice),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'هدفك ${formatEgp(alert.targetPrice)}',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 11,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              alert.merchant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.muted.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            alert.lastChecked,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: alert.enabled,
                  onChanged: (value) => context.read<AlertsBloc>().add(
                    AlertToggled(alert.id, value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        remaining == 0
                            ? 'السعر وصل لهدفك 🎉'
                            : 'فاضل ${formatEgp(remaining)} للهدف',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: remaining == 0
                              ? AppColors.success
                              : AppColors.inkSoft,
                        ),
                      ),
                      const Spacer(),
                      TagPill(
                        label: 'انخفض ${alert.dropPercent}%',
                        icon: Icons.south_east_rounded,
                        background: AppColors.successSoft,
                        foreground: AppColors.success,
                        fontSize: 8,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openProduct(context, alert),
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('عرض المنتج'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.read<AlertsBloc>().add(AlertDeleted(alert.id));
                    AppSnack.show(
                      context,
                      'تم حذف تنبيه ${alert.productName}',
                      icon: Icons.delete_outline_rounded,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  label: const Text(
                    'حذف',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openProduct(BuildContext context, PriceAlert alert) {
    final products = context.read<CatalogBloc>().state.allProducts;
    Product? match;
    for (final product in products) {
      if (product.id == alert.productId) {
        match = product;
        break;
      }
    }
    if (match == null) {
      AppSnack.show(
        context,
        'تفاصيل المنتج غير متاحة في النسخة التجريبية',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    Navigator.of(context).push(AppRoutes.product(match));
  }
}
