import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/product.dart';

abstract class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

class AlertsStarted extends AlertsEvent {
  const AlertsStarted();
}

class AlertToggled extends AlertsEvent {
  const AlertToggled(this.id, this.enabled);

  final String id;
  final bool enabled;

  @override
  List<Object?> get props => [id, enabled];
}

class AlertDeleted extends AlertsEvent {
  const AlertDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class AlertsAllToggled extends AlertsEvent {
  const AlertsAllToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class AlertAddedForProduct extends AlertsEvent {
  const AlertAddedForProduct(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}
