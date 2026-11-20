import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/load_status.dart';
import '../../domain/usecases/get_catalog_products.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({required GetCatalogProducts getCatalogProducts})
    : _getCatalogProducts = getCatalogProducts,
      super(const CatalogState()) {
    on<CatalogStarted>(_onStarted);
    on<CatalogQueryChanged>(_onQueryChanged);
    on<CatalogCategorySelected>(_onCategorySelected);
    on<CatalogSortChanged>(_onSortChanged);
    on<CatalogFiltersCleared>(_onFiltersCleared);
  }

  final GetCatalogProducts _getCatalogProducts;

  Future<void> _onStarted(
    CatalogStarted event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    try {
      final products = await _getCatalogProducts();
      emit(
        state.copyWith(
          status: LoadStatus.success,
          allProducts: products,
          visibleProducts: _applyFilters(products, state),
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: 'تعذر تحميل المنتجات. حاول مرة أخرى.',
        ),
      );
    }
  }

  void _onQueryChanged(CatalogQueryChanged event, Emitter<CatalogState> emit) {
    final next = state.copyWith(query: event.query);
    emit(
      next.copyWith(visibleProducts: _applyFilters(state.allProducts, next)),
    );
  }

  void _onCategorySelected(
    CatalogCategorySelected event,
    Emitter<CatalogState> emit,
  ) {
    final next = state.copyWith(
      category: event.category,
      clearCategory: event.category == null,
      query: '',
    );
    emit(
      next.copyWith(visibleProducts: _applyFilters(state.allProducts, next)),
    );
  }

  void _onSortChanged(CatalogSortChanged event, Emitter<CatalogState> emit) {
    final next = state.copyWith(sort: event.sort);
    emit(
      next.copyWith(visibleProducts: _applyFilters(state.allProducts, next)),
    );
  }

  void _onFiltersCleared(
    CatalogFiltersCleared event,
    Emitter<CatalogState> emit,
  ) {
    final next = state.copyWith(
      query: '',
      category: null,
      clearCategory: true,
      sort: CatalogSort.recommended,
    );
    emit(
      next.copyWith(visibleProducts: _applyFilters(state.allProducts, next)),
    );
  }

  List<Product> _applyFilters(List<Product> products, CatalogState filters) {
    final query = filters.query.trim().toLowerCase();
    var result = products.where((product) {
      final matchesCategory =
          filters.category == null || product.category == filters.category;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      final haystack = [
        product.name,
        product.brand,
        product.tagline,
        product.category.label,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    switch (filters.sort) {
      case CatalogSort.recommended:
        break;
      case CatalogSort.priceLow:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CatalogSort.priceHigh:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CatalogSort.discount:
        result.sort(
          (a, b) => (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0),
        );
        break;
    }
    return List<Product>.unmodifiable(result);
  }
}
