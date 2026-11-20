import 'package:flutter_test/flutter_test.dart';
import 'package:tagme3a/core/domain/entities/laptop.dart';
import 'package:tagme3a/features/laptops/domain/services/laptop_scorer.dart';

Laptop _laptop({
  required String id,
  required int price,
  required int gamingScore,
  bool inStock = true,
}) {
  return Laptop(
    id: id,
    name: id,
    brand: 'Test',
    imageAsset: 'assets/images/laptop.jpg',
    price: price,
    processor: 'i7',
    gpu: 'RTX 4070',
    ram: '32GB',
    storage: '1TB',
    display: '16" 240Hz',
    rating: 4.8,
    stores: 3,
    inStock: inStock,
    useCases: const [LaptopUseCase.gaming],
    useCaseScores: {
      LaptopUseCase.gaming: gamingScore,
      LaptopUseCase.engineering: 80,
      LaptopUseCase.editing: 80,
      LaptopUseCase.threeD: 80,
      LaptopUseCase.student: 80,
    },
  );
}

void main() {
  group('LaptopScorer', () {
    const scorer = LaptopScorer();
    final laptops = [
      _laptop(id: 'fast', price: 65000, gamingScore: 98),
      _laptop(id: 'value', price: 40000, gamingScore: 90),
      _laptop(id: 'import', price: 60000, gamingScore: 99, inStock: false),
      _laptop(id: 'over-budget', price: 95000, gamingScore: 99),
    ];

    test('filters over-budget and unavailable laptops', () {
      final result = scorer.rank(
        laptops: laptops,
        useCase: LaptopUseCase.gaming,
        budget: 65000,
        localOnly: true,
      );

      expect(result.map((item) => item.laptop.id), isNot(contains('import')));
      expect(
        result.map((item) => item.laptop.id),
        isNot(contains('over-budget')),
      );
      expect(result.first.laptop.id, 'fast');
    });

    test('includes imported laptops when local-only is disabled', () {
      final result = scorer.rank(
        laptops: laptops,
        useCase: LaptopUseCase.gaming,
        budget: 65000,
        localOnly: false,
      );

      expect(result.map((item) => item.laptop.id), contains('import'));
      expect(result, hasLength(3));
    });

    test('returns no matches when the budget is too low', () {
      final result = scorer.rank(
        laptops: laptops,
        useCase: LaptopUseCase.gaming,
        budget: 25000,
        localOnly: true,
      );

      expect(result, isEmpty);
    });
  });
}
