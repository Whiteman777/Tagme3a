import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductRequested extends ProductEvent {
  const ProductRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}
