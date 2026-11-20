import 'package:equatable/equatable.dart';

class PriceAlert extends Equatable {
  const PriceAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageAsset,
    required this.currentPrice,
    required this.targetPrice,
    required this.merchant,
    required this.lastChecked,
    required this.enabled,
    required this.dropPercent,
  });

  final String id;
  final String productId;
  final String productName;
  final String? imageAsset;
  final int currentPrice;
  final int targetPrice;
  final String merchant;
  final String lastChecked;
  final bool enabled;
  final int dropPercent;

  PriceAlert copyWith({bool? enabled}) {
    return PriceAlert(
      id: id,
      productId: productId,
      productName: productName,
      imageAsset: imageAsset,
      currentPrice: currentPrice,
      targetPrice: targetPrice,
      merchant: merchant,
      lastChecked: lastChecked,
      enabled: enabled ?? this.enabled,
      dropPercent: dropPercent,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    imageAsset,
    currentPrice,
    targetPrice,
    merchant,
    lastChecked,
    enabled,
    dropPercent,
  ];
}
