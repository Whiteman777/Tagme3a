import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/pc_build.dart';
import '../../../../core/presentation/load_status.dart';

class BuilderState extends Equatable {
  const BuilderState({
    this.status = LoadStatus.initial,
    this.build,
    this.options = const {},
    this.errorMessage,
  });

  final LoadStatus status;
  final PcBuild? build;
  final Map<ComponentSlot, List<BuildPart>> options;
  final String? errorMessage;

  bool get isReady => build != null;

  BuilderState copyWith({
    LoadStatus? status,
    PcBuild? build,
    Map<ComponentSlot, List<BuildPart>>? options,
    String? errorMessage,
  }) {
    return BuilderState(
      status: status ?? this.status,
      build: build ?? this.build,
      options: options ?? this.options,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, build, options, errorMessage];
}
