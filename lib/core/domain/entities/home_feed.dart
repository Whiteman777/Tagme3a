import 'package:equatable/equatable.dart';

import 'product.dart';

class HomeFeed extends Equatable {
  const HomeFeed({
    required this.deals,
    required this.laptops,
    required this.trending,
    required this.updatedAt,
    required this.trackedOffers,
    required this.verifiedStores,
  });

  final List<Product> deals;
  final List<Product> laptops;
  final List<Product> trending;
  final String updatedAt;
  final int trackedOffers;
  final int verifiedStores;

  @override
  List<Object?> get props => [
    deals,
    laptops,
    trending,
    updatedAt,
    trackedOffers,
    verifiedStores,
  ];
}
