import '../../../../core/domain/entities/laptop.dart';

/// Ranks laptops for a use case and budget using the per-model profile.
class LaptopScorer {
  const LaptopScorer();

  List<LaptopRecommendation> rank({
    required List<Laptop> laptops,
    required LaptopUseCase useCase,
    required int budget,
    required bool localOnly,
  }) {
    final candidates = laptops.where((laptop) {
      if (localOnly && !laptop.inStock) return false;
      return laptop.price <= budget;
    }).toList();

    final scored = candidates.map((laptop) {
      final profileScore = laptop.useCaseScores[useCase] ?? 70;
      final inStockBonus = laptop.inStock ? 2 : -8;
      final valueBonus = laptop.price <= budget * 0.85 ? 3 : 0;
      final match = (profileScore + inStockBonus + valueBonus).clamp(40, 99);
      return LaptopRecommendation(
        laptop: laptop,
        matchPercent: match,
        reasons: _reasons(laptop, useCase, budget),
      );
    }).toList();

    scored.sort((a, b) {
      final match = b.matchPercent.compareTo(a.matchPercent);
      if (match != 0) return match;
      return a.laptop.price.compareTo(b.laptop.price);
    });
    return scored;
  }

  List<String> _reasons(Laptop laptop, LaptopUseCase useCase, int budget) {
    final reasons = <String>[];
    switch (useCase) {
      case LaptopUseCase.gaming:
        reasons.add('أداء ألعاب قوي مع ${laptop.gpu}');
        if (laptop.display.contains('240Hz') ||
            laptop.display.contains('144Hz')) {
          reasons.add('شاشة عالية التحديث مناسبة للألعاب');
        }
        break;
      case LaptopUseCase.engineering:
        reasons.add('معالج ${laptop.processor} للبرامج الهندسية');
        reasons.add('${laptop.ram} لفتح المشاريع الكبيرة');
        break;
      case LaptopUseCase.editing:
        reasons.add('مناسب للمونتاج مع ${laptop.gpu}');
        reasons.add('شاشة ${laptop.display} بألوان دقيقة');
        break;
      case LaptopUseCase.threeD:
        reasons.add('ذاكرة ${laptop.ram} لرندر المشاهد');
        reasons.add('${laptop.gpu} لتسريع التصميم ثلاثي الأبعاد');
        break;
      case LaptopUseCase.student:
        reasons.add('سعر مناسب للدراسة والاستخدام اليومي');
        reasons.add('خفيف ومتوازن في الأداء');
        break;
    }
    if (laptop.inStock) {
      reasons.add('متوفر محلياً بدون انتظار الاستيراد');
    }
    if (laptop.price <= budget * 0.85) {
      reasons.add('أقل من ميزانيتك وبهوامش توفير');
    }
    return reasons.take(3).toList();
  }
}
