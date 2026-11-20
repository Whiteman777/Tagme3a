import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/pc_build.dart';
import '../../../../core/domain/entities/product.dart';

abstract class BuilderEvent extends Equatable {
  const BuilderEvent();

  @override
  List<Object?> get props => [];
}

class BuilderStarted extends BuilderEvent {
  const BuilderStarted();
}

class BuilderPartSelected extends BuilderEvent {
  const BuilderPartSelected({required this.slot, required this.part});

  final ComponentSlot slot;
  final BuildPart part;

  @override
  List<Object?> get props => [slot, part];
}

class BuilderPartRemoved extends BuilderEvent {
  const BuilderPartRemoved(this.slot);

  final ComponentSlot slot;

  @override
  List<Object?> get props => [slot];
}

class BuilderWarningFixRequested extends BuilderEvent {
  const BuilderWarningFixRequested(this.warning);

  final BuildWarning warning;

  @override
  List<Object?> get props => [warning];
}

class BuilderAutoOptimizeRequested extends BuilderEvent {
  const BuilderAutoOptimizeRequested();
}

class BuilderProductAdded extends BuilderEvent {
  const BuilderProductAdded(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}
