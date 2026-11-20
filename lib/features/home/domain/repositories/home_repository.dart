import '../../../../core/domain/entities/home_feed.dart';

abstract class HomeRepository {
  Future<HomeFeed> getHomeFeed();
}
