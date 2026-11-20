import 'package:flutter_test/flutter_test.dart';
import 'package:tagme3a/core/domain/entities/pc_build.dart';
import 'package:tagme3a/features/builder/domain/services/build_calculator.dart';

BuildPart _part({
  required ComponentSlot slot,
  required String id,
  required int price,
  int powerDraw = 0,
  int? wattage,
}) {
  return BuildPart(
    id: id,
    slot: slot,
    name: id,
    brand: 'Test',
    specLine: 'spec',
    price: price,
    stores: 3,
    powerDraw: powerDraw,
    wattage: wattage,
  );
}

void main() {
  group('BuildCalculator', () {
    const calculator = BuildCalculator();

    test('flags an underpowered PSU and reports estimated wattage', () {
      final build = calculator.recalculate({
        ComponentSlot.cpu: _part(
          slot: ComponentSlot.cpu,
          id: 'cpu',
          price: 19450,
          powerDraw: 125,
        ),
        ComponentSlot.gpu: _part(
          slot: ComponentSlot.gpu,
          id: 'gpu',
          price: 41200,
          powerDraw: 285,
        ),
        ComponentSlot.psu: _part(
          slot: ComponentSlot.psu,
          id: 'psu650',
          price: 4250,
          wattage: 650,
        ),
      });

      expect(build.psuWatts, 650);
      expect(build.estimatedWatts, 35 + 125 + 285);
      expect(build.warnings, hasLength(1));
      expect(build.warnings.single.id, 'psu-headroom');
      expect(build.warnings.single.fixPartId, 'psu-rm850x');
      expect(build.compatibility, 94);
      expect(build.isBalanced, isFalse);
    });

    test('clears the warning when an 850W PSU is used', () {
      final build = calculator.recalculate({
        ComponentSlot.cpu: _part(
          slot: ComponentSlot.cpu,
          id: 'cpu',
          price: 19450,
          powerDraw: 125,
        ),
        ComponentSlot.gpu: _part(
          slot: ComponentSlot.gpu,
          id: 'gpu',
          price: 41200,
          powerDraw: 250,
        ),
        ComponentSlot.psu: _part(
          slot: ComponentSlot.psu,
          id: 'psu850',
          price: 6950,
          wattage: 850,
        ),
      });

      expect(build.warnings, isEmpty);
      expect(build.compatibility, 100);
      expect(build.isBalanced, isFalse);
      expect(build.total, 19450 + 41200 + 6950);
    });

    test('asks for a PSU when none is selected', () {
      final build = calculator.recalculate({
        ComponentSlot.cpu: _part(
          slot: ComponentSlot.cpu,
          id: 'cpu',
          price: 19450,
          powerDraw: 125,
        ),
      });

      expect(build.psuWatts, 0);
      expect(build.warnings, hasLength(1));
      expect(build.warnings.single.id, 'psu-missing');
      expect(build.compatibility, 98);
    });
  });
}
