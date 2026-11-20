import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/load_status.dart';
import '../../domain/usecases/get_product_details.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({required GetProductDetails getProductDetails})
    : _getProductDetails = getProductDetails,
      super(const ProductState()) {
    on<ProductRequested>(_onRequested);
  }

  final GetProductDetails _getProductDetails;

  Future<void> _onRequested(
    ProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductState(status: LoadStatus.loading));
    try {
      final product = await _getProductDetails(event.productId);
      emit(ProductState(status: LoadStatus.success, product: product));
    } catch (_) {
      emit(
        const ProductState(
          status: LoadStatus.failure,
          errorMessage: 'تعذر تحميل تفاصيل المنتج.',
        ),
      );
    }
  }
}
