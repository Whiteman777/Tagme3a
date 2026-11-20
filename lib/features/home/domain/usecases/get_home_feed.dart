import '../../../../core/domain/entities/home_feed.dart';
import '../repositories/home_repository.dart';

class GetHomeFeed {
  const GetHomeFeed(this._repository);

  final HomeRepository _repository;

  Future<HomeFeed> call() => _repository.getHomeFeed();
}
