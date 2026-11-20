import '../../../../core/domain/entities/price_alert.dart';

abstract class AlertsRepository {
  Future<List<PriceAlert>> getAlerts();
}
