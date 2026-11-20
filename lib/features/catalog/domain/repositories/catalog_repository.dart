import '../../../../core/domain/entities/product.dart';

abstract class CatalogRepository {
  Future<List<Product>> getProducts();
}
