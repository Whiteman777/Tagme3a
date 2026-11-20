import '../../../../core/constants/app_assets.dart';
import '../../../../core/domain/entities/pc_build.dart';
import '../../domain/repositories/builder_repository.dart';

class BuilderMockDataSource {
  Future<PcBuild> fetchInitialBuild() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return PcBuild(
      parts: Map.unmodifiable({
        ComponentSlot.cpu: _cpuI7,
        ComponentSlot.motherboard: _moboAsus,
        ComponentSlot.gpu: _gpu4070,
        ComponentSlot.ram: _ramCorsair,
        ComponentSlot.psu: _psu650,
        ComponentSlot.storage: _storage1tb,
      }),
      warnings: const [],
      compatibility: 100,
      estimatedWatts: 0,
      psuWatts: 0,
    );
  }

  Future<Map<ComponentSlot, List<BuildPart>>> fetchOptions() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return {
      for (final slot in ComponentSlot.values)
        slot: List<BuildPart>.unmodifiable(_options[slot] ?? const []),
    };
  }

  static const _cpuI7 = BuildPart(
    id: 'cpu-i7-14700k',
    slot: ComponentSlot.cpu,
    name: 'Intel Core i7-14700K',
    brand: 'Intel',
    specLine: '20 نواة • 5.6GHz • LGA1700',
    imageAsset: AppAssets.cpu,
    price: 19450,
    stores: 6,
    powerDraw: 125,
    recommended: true,
  );

  static const _cpuI5 = BuildPart(
    id: 'cpu-i5-14600k',
    slot: ComponentSlot.cpu,
    name: 'Intel Core i5-14600K',
    brand: 'Intel',
    specLine: '14 نواة • 5.3GHz • LGA1700',
    imageAsset: AppAssets.cpu,
    price: 15500,
    stores: 5,
    powerDraw: 110,
  );

  static const _moboAsus = BuildPart(
    id: 'mobo-asus-z790',
    slot: ComponentSlot.motherboard,
    name: 'ASUS TUF Gaming Z790-Plus',
    brand: 'ASUS',
    specLine: 'DDR5 • PCIe 5.0 • WiFi 6E',
    imageAsset: AppAssets.motherboard,
    price: 12800,
    stores: 4,
    powerDraw: 45,
    recommended: true,
  );

  static const _moboMsi = BuildPart(
    id: 'mobo-msi-b760',
    slot: ComponentSlot.motherboard,
    name: 'MSI PRO B760M-A',
    brand: 'MSI',
    specLine: 'DDR5 • PCIe 4.0 • mATX',
    imageAsset: AppAssets.motherboard,
    price: 8950,
    stores: 5,
    powerDraw: 40,
  );

  static const _gpu4070 = BuildPart(
    id: 'gpu-rtx-4070-ti-super',
    slot: ComponentSlot.gpu,
    name: 'RTX 4070 Ti Super',
    brand: 'NVIDIA',
    specLine: '16GB GDDR6X • DLSS 3.5',
    imageAsset: AppAssets.gpu,
    price: 41200,
    stores: 6,
    powerDraw: 285,
    recommended: true,
  );

  static const _gpu4060 = BuildPart(
    id: 'gpu-rtx-4060-ti',
    slot: ComponentSlot.gpu,
    name: 'RTX 4060 Ti',
    brand: 'NVIDIA',
    specLine: '8GB GDDR6 • DLSS 3',
    imageAsset: AppAssets.gpu,
    price: 24500,
    stores: 5,
    powerDraw: 160,
  );

  static const _ramCorsair = BuildPart(
    id: 'ram-corsair-32',
    slot: ComponentSlot.ram,
    name: 'Corsair Vengeance DDR5 32GB',
    brand: 'Corsair',
    specLine: '2×16GB • 6000MT/s • RGB',
    imageAsset: AppAssets.ram,
    price: 5400,
    stores: 5,
    powerDraw: 10,
    recommended: true,
  );

  static const _ramKingston = BuildPart(
    id: 'ram-kingston-16',
    slot: ComponentSlot.ram,
    name: 'Kingston Fury Beast 16GB',
    brand: 'Kingston',
    specLine: '2×8GB • 5600MT/s',
    imageAsset: AppAssets.ram,
    price: 2950,
    stores: 4,
    powerDraw: 6,
  );

  static const _psu650 = BuildPart(
    id: 'psu-rm650x',
    slot: ComponentSlot.psu,
    name: 'Corsair RM650x',
    brand: 'Corsair',
    specLine: '650W • 80+ Gold • Full Modular',
    price: 4250,
    stores: 3,
    powerDraw: 0,
    wattage: 650,
  );

  static const _psu850 = BuildPart(
    id: 'psu-rm850x',
    slot: ComponentSlot.psu,
    name: 'Corsair RM850x',
    brand: 'Corsair',
    specLine: '850W • 80+ Gold • ATX 3.0',
    price: 6950,
    stores: 3,
    powerDraw: 0,
    wattage: 850,
    recommended: true,
  );

  static const _psu1000 = BuildPart(
    id: 'psu-rm1000x',
    slot: ComponentSlot.psu,
    name: 'Corsair RM1000x',
    brand: 'Corsair',
    specLine: '1000W • 80+ Gold • ATX 3.0',
    price: 9800,
    stores: 2,
    powerDraw: 0,
    wattage: 1000,
  );

  static const _caseNzxt = BuildPart(
    id: 'case-nzxt-h7',
    slot: ComponentSlot.pcCase,
    name: 'NZXT H7 Flow',
    brand: 'NZXT',
    specLine: 'Mid Tower • Airflow • زجاج',
    imageAsset: AppAssets.pcCase,
    price: 4800,
    stores: 4,
    powerDraw: 0,
    recommended: true,
  );

  static const _caseLian = BuildPart(
    id: 'case-lian-lancool',
    slot: ComponentSlot.pcCase,
    name: 'Lian Li Lancool 216',
    brand: 'Lian Li',
    specLine: 'Mid Tower • Airflow • ARGB',
    imageAsset: AppAssets.pcCase,
    price: 3900,
    stores: 3,
    powerDraw: 0,
  );

  static const _coolerDeepcool = BuildPart(
    id: 'cooler-lt720',
    slot: ComponentSlot.cooler,
    name: 'DeepCool LT720 360 AIO',
    brand: 'DeepCool',
    specLine: '360mm • ARGB • 3100RPM',
    price: 5600,
    stores: 3,
    powerDraw: 12,
    recommended: true,
  );

  static const _coolerAir = BuildPart(
    id: 'cooler-hyper-212',
    slot: ComponentSlot.cooler,
    name: 'Cooler Master Hyper 212',
    brand: 'Cooler Master',
    specLine: 'مبرد هوائي • 4 أنابيب حرارية',
    price: 1800,
    stores: 5,
    powerDraw: 8,
  );

  static const _storage1tb = BuildPart(
    id: 'storage-980-1tb',
    slot: ComponentSlot.storage,
    name: 'Samsung 980 NVMe 1TB',
    brand: 'Samsung',
    specLine: 'PCIe 3.0 • 3500MB/s',
    price: 4900,
    stores: 6,
    powerDraw: 8,
  );

  static const _storage2tb = BuildPart(
    id: 'storage-990-pro-2tb',
    slot: ComponentSlot.storage,
    name: 'Samsung 990 PRO 2TB',
    brand: 'Samsung',
    specLine: 'PCIe 4.0 • 7450MB/s',
    price: 8900,
    stores: 6,
    powerDraw: 9,
    recommended: true,
  );

  static final Map<ComponentSlot, List<BuildPart>> _options = {
    ComponentSlot.cpu: [_cpuI7, _cpuI5],
    ComponentSlot.motherboard: [_moboAsus, _moboMsi],
    ComponentSlot.gpu: [_gpu4070, _gpu4060],
    ComponentSlot.ram: [_ramCorsair, _ramKingston],
    ComponentSlot.psu: [_psu850, _psu650, _psu1000],
    ComponentSlot.pcCase: [_caseNzxt, _caseLian],
    ComponentSlot.cooler: [_coolerDeepcool, _coolerAir],
    ComponentSlot.storage: [_storage2tb, _storage1tb],
  };
}

class BuilderRepositoryImpl implements BuilderRepository {
  const BuilderRepositoryImpl(this._dataSource);

  final BuilderMockDataSource _dataSource;

  @override
  Future<PcBuild> getInitialBuild() => _dataSource.fetchInitialBuild();

  @override
  Future<Map<ComponentSlot, List<BuildPart>>> getOptions() =>
      _dataSource.fetchOptions();
}
