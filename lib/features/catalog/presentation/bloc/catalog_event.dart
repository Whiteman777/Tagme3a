import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/product_category.dart';
import 'catalog_state.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class CatalogStarted extends CatalogEvent {
  const CatalogStarted();
}

class CatalogQueryChanged extends CatalogEvent {
  const CatalogQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class CatalogCategorySelected extends CatalogEvent {
  const CatalogCategorySelected(this.category);

  final ProductCategory? category;

  @override
  List<Object?> get props => [category];
}

class CatalogSortChanged extends CatalogEvent {
  const CatalogSortChanged(this.sort);

  final CatalogSort sort;

  @override
  List<Object?> get props => [sort];
}

class CatalogFiltersCleared extends CatalogEvent {
  const CatalogFiltersCleared();
}
