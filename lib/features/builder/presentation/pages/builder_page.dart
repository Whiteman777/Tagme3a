import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/pc_build.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/app_snack.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/page_top_bar.dart';
import '../../../../core/presentation/widgets/product_artwork.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../bloc/builder_bloc.dart';
import '../bloc/builder_event.dart';
import '../bloc/builder_state.dart';

class BuilderPage extends StatelessWidget {
  const BuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageTopBar(
            title: 'جمّع جهازك',
            subtitle: 'قطع متوافقة وأفضل سعر من 6 متاجر',
            actions: [
              CircleIconButton(
                icon: Icons.auto_awesome_rounded,
                tooltip: 'تحسين تلقائي',
                background: AppColors.accent,
                border: false,
                onTap: () {
                  context.read<BuilderBloc>().add(
                    const BuilderAutoOptimizeRequested(),
                  );
                  AppSnack.show(
                    context,
                    'تم تحسين التجميعة تلقائياً وملء القطع الناقصة',
                    icon: Icons.auto_awesome_rounded,
                  );
                },
              ),
              CircleIconButton(
                icon: Icons.share_outlined,
                tooltip: 'مشاركة',
                onTap: () => AppSnack.show(
                  context,
                  'تم إنشاء رابط لمشاركة تجميعتك',
                  icon: Icons.link_rounded,
                ),
              ),
            ],
          ),
          Expanded(
            child: BlocBuilder<BuilderBloc, BuilderState>(
              builder: (context, state) {
                if (state.status == LoadStatus.loading ||
                    state.status == LoadStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.build == null || state.status == LoadStatus.failure) {
                  return EmptyState(
                    icon: Icons.memory_rounded,
                    title: 'تعذر تحميل التجميعة',
                    message: state.errorMessage ?? 'حاول مرة أخرى.',
                    actionLabel: 'إعادة المحاولة',
                    onAction: () =>
                        context.read<BuilderBloc>().add(const BuilderStarted()),
                  );
                }
                return _BuilderContent(
                  build: state.build!,
                  options: state.options,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BuilderContent extends StatelessWidget {
  const _BuilderContent({required PcBuild build, required this.options})
    : pcBuild = build;

  final PcBuild pcBuild;
  final Map<ComponentSlot, List<BuildPart>> options;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      children: [
        _SummaryCard(build: pcBuild),
        const SizedBox(height: 14),
        if (pcBuild.warnings.isEmpty)
          const _BalancedBanner()
        else
          for (final warning in pcBuild.warnings) ...[
            _WarningCard(warning: warning),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'قطع التجميعة',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            TagPill(
              label: '${pcBuild.completedSlots} من ${pcBuild.totalSlots}',
              background: AppColors.softBlue,
              foreground: AppColors.primary,
              fontSize: 9.5,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'اضغط على أي قطعة لتغييرها أو ترقيتها',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        for (final slot in ComponentSlot.values) ...[
          _SlotTile(
            slot: slot,
            part: pcBuild.parts[slot],
            onTap: () => _openPicker(context, slot, pcBuild.parts[slot]),
            onRemove: pcBuild.parts[slot] == null
                ? null
                : () =>
                      context.read<BuilderBloc>().add(BuilderPartRemoved(slot)),
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 10),
        _PowerCard(build: pcBuild),
        const SizedBox(height: 12),
        _CompatibilityCard(build: pcBuild),
        const SizedBox(height: 12),
        SurfaceHint(
          icon: Icons.info_outline_rounded,
          text:
              'الأسعار والاستهلاك تقديرية للنسخة التجريبية. توافق القطع '
              'الحقيقي يحتاج مراجعة المقبس والطول والمنافذ.',
        ),
      ],
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    ComponentSlot slot,
    BuildPart? selected,
  ) {
    final parts = options[slot] ?? const <BuildPart>[];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.74,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _slotIcon(slot),
                          size: 21,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اختر ${slot.label}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'قطع متوافقة مع تجميعتك · أسعار محدثة',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 9.5,
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
                Expanded(
                  child: parts.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'لا توجد خيارات',
                          message: 'لم نجد قطعاً متاحة لهذا القسم حالياً.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                          itemCount: parts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final part = parts[index];
                            final isSelected = selected?.id == part.id;
                            return _PartOption(
                              part: part,
                              selected: isSelected,
                              onTap: () {
                                context.read<BuilderBloc>().add(
                                  BuilderPartSelected(slot: slot, part: part),
                                );
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          },
                        ),
                ),
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: TextButton.icon(
                      onPressed: () {
                        context.read<BuilderBloc>().add(
                          BuilderPartRemoved(slot),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text('إزالة ${slot.label} من التجميعة'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required PcBuild build}) : pcBuild = build;

  final PcBuild pcBuild;

  @override
  Widget build(BuildContext context) {
    final progress = pcBuild.completedSlots / pcBuild.totalSlots;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'تجميعتك الحالية',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TagPill(
                label: '${pcBuild.completedSlots}/${pcBuild.totalSlots} مكتملة',
                icon: Icons.check_circle_outline_rounded,
                background: Colors.white.withValues(alpha: 0.14),
                foreground: Colors.white,
                fontSize: 9,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    formatEgp(pcBuild.total),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'إجمالي القطع',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  icon: Icons.verified_outlined,
                  label: 'التوافق',
                  value: '${pcBuild.compatibility}%',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              Expanded(
                child: _SummaryStat(
                  icon: Icons.bolt_rounded,
                  label: 'الاستهلاك المتوقع',
                  value: '${pcBuild.estimatedWatts}W',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              Expanded(
                child: _SummaryStat(
                  icon: Icons.power_rounded,
                  label: 'مزود الطاقة',
                  value: pcBuild.psuWatts == 0 ? '—' : '${pcBuild.psuWatts}W',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LimeButton(
            label: pcBuild.isComplete ? 'راجع التجميعة' : 'أكمل القطع الناقصة',
            icon: Icons.auto_awesome_rounded,
            expand: true,
            height: 44,
            onPressed: () {
              if (pcBuild.isComplete) {
                AppSnack.show(
                  context,
                  'تجميعتك مكتملة ومتوافقة. جاهز للشراء!',
                  icon: Icons.celebration_rounded,
                );
                return;
              }
              context.read<BuilderBloc>().add(
                const BuilderAutoOptimizeRequested(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 15, color: AppColors.accent),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
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

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning});

  final BuildWarning warning;

  @override
  Widget build(BuildContext context) {
    final isWarning = warning.severity == BuildIssueSeverity.warning;
    final foreground = isWarning ? AppColors.warning : AppColors.primary;
    final background = isWarning ? AppColors.warningSoft : AppColors.softBlue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warning.title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      warning.message,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warning.actionLabel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  context.read<BuilderBloc>().add(
                    BuilderWarningFixRequested(warning),
                  );
                  AppSnack.show(
                    context,
                    'تمت ترقية مزود الطاقة وحل التنبيه',
                    icon: Icons.check_circle_rounded,
                  );
                },
                icon: const Icon(Icons.build_rounded, size: 15),
                label: Text(warning.actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalancedBanner extends StatelessWidget {
  const _BalancedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 19, color: AppColors.success),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تجميعة متوازنة — لا توجد تعارضات أو تنبيهات.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.part,
    required this.onTap,
    required this.onRemove,
  });

  final ComponentSlot slot;
  final BuildPart? part;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final filled = part != null;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? AppColors.line : AppColors.lineStrong,
            ),
          ),
          child: Row(
            children: [
              if (filled)
                PartArtwork(
                  imageAsset: part!.imageAsset,
                  fallbackIcon: _slotIcon(slot),
                  size: 56,
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Icon(
                    _slotIcon(slot),
                    size: 23,
                    color: AppColors.muted,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.softBlue
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            slot.shortLabel,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: filled
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            slot.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        if (part?.recommended ?? false) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 11,
                            color: AppColors.accentDeep,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      part?.name ?? 'أضف ${slot.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: filled ? AppColors.ink : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      part?.specLine ?? 'اختر من القطع المتوافقة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              if (filled) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatEgp(part!.price),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.dangerSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ] else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 17,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartOption extends StatelessWidget {
  const _PartOption({
    required this.part,
    required this.selected,
    required this.onTap,
  });

  final BuildPart part;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.softBlue : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              PartArtwork(
                imageAsset: part.imageAsset,
                fallbackIcon: _slotIcon(part.slot),
                size: 54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            part.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (part.recommended) ...[
                          const SizedBox(width: 5),
                          TagPill(
                            label: 'موصى به',
                            icon: Icons.auto_awesome_rounded,
                            background: AppColors.accentSoft,
                            foreground: AppColors.ink,
                            fontSize: 7.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      part.specLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          formatEgp(part.price),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${part.stores} متاجر',
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
              const SizedBox(width: 6),
              if (selected)
                const Icon(
                  Icons.radio_button_checked_rounded,
                  size: 20,
                  color: AppColors.primary,
                )
              else
                const Icon(
                  Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: AppColors.lineStrong,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({required PcBuild build}) : pcBuild = build;

  final PcBuild pcBuild;

  @override
  Widget build(BuildContext context) {
    final psu = pcBuild.psuWatts;
    final ratio = psu == 0
        ? 0.0
        : (pcBuild.estimatedWatts / psu).clamp(0.0, 1.0);
    final overloaded = psu > 0 && pcBuild.estimatedWatts > psu * 0.85;
    final tone = overloaded ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(
                Icons.electrical_services_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'الطاقة والاستهلاك',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              TagPill(
                label: overloaded ? 'قريب من الحد' : 'آمن',
                background: overloaded
                    ? AppColors.warningSoft
                    : AppColors.successSoft,
                foreground: tone,
                fontSize: 8.5,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${pcBuild.estimatedWatts}W',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'استهلاك تقديري',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              Text(
                psu == 0 ? 'بدون مزود' : 'مزود $psu',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.softBlue,
              valueColor: AlwaysStoppedAnimation(tone),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            psu == 0
                ? 'أضف مزود طاقة لحساب هامش الأمان.'
                : 'هامش الأمان المتاح ${(psu - pcBuild.estimatedWatts).clamp(0, psu)}W '
                      'من أصل $psu.',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({required PcBuild build}) : pcBuild = build;

  final PcBuild pcBuild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pcBuild.compatibility / 100,
                  strokeWidth: 5,
                  backgroundColor: AppColors.softBlue,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text(
                  '${pcBuild.compatibility}%',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توافق القطع',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pcBuild.warnings.isEmpty
                      ? 'كل القطع المختارة تعمل مع بعضها بدون تعارضات.'
                      : 'يوجد ${pcBuild.warnings.length} تنبيه يحتاج مراجعة قبل الشراء.',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.read<NavigationCubit>().select(
              NavigationCubit.storeTab,
            ),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primary,
            tooltip: 'تصفح القطع',
          ),
        ],
      ),
    );
  }
}

class SurfaceHint extends StatelessWidget {
  const SurfaceHint({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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
    );
  }
}

IconData _slotIcon(ComponentSlot slot) => switch (slot) {
  ComponentSlot.cpu => Icons.memory_rounded,
  ComponentSlot.motherboard => Icons.developer_board_rounded,
  ComponentSlot.gpu => Icons.videogame_asset_rounded,
  ComponentSlot.ram => Icons.view_module_rounded,
  ComponentSlot.psu => Icons.bolt_rounded,
  ComponentSlot.pcCase => Icons.computer_rounded,
  ComponentSlot.cooler => Icons.ac_unit_rounded,
  ComponentSlot.storage => Icons.storage_rounded,
};
