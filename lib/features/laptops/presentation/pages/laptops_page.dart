import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/laptop.dart';
import '../../../../core/presentation/load_status.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/page_top_bar.dart';
import '../../../../core/presentation/widgets/tag_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../bloc/laptops_bloc.dart';
import '../bloc/laptops_event.dart';
import '../bloc/laptops_state.dart';
import '../widgets/laptop_recommendation_card.dart';
import 'laptop_details_screen.dart';

class LaptopsPage extends StatelessWidget {
  const LaptopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageTopBar(
            title: 'لابتوبك المناسب',
            subtitle: 'ترشيحات ذكية حسب استخدامك وميزانيتك',
            actions: [
              CircleIconButton(
                icon: Icons.compare_arrows_rounded,
                tooltip: 'المقارنة',
                onTap: () {},
              ),
            ],
          ),
          Expanded(
            child: BlocBuilder<LaptopsBloc, LaptopsState>(
              builder: (context, state) {
                if (state.status == LoadStatus.loading ||
                    state.status == LoadStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == LoadStatus.failure) {
                  return EmptyState(
                    icon: Icons.laptop_mac_rounded,
                    title: 'تعذر تحميل اللابتوبات',
                    message: state.errorMessage ?? 'حاول مرة أخرى.',
                    actionLabel: 'إعادة المحاولة',
                    onAction: () =>
                        context.read<LaptopsBloc>().add(const LaptopsStarted()),
                  );
                }
                return _LaptopsContent(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LaptopsContent extends StatelessWidget {
  const _LaptopsContent({required this.state});

  final LaptopsState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      children: [
        _FilterCard(state: state),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'أفضل اختيارات لك',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 7),
            TagPill(
              label: '${state.recommendations.length}',
              background: AppColors.softBlue,
              foreground: AppColors.primary,
              fontSize: 9.5,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            ),
            const Spacer(),
            Text(
              'مرتبة حسب التطابق',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.muted.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.recommendations.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'ما فيش لابتوب مطابق',
            message:
                'جرّب ترفع الميزانية شوية أو تختار استخدام مختلف، أو تلغي '
                'فلتر المتوفر محلياً.',
            actionLabel: 'إعادة ضبط الفلاتر',
            onAction: () {
              context.read<LaptopsBloc>()
                ..add(const LaptopBudgetChanged(65000))
                ..add(const LaptopUseCaseChanged(LaptopUseCase.gaming))
                ..add(const LaptopLocalOnlyToggled(true));
            },
          )
        else
          for (
            var index = 0;
            index < state.recommendations.length;
            index++
          ) ...[
            LaptopRecommendationCard(
              recommendation: state.recommendations[index],
              rank: index + 1,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => LaptopDetailsScreen(
                    recommendation: state.recommendations[index],
                    useCase: state.useCase,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الترشيحات مبنية على الأداء في استخدامك، التوفر المحلي، '
                  'وسعر مقابل الميزانية. الأسعار استرشادية.',
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

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.state});

  final LaptopsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قولنا بتستخدمه في إيه؟',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'هنرتب لك أفضل الموديلات المناسبة',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final useCase in LaptopUseCase.values)
                _UseCaseChip(
                  useCase: useCase,
                  active: state.useCase == useCase,
                  onTap: () => context.read<LaptopsBloc>().add(
                    LaptopUseCaseChanged(useCase),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'ميزانيتك',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const Spacer(),
              Text(
                formatEgp(state.budget),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: state.budget.toDouble(),
            min: 25000,
            max: 100000,
            divisions: 30,
            onChanged: (value) => context.read<LaptopsBloc>().add(
              LaptopBudgetChanged(value.round()),
            ),
          ),
          Row(
            children: [
              Text(
                '25,000 ج.م',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted.withValues(alpha: 0.95),
                ),
              ),
              const Spacer(),
              Text(
                '100,000 ج.م',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المتوفر محلياً فقط',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'بدون انتظار الاستيراد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.localOnly,
                  onChanged: (value) => context.read<LaptopsBloc>().add(
                    LaptopLocalOnlyToggled(value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UseCaseChip extends StatelessWidget {
  const _UseCaseChip({
    required this.useCase,
    required this.active,
    required this.onTap,
  });

  final LaptopUseCase useCase;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.line,
            ),
          ),
          child: Text(
            useCase.label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
