import '../../../../core/domain/entities/pc_build.dart';
import '../repositories/builder_repository.dart';

class GetInitialBuild {
  const GetInitialBuild(this._repository);

  final BuilderRepository _repository;

  Future<PcBuild> call() => _repository.getInitialBuild();
}

class GetBuildOptions {
  const GetBuildOptions(this._repository);

  final BuilderRepository _repository;

  Future<Map<ComponentSlot, List<BuildPart>>> call() =>
      _repository.getOptions();
}
