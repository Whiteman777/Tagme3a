import '../../../../core/domain/entities/laptop.dart';

abstract class LaptopsRepository {
  Future<List<Laptop>> getLaptops();
}
