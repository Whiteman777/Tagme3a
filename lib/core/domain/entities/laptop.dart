import 'package:equatable/equatable.dart';

enum LaptopUseCase {
  gaming('الألعاب'),
  engineering('الهندسة'),
  editing('المونتاج'),
  threeD('التصميم 3D'),
  student('الدراسة');

  const LaptopUseCase(this.label);

  final String label;
}

class Laptop extends Equatable {
  const Laptop({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageAsset,
    required this.price,
    required this.processor,
    required this.gpu,
    required this.ram,
    required this.storage,
    required this.display,
    required this.rating,
    required this.stores,
    required this.inStock,
    required this.useCases,
    required this.useCaseScores,
    this.oldPrice,
  });

  final String id;
  final String name;
  final String brand;
  final String imageAsset;
  final int price;
  final int? oldPrice;
  final String processor;
  final String gpu;
  final String ram;
  final String storage;
  final String display;
  final double rating;
  final int stores;
  final bool inStock;
  final List<LaptopUseCase> useCases;
  final Map<LaptopUseCase, int> useCaseScores;

  List<String> get specChips => [processor, gpu, ram, storage, display];

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    imageAsset,
    price,
    oldPrice,
    processor,
    gpu,
    ram,
    storage,
    display,
    rating,
    stores,
    inStock,
    useCases,
    useCaseScores,
  ];
}

class LaptopRecommendation extends Equatable {
  const LaptopRecommendation({
    required this.laptop,
    required this.matchPercent,
    required this.reasons,
  });

  final Laptop laptop;
  final int matchPercent;
  final List<String> reasons;

  @override
  List<Object?> get props => [laptop, matchPercent, reasons];
}
