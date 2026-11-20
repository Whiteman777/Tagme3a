import '../../../../core/data/mock_catalog_data.dart';
import '../../../../core/domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductMockDataSource {
  Future<Product> fetchProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final product = MockCatalogData.byId(id);
    if (product == null) {
      throw StateError('Product not found: $id');
    }
    return product;
  }
}

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._dataSource);

  final ProductMockDataSource _dataSource;

  @override
  Future<Product> getProductById(String id) => _dataSource.fetchProduct(id);
}
