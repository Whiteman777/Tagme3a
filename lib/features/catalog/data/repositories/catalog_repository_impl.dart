import '../../../../core/data/mock_catalog_data.dart';
import '../../../../core/domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogMockDataSource {
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List<Product>.unmodifiable(MockCatalogData.products);
  }
}

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._dataSource);

  final CatalogMockDataSource _dataSource;

  @override
  Future<List<Product>> getProducts() => _dataSource.fetchProducts();
}
