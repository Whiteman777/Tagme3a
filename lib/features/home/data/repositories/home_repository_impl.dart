import '../../../../core/data/mock_catalog_data.dart';
import '../../../../core/domain/entities/home_feed.dart';
import '../../domain/repositories/home_repository.dart';

class HomeMockDataSource {
  Future<HomeFeed> fetchFeed() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final deals = MockCatalogData.deals.take(4).toList(growable: false);
    final laptops = MockCatalogData.laptops.take(3).toList(growable: false);
    final trending = MockCatalogData.products
        .where((product) => !product.category.isLaptop && product.stores >= 4)
        .take(4)
        .toList(growable: false);
    return HomeFeed(
      deals: deals,
      laptops: laptops,
      trending: trending,
      updatedAt: 'منذ 12 دقيقة',
      trackedOffers: 12480,
      verifiedStores: 6,
    );
  }
}

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dataSource);

  final HomeMockDataSource _dataSource;

  @override
  Future<HomeFeed> getHomeFeed() => _dataSource.fetchFeed();
}
