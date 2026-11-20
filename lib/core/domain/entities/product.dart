import 'package:equatable/equatable.dart';

import 'product_category.dart';

class MerchantOffer extends Equatable {
  const MerchantOffer({
    required this.merchant,
    required this.price,
    required this.inStock,
    required this.lastSeen,
    this.isBest = false,
  });

  final String merchant;
  final int price;
  final bool inStock;
  final String lastSeen;
  final bool isBest;

  String get initials {
    final clean = merchant.trim();
    if (clean.isEmpty) return '؟';
    return clean.substring(0, clean.length >= 2 ? 2 : 1);
  }

  @override
  List<Object?> get props => [merchant, price, inStock, lastSeen, isBest];
}

class PricePoint extends Equatable {
  const PricePoint({required this.day, required this.price});

  final int day;
  final int price;

  @override
  List<Object?> get props => [day, price];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.tagline,
    required this.description,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.stores,
    this.imageAsset,
    this.oldPrice,
    this.badges = const [],
    this.highlights = const [],
    this.offers = const [],
    this.priceHistory = const [],
    this.low30d,
    this.high30d,
    this.change30dPercent,
    this.inStock = true,
  });

  final String id;
  final String name;
  final String brand;
  final ProductCategory category;
  final String tagline;
  final String description;
  final String? imageAsset;
  final int price;
  final int? oldPrice;
  final double rating;
  final int reviews;
  final int stores;
  final List<String> badges;
  final List<String> highlights;
  final List<MerchantOffer> offers;
  final List<PricePoint> priceHistory;
  final int? low30d;
  final int? high30d;
  final int? change30dPercent;
  final bool inStock;

  int? get discountPercent {
    final previous = oldPrice;
    if (previous == null || previous <= price) return null;
    return ((previous - price) / previous * 100).round();
  }

  bool get isLaptop => category.isLaptop;

  int get lowestOffer {
    if (offers.isEmpty) return price;
    return offers.map((offer) => offer.price).reduce((a, b) => a < b ? a : b);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    category,
    tagline,
    description,
    imageAsset,
    price,
    oldPrice,
    rating,
    reviews,
    stores,
    badges,
    highlights,
    offers,
    priceHistory,
    low30d,
    high30d,
    change30dPercent,
    inStock,
  ];
}
