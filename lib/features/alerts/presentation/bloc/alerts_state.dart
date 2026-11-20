import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/price_alert.dart';
import '../../../../core/presentation/load_status.dart';

class AlertsState extends Equatable {
  const AlertsState({
    this.status = LoadStatus.initial,
    this.alerts = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<PriceAlert> alerts;
  final String? errorMessage;

  int get enabledCount => alerts.where((alert) => alert.enabled).length;

  AlertsState copyWith({
    LoadStatus? status,
    List<PriceAlert>? alerts,
    String? errorMessage,
  }) {
    return AlertsState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, alerts, errorMessage];
}
