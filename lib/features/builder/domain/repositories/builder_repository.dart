import '../../../../core/domain/entities/pc_build.dart';

abstract class BuilderRepository {
  Future<PcBuild> getInitialBuild();

  Future<Map<ComponentSlot, List<BuildPart>>> getOptions();
}
