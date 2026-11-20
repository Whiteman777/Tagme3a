import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/presentation/load_status.dart';

class ProductState extends Equatable {
  const ProductState({
    this.status = LoadStatus.initial,
    this.product,
    this.errorMessage,
  });

  final LoadStatus status;
  final Product? product;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, product, errorMessage];
}
