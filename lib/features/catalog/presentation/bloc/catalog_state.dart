import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/product_category.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/load_status.dart';

enum CatalogSort { recommended, priceLow, priceHigh, discount }

class CatalogState extends Equatable {
  const CatalogState({
    this.status = LoadStatus.initial,
    this.allProducts = const [],
    this.visibleProducts = const [],
    this.query = '',
    this.category,
    this.sort = CatalogSort.recommended,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Product> allProducts;
  final List<Product> visibleProducts;
  final String query;
  final ProductCategory? category;
  final CatalogSort sort;
  final String? errorMessage;

  bool get hasActiveFilters => query.trim().isNotEmpty || category != null;

  CatalogState copyWith({
    LoadStatus? status,
    List<Product>? allProducts,
    List<Product>? visibleProducts,
    String? query,
    ProductCategory? category,
    bool clearCategory = false,
    CatalogSort? sort,
    String? errorMessage,
  }) {
    return CatalogState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      visibleProducts: visibleProducts ?? this.visibleProducts,
      query: query ?? this.query,
      category: clearCategory ? null : category ?? this.category,
      sort: sort ?? this.sort,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allProducts,
    visibleProducts,
    query,
    category,
    sort,
    errorMessage,
  ];
}
