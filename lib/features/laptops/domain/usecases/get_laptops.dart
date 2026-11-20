import '../../../../core/domain/entities/laptop.dart';
import '../repositories/laptops_repository.dart';

class GetLaptops {
  const GetLaptops(this._repository);

  final LaptopsRepository _repository;

  Future<List<Laptop>> call() => _repository.getLaptops();
}
