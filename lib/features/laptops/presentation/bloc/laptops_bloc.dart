import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/laptop.dart';
import '../../../../core/presentation/load_status.dart';
import '../../domain/services/laptop_scorer.dart';
import '../../domain/usecases/get_laptops.dart';
import 'laptops_event.dart';
import 'laptops_state.dart';

class LaptopsBloc extends Bloc<LaptopsEvent, LaptopsState> {
  LaptopsBloc({
    required GetLaptops getLaptops,
    LaptopScorer scorer = const LaptopScorer(),
  }) : _getLaptops = getLaptops,
       _scorer = scorer,
       super(const LaptopsState()) {
    on<LaptopsStarted>(_onStarted);
    on<LaptopUseCaseChanged>(_onUseCaseChanged);
    on<LaptopBudgetChanged>(_onBudgetChanged);
    on<LaptopLocalOnlyToggled>(_onLocalOnlyToggled);
  }

  final GetLaptops _getLaptops;
  final LaptopScorer _scorer;

  Future<void> _onStarted(
    LaptopsStarted event,
    Emitter<LaptopsState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    try {
      final laptops = await _getLaptops();
      emit(
        state.copyWith(
          status: LoadStatus.success,
          allLaptops: laptops,
          recommendations: _rank(laptops, state),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: 'تعذر تحميل ترشيحات اللابتوبات.',
        ),
      );
    }
  }

  void _onUseCaseChanged(
    LaptopUseCaseChanged event,
    Emitter<LaptopsState> emit,
  ) {
    final next = state.copyWith(useCase: event.useCase);
    emit(next.copyWith(recommendations: _rank(state.allLaptops, next)));
  }

  void _onBudgetChanged(LaptopBudgetChanged event, Emitter<LaptopsState> emit) {
    final budget = event.budget.clamp(25000, 100000);
    final next = state.copyWith(budget: budget);
    emit(next.copyWith(recommendations: _rank(state.allLaptops, next)));
  }

  void _onLocalOnlyToggled(
    LaptopLocalOnlyToggled event,
    Emitter<LaptopsState> emit,
  ) {
    final next = state.copyWith(localOnly: event.localOnly);
    emit(next.copyWith(recommendations: _rank(state.allLaptops, next)));
  }

  List<LaptopRecommendation> _rank(List<Laptop> laptops, LaptopsState filters) {
    return _scorer.rank(
      laptops: laptops,
      useCase: filters.useCase,
      budget: filters.budget,
      localOnly: filters.localOnly,
    );
  }
}
