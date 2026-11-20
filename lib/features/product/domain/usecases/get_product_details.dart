import '../../../../core/domain/entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductDetails {
  const GetProductDetails(this._repository);

  final ProductRepository _repository;

  Future<Product> call(String id) => _repository.getProductById(id);
}
