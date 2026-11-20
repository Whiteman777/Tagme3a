import 'package:flutter/material.dart';

import '../../../../core/domain/entities/product.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';

class OffersCard extends StatelessWidget {
  const OffersCard({super.key, required this.offers, required this.onOfferTap});

  final List<MerchantOffer> offers;
  final ValueChanged<MerchantOffer> onOfferTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var index = 0; index < offers.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 14, endIndent: 14),
            InkWell(
              onTap: () => onOfferTap(offers[index]),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(index == 0 ? 20 : 0),
                bottom: Radius.circular(index == offers.length - 1 ? 20 : 0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: offers[index].isBest
                            ? AppColors.primary
                            : AppColors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        offers[index].initials,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: offers[index].isBest
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  offers[index].merchant,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (offers[index].isBest) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text(
                                    'الأفضل',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            offers[index].inStock
                                ? 'متوفر · آخر تحقق ${offers[index].lastSeen}'
                                : 'غير متوفر حالياً · ${offers[index].lastSeen}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: offers[index].inStock
                                  ? AppColors.muted
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatEgp(offers[index].price),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: offers[index].inStock
                                ? AppColors.ink
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.chevron_left_rounded,
                          size: 15,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
