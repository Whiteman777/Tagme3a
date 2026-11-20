import '../../../../core/domain/entities/price_alert.dart';
import '../repositories/alerts_repository.dart';

class GetPriceAlerts {
  const GetPriceAlerts(this._repository);

  final AlertsRepository _repository;

  Future<List<PriceAlert>> call() => _repository.getAlerts();
}
