import '../../../../core/constants/app_assets.dart';
import '../../../../core/domain/entities/price_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

class AlertsMockDataSource {
  Future<List<PriceAlert>> fetchAlerts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      PriceAlert(
        id: 'alert-gpu',
        productId: 'gpu-rtx-4070-ti-super',
        productName: 'NVIDIA GeForce RTX 4070 Ti Super',
        imageAsset: AppAssets.gpu,
        currentPrice: 41200,
        targetPrice: 39000,
        merchant: 'مول البستان',
        lastChecked: 'منذ 12 دقيقة',
        enabled: true,
        dropPercent: 11,
      ),
      PriceAlert(
        id: 'alert-cpu',
        productId: 'cpu-i7-14700k',
        productName: 'Intel Core i7-14700K',
        imageAsset: AppAssets.cpu,
        currentPrice: 19450,
        targetPrice: 18000,
        merchant: 'النهضة تكنولوجي',
        lastChecked: 'منذ 24 دقيقة',
        enabled: true,
        dropPercent: 9,
      ),
      PriceAlert(
        id: 'alert-ram',
        productId: 'ram-vengeance-ddr5-32',
        productName: 'Corsair Vengeance DDR5 32GB',
        imageAsset: AppAssets.ram,
        currentPrice: 5400,
        targetPrice: 4900,
        merchant: 'سوق البلد',
        lastChecked: 'منذ 38 دقيقة',
        enabled: true,
        dropPercent: 12,
      ),
      PriceAlert(
        id: 'alert-laptop',
        productId: 'laptop-legion-pro-5',
        productName: 'Lenovo Legion Pro 5 16IRX9',
        imageAsset: AppAssets.laptop,
        currentPrice: 65000,
        targetPrice: 60000,
        merchant: 'مول البستان',
        lastChecked: 'منذ 55 دقيقة',
        enabled: false,
        dropPercent: 7,
      ),
    ];
  }
}

class AlertsRepositoryImpl implements AlertsRepository {
  const AlertsRepositoryImpl(this._dataSource);

  final AlertsMockDataSource _dataSource;

  @override
  Future<List<PriceAlert>> getAlerts() => _dataSource.fetchAlerts();
}
