import '../../../../core/constants/app_assets.dart';
import '../../../../core/domain/entities/laptop.dart';
import '../../domain/repositories/laptops_repository.dart';

class LaptopsMockDataSource {
  Future<List<Laptop>> fetchLaptops() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _laptops;
  }

  static const List<Laptop> _laptops = [
    Laptop(
      id: 'laptop-legion-pro-5',
      name: 'Lenovo Legion Pro 5 16IRX9',
      brand: 'Lenovo',
      imageAsset: AppAssets.laptop,
      price: 65000,
      oldPrice: 69999,
      processor: 'i7-14700HX',
      gpu: 'RTX 4070 8GB',
      ram: '32GB DDR5',
      storage: '1TB NVMe',
      display: '16" 2.5K 240Hz',
      rating: 4.8,
      stores: 4,
      inStock: true,
      useCases: [
        LaptopUseCase.gaming,
        LaptopUseCase.engineering,
        LaptopUseCase.editing,
        LaptopUseCase.threeD,
      ],
      useCaseScores: {
        LaptopUseCase.gaming: 98,
        LaptopUseCase.engineering: 94,
        LaptopUseCase.editing: 93,
        LaptopUseCase.threeD: 95,
        LaptopUseCase.student: 78,
      },
    ),
    Laptop(
      id: 'laptop-hp-victus-15',
      name: 'HP Victus 15',
      brand: 'HP',
      imageAsset: AppAssets.laptop,
      price: 39999,
      oldPrice: 43999,
      processor: 'i5-13420H',
      gpu: 'RTX 4060 8GB',
      ram: '16GB DDR5',
      storage: '512GB NVMe',
      display: '15.6" FHD 144Hz',
      rating: 4.5,
      stores: 5,
      inStock: true,
      useCases: [LaptopUseCase.gaming, LaptopUseCase.student],
      useCaseScores: {
        LaptopUseCase.gaming: 90,
        LaptopUseCase.engineering: 82,
        LaptopUseCase.editing: 84,
        LaptopUseCase.threeD: 76,
        LaptopUseCase.student: 94,
      },
    ),
    Laptop(
      id: 'laptop-rog-zephyrus-g14',
      name: 'ASUS ROG Zephyrus G14',
      brand: 'ASUS',
      imageAsset: AppAssets.laptop,
      price: 82500,
      processor: 'Ryzen 9 8945HS',
      gpu: 'RTX 4070 8GB',
      ram: '32GB DDR5',
      storage: '1TB NVMe',
      display: '14" OLED 120Hz',
      rating: 4.9,
      stores: 3,
      inStock: true,
      useCases: [
        LaptopUseCase.gaming,
        LaptopUseCase.engineering,
        LaptopUseCase.editing,
        LaptopUseCase.threeD,
      ],
      useCaseScores: {
        LaptopUseCase.gaming: 94,
        LaptopUseCase.engineering: 89,
        LaptopUseCase.editing: 96,
        LaptopUseCase.threeD: 92,
        LaptopUseCase.student: 72,
      },
    ),
    Laptop(
      id: 'laptop-msi-thin-15',
      name: 'MSI Thin 15 B13V',
      brand: 'MSI',
      imageAsset: AppAssets.laptop,
      price: 45900,
      oldPrice: 48900,
      processor: 'i5-12450H',
      gpu: 'RTX 4050 6GB',
      ram: '16GB DDR4',
      storage: '512GB NVMe',
      display: '15.6" FHD 144Hz',
      rating: 4.4,
      stores: 4,
      inStock: true,
      useCases: [LaptopUseCase.gaming, LaptopUseCase.student],
      useCaseScores: {
        LaptopUseCase.gaming: 86,
        LaptopUseCase.engineering: 78,
        LaptopUseCase.editing: 80,
        LaptopUseCase.threeD: 74,
        LaptopUseCase.student: 90,
      },
    ),
    Laptop(
      id: 'laptop-dell-xps-15',
      name: 'Dell XPS 15',
      brand: 'Dell',
      imageAsset: AppAssets.laptop,
      price: 74000,
      processor: 'i7-13700H',
      gpu: 'RTX 4050 6GB',
      ram: '16GB DDR5',
      storage: '512GB NVMe',
      display: '15.6" OLED 60Hz',
      rating: 4.7,
      stores: 2,
      inStock: false,
      useCases: [
        LaptopUseCase.engineering,
        LaptopUseCase.editing,
        LaptopUseCase.student,
      ],
      useCaseScores: {
        LaptopUseCase.gaming: 74,
        LaptopUseCase.engineering: 94,
        LaptopUseCase.editing: 92,
        LaptopUseCase.threeD: 86,
        LaptopUseCase.student: 88,
      },
    ),
  ];
}

class LaptopsRepositoryImpl implements LaptopsRepository {
  const LaptopsRepositoryImpl(this._dataSource);

  final LaptopsMockDataSource _dataSource;

  @override
  Future<List<Laptop>> getLaptops() => _dataSource.fetchLaptops();
}
