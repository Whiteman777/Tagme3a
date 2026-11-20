import 'package:equatable/equatable.dart';

enum ComponentSlot { cpu, motherboard, gpu, ram, psu, pcCase, cooler, storage }

extension ComponentSlotX on ComponentSlot {
  String get label => switch (this) {
    ComponentSlot.cpu => 'المعالج',
    ComponentSlot.motherboard => 'اللوحة الأم',
    ComponentSlot.gpu => 'كارت الشاشة',
    ComponentSlot.ram => 'الرامات',
    ComponentSlot.psu => 'مزود الطاقة',
    ComponentSlot.pcCase => 'الصندوق',
    ComponentSlot.cooler => 'التبريد',
    ComponentSlot.storage => 'التخزين',
  };

  String get shortLabel => switch (this) {
    ComponentSlot.cpu => 'CPU',
    ComponentSlot.motherboard => 'Motherboard',
    ComponentSlot.gpu => 'GPU',
    ComponentSlot.ram => 'RAM',
    ComponentSlot.psu => 'PSU',
    ComponentSlot.pcCase => 'Case',
    ComponentSlot.cooler => 'Cooler',
    ComponentSlot.storage => 'Storage',
  };
}

class BuildPart extends Equatable {
  const BuildPart({
    required this.id,
    required this.slot,
    required this.name,
    required this.brand,
    required this.specLine,
    required this.price,
    required this.stores,
    required this.powerDraw,
    this.imageAsset,
    this.compatible = true,
    this.wattage,
    this.recommended = false,
    this.note,
  });

  final String id;
  final ComponentSlot slot;
  final String name;
  final String brand;
  final String specLine;
  final String? imageAsset;
  final int price;
  final int stores;
  final int powerDraw;
  final int? wattage;
  final bool compatible;
  final bool recommended;
  final String? note;

  @override
  List<Object?> get props => [
    id,
    slot,
    name,
    brand,
    specLine,
    imageAsset,
    price,
    stores,
    powerDraw,
    wattage,
    compatible,
    recommended,
    note,
  ];
}

enum BuildIssueSeverity { info, warning, error }

class BuildWarning extends Equatable {
  const BuildWarning({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    this.actionLabel,
    this.fixPartId,
  });

  final String id;
  final BuildIssueSeverity severity;
  final String title;
  final String message;
  final String? actionLabel;
  final String? fixPartId;

  @override
  List<Object?> get props => [
    id,
    severity,
    title,
    message,
    actionLabel,
    fixPartId,
  ];
}

class PcBuild extends Equatable {
  const PcBuild({
    required this.parts,
    required this.warnings,
    required this.compatibility,
    required this.estimatedWatts,
    required this.psuWatts,
    this.isBalanced = false,
  });

  final Map<ComponentSlot, BuildPart> parts;
  final List<BuildWarning> warnings;
  final int compatibility;
  final int estimatedWatts;
  final int psuWatts;
  final bool isBalanced;

  int get total => parts.values.fold(0, (sum, part) => sum + part.price);

  int get completedSlots => parts.length;

  int get totalSlots => ComponentSlot.values.length;

  bool get isComplete => parts.length == ComponentSlot.values.length;

  PcBuild copyWith({
    Map<ComponentSlot, BuildPart>? parts,
    List<BuildWarning>? warnings,
    int? compatibility,
    int? estimatedWatts,
    int? psuWatts,
    bool? isBalanced,
  }) {
    return PcBuild(
      parts: parts ?? this.parts,
      warnings: warnings ?? this.warnings,
      compatibility: compatibility ?? this.compatibility,
      estimatedWatts: estimatedWatts ?? this.estimatedWatts,
      psuWatts: psuWatts ?? this.psuWatts,
      isBalanced: isBalanced ?? this.isBalanced,
    );
  }

  @override
  List<Object?> get props => [
    parts,
    warnings,
    compatibility,
    estimatedWatts,
    psuWatts,
    isBalanced,
  ];
}
