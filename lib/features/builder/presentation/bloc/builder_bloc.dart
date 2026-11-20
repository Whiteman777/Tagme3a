import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/pc_build.dart';
import '../../../../core/domain/entities/product_category.dart';
import '../../../../core/presentation/load_status.dart';
import '../../domain/services/build_calculator.dart';
import '../../domain/usecases/get_builder_data.dart';
import 'builder_event.dart';
import 'builder_state.dart';

class BuilderBloc extends Bloc<BuilderEvent, BuilderState> {
  BuilderBloc({
    required GetInitialBuild getInitialBuild,
    required GetBuildOptions getBuildOptions,
    BuildCalculator calculator = const BuildCalculator(),
  }) : _getInitialBuild = getInitialBuild,
       _getBuildOptions = getBuildOptions,
       _calculator = calculator,
       super(const BuilderState()) {
    on<BuilderStarted>(_onStarted);
    on<BuilderPartSelected>(_onPartSelected);
    on<BuilderPartRemoved>(_onPartRemoved);
    on<BuilderWarningFixRequested>(_onWarningFix);
    on<BuilderAutoOptimizeRequested>(_onAutoOptimize);
    on<BuilderProductAdded>(_onProductAdded);
  }

  final GetInitialBuild _getInitialBuild;
  final GetBuildOptions _getBuildOptions;
  final BuildCalculator _calculator;

  Future<void> _onStarted(
    BuilderStarted event,
    Emitter<BuilderState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final initial = await _getInitialBuild();
      final options = await _getBuildOptions();
      emit(
        BuilderState(
          status: LoadStatus.success,
          build: _calculator.recalculate(initial.parts),
          options: options,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: 'تعذر تحميل التجميعة.',
        ),
      );
    }
  }

  void _onPartSelected(BuilderPartSelected event, Emitter<BuilderState> emit) {
    final build = state.build;
    if (build == null) return;
    final parts = Map<ComponentSlot, BuildPart>.from(build.parts)
      ..[event.slot] = event.part;
    emit(
      state.copyWith(
        status: LoadStatus.success,
        build: _calculator.recalculate(parts),
      ),
    );
  }

  void _onPartRemoved(BuilderPartRemoved event, Emitter<BuilderState> emit) {
    final build = state.build;
    if (build == null) return;
    final parts = Map<ComponentSlot, BuildPart>.from(build.parts)
      ..remove(event.slot);
    emit(
      state.copyWith(
        status: LoadStatus.success,
        build: _calculator.recalculate(parts),
      ),
    );
  }

  void _onWarningFix(
    BuilderWarningFixRequested event,
    Emitter<BuilderState> emit,
  ) {
    final build = state.build;
    final fixId = event.warning.fixPartId;
    if (build == null || fixId == null) return;
    BuildPart? fix;
    for (final options in state.options.values) {
      for (final part in options) {
        if (part.id == fixId) fix = part;
      }
    }
    if (fix == null) return;
    final parts = Map<ComponentSlot, BuildPart>.from(build.parts)
      ..[fix.slot] = fix;
    emit(
      state.copyWith(
        build: _calculator.recalculate(parts),
        status: LoadStatus.success,
      ),
    );
  }

  void _onAutoOptimize(
    BuilderAutoOptimizeRequested event,
    Emitter<BuilderState> emit,
  ) {
    final build = state.build;
    if (build == null) return;
    final parts = Map<ComponentSlot, BuildPart>.from(build.parts);
    for (final slot in ComponentSlot.values) {
      if (parts.containsKey(slot)) continue;
      final options = state.options[slot] ?? const <BuildPart>[];
      if (options.isEmpty) continue;
      parts[slot] = options.firstWhere(
        (part) => part.recommended,
        orElse: () => options.first,
      );
    }
    final psu = parts[ComponentSlot.psu];
    final gpu = parts[ComponentSlot.gpu];
    if (gpu != null && psu != null && (psu.wattage ?? 0) < 750) {
      final psuOptions =
          state.options[ComponentSlot.psu] ?? const <BuildPart>[];
      final upgrade = psuOptions.where((part) => (part.wattage ?? 0) >= 850);
      if (upgrade.isNotEmpty) {
        parts[ComponentSlot.psu] = upgrade.first;
      }
    }
    emit(
      state.copyWith(
        build: _calculator.recalculate(parts),
        status: LoadStatus.success,
      ),
    );
  }

  void _onProductAdded(BuilderProductAdded event, Emitter<BuilderState> emit) {
    final build = state.build;
    if (build == null) return;
    final slot = _slotFor(event.product.category);
    if (slot == null) return;
    final part = BuildPart(
      id: event.product.id,
      slot: slot,
      name: event.product.name,
      brand: event.product.brand,
      specLine: event.product.tagline,
      imageAsset: event.product.imageAsset,
      price: event.product.price,
      stores: event.product.stores,
      powerDraw: _powerDrawFor(event.product.category),
      wattage: slot == ComponentSlot.psu ? 850 : null,
      recommended: false,
    );
    final parts = Map<ComponentSlot, BuildPart>.from(build.parts)
      ..[slot] = part;
    emit(
      state.copyWith(
        build: _calculator.recalculate(parts),
        status: LoadStatus.success,
      ),
    );
  }

  ComponentSlot? _slotFor(ProductCategory category) => switch (category) {
    ProductCategory.cpu => ComponentSlot.cpu,
    ProductCategory.gpu => ComponentSlot.gpu,
    ProductCategory.motherboard => ComponentSlot.motherboard,
    ProductCategory.ram => ComponentSlot.ram,
    ProductCategory.psu => ComponentSlot.psu,
    ProductCategory.pcCase => ComponentSlot.pcCase,
    ProductCategory.cooler => ComponentSlot.cooler,
    ProductCategory.storage => ComponentSlot.storage,
    ProductCategory.laptop => null,
  };

  int _powerDrawFor(ProductCategory category) => switch (category) {
    ProductCategory.cpu => 125,
    ProductCategory.gpu => 250,
    ProductCategory.motherboard => 45,
    ProductCategory.ram => 10,
    ProductCategory.psu => 0,
    ProductCategory.pcCase => 0,
    ProductCategory.cooler => 10,
    ProductCategory.storage => 8,
    ProductCategory.laptop => 0,
  };
}
