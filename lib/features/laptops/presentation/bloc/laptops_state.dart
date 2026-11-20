import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/laptop.dart';
import '../../../../core/presentation/load_status.dart';

class LaptopsState extends Equatable {
  const LaptopsState({
    this.status = LoadStatus.initial,
    this.allLaptops = const [],
    this.recommendations = const [],
    this.useCase = LaptopUseCase.gaming,
    this.budget = 65000,
    this.localOnly = true,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Laptop> allLaptops;
  final List<LaptopRecommendation> recommendations;
  final LaptopUseCase useCase;
  final int budget;
  final bool localOnly;
  final String? errorMessage;

  LaptopsState copyWith({
    LoadStatus? status,
    List<Laptop>? allLaptops,
    List<LaptopRecommendation>? recommendations,
    LaptopUseCase? useCase,
    int? budget,
    bool? localOnly,
    String? errorMessage,
  }) {
    return LaptopsState(
      status: status ?? this.status,
      allLaptops: allLaptops ?? this.allLaptops,
      recommendations: recommendations ?? this.recommendations,
      useCase: useCase ?? this.useCase,
      budget: budget ?? this.budget,
      localOnly: localOnly ?? this.localOnly,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allLaptops,
    recommendations,
    useCase,
    budget,
    localOnly,
    errorMessage,
  ];
}
