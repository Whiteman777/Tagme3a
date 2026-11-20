import '../../../../core/domain/entities/product.dart';
import '../repositories/catalog_repository.dart';

class GetCatalogProducts {
  const GetCatalogProducts(this._repository);

  final CatalogRepository _repository;

  Future<List<Product>> call() => _repository.getProducts();
}
