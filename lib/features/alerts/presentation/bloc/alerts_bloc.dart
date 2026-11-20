import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/price_alert.dart';
import '../../../../core/presentation/load_status.dart';
import '../../domain/usecases/get_price_alerts.dart';
import 'alerts_event.dart';
import 'alerts_state.dart';

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({required GetPriceAlerts getPriceAlerts})
    : _getPriceAlerts = getPriceAlerts,
      super(const AlertsState()) {
    on<AlertsStarted>(_onStarted);
    on<AlertToggled>(_onToggled);
    on<AlertDeleted>(_onDeleted);
    on<AlertsAllToggled>(_onAllToggled);
    on<AlertAddedForProduct>(_onAdded);
  }

  final GetPriceAlerts _getPriceAlerts;

  Future<void> _onStarted(
    AlertsStarted event,
    Emitter<AlertsState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    try {
      final alerts = await _getPriceAlerts();
      emit(AlertsState(status: LoadStatus.success, alerts: alerts));
    } catch (_) {
      emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: 'تعذر تحميل التنبيهات.',
        ),
      );
    }
  }

  void _onToggled(AlertToggled event, Emitter<AlertsState> emit) {
    final next = [
      for (final alert in state.alerts)
        if (alert.id == event.id)
          alert.copyWith(enabled: event.enabled)
        else
          alert,
    ];
    emit(state.copyWith(alerts: next, status: LoadStatus.success));
  }

  void _onDeleted(AlertDeleted event, Emitter<AlertsState> emit) {
    final next = state.alerts.where((alert) => alert.id != event.id).toList();
    emit(state.copyWith(alerts: next, status: LoadStatus.success));
  }

  void _onAllToggled(AlertsAllToggled event, Emitter<AlertsState> emit) {
    final next = [
      for (final alert in state.alerts) alert.copyWith(enabled: event.enabled),
    ];
    emit(state.copyWith(alerts: next, status: LoadStatus.success));
  }

  void _onAdded(AlertAddedForProduct event, Emitter<AlertsState> emit) {
    final product = event.product;
    if (state.alerts.any((alert) => alert.productId == product.id)) return;
    final alert = PriceAlert(
      id: 'alert-${product.id}-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      imageAsset: product.imageAsset,
      currentPrice: product.price,
      targetPrice: (product.price * 0.95).round(),
      merchant: product.offers.isNotEmpty
          ? product.offers.first.merchant
          : 'أفضل متجر',
      lastChecked: 'الآن',
      enabled: true,
      dropPercent: 5,
    );
    emit(
      state.copyWith(
        alerts: [alert, ...state.alerts],
        status: LoadStatus.success,
      ),
    );
  }
}
