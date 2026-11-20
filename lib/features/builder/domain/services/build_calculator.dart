import '../../../../core/domain/entities/pc_build.dart';

/// Pure domain rule set for the demo build compatibility engine.
class BuildCalculator {
  const BuildCalculator();

  PcBuild recalculate(Map<ComponentSlot, BuildPart> parts) {
    final warnings = <BuildWarning>[];
    final gpu = parts[ComponentSlot.gpu];
    final psu = parts[ComponentSlot.psu];

    if (gpu != null && psu != null && (psu.wattage ?? 0) < 750) {
      warnings.add(
        BuildWarning(
          id: 'psu-headroom',
          severity: BuildIssueSeverity.warning,
          title: 'تنبيه مقترح من فريق تجميعة',
          message:
              '${gpu.name} يستهلك ${gpu.powerDraw}W ويحتاج مزود طاقة 750W '
              'على الأقل. نوصي بمزود 850W لمساحة أمان أكبر.',
          actionLabel: 'ترقية المزود إلى 850W',
          fixPartId: 'psu-rm850x',
        ),
      );
    }

    if (psu == null) {
      warnings.add(
        const BuildWarning(
          id: 'psu-missing',
          severity: BuildIssueSeverity.info,
          title: 'أضف مزود طاقة',
          message:
              'لم يتم اختيار مزود طاقة بعد. سنحسب الاستهلاك التقديري بمجرد '
              'إضافته إلى التجميعة.',
        ),
      );
    }

    final estimatedWatts =
        35 + parts.values.fold<int>(0, (sum, part) => sum + part.powerDraw);

    final penalty = warnings.fold<int>(0, (sum, warning) {
      return sum +
          switch (warning.severity) {
            BuildIssueSeverity.error => 20,
            BuildIssueSeverity.warning => 6,
            BuildIssueSeverity.info => 2,
          };
    });

    final compatibility = (100 - penalty).clamp(0, 100);
    final psuWatts = psu?.wattage ?? 0;

    return PcBuild(
      parts: Map.unmodifiable(parts),
      warnings: List.unmodifiable(warnings),
      compatibility: compatibility,
      estimatedWatts: estimatedWatts,
      psuWatts: psuWatts,
      isBalanced: warnings.isEmpty && parts.length >= 6,
    );
  }
}
