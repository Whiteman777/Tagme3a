import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/laptop.dart';

abstract class LaptopsEvent extends Equatable {
  const LaptopsEvent();

  @override
  List<Object?> get props => [];
}

class LaptopsStarted extends LaptopsEvent {
  const LaptopsStarted();
}

class LaptopUseCaseChanged extends LaptopsEvent {
  const LaptopUseCaseChanged(this.useCase);

  final LaptopUseCase useCase;

  @override
  List<Object?> get props => [useCase];
}

class LaptopBudgetChanged extends LaptopsEvent {
  const LaptopBudgetChanged(this.budget);

  final int budget;

  @override
  List<Object?> get props => [budget];
}

class LaptopLocalOnlyToggled extends LaptopsEvent {
  const LaptopLocalOnlyToggled(this.localOnly);

  final bool localOnly;

  @override
  List<Object?> get props => [localOnly];
}
