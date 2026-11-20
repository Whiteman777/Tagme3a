import '../constants/app_assets.dart';
import '../domain/entities/product.dart';
import '../domain/entities/product_category.dart';

/// Seed data for the no-backend demo.
///
/// In production this layer is replaced by a remote data source + DTO mappers.
abstract final class MockCatalogData {
  static final List<Product> products = [
    Product(
      id: 'gpu-rtx-4070-ti-super',
      name: 'NVIDIA GeForce RTX 4070 Ti Super',
      brand: 'NVIDIA',
      category: ProductCategory.gpu,
      tagline: '16GB GDDR6X • DLSS 3.5 • Ada Lovelace',
      description:
          'كارت شاشة مخصص للألعاب بدقة 1440p والتصميم الاحترافي. يقدم أداءً '
          'استثنائياً مع تقنيات الذكاء الاصطناعي من الجيل الرابع وذاكرة 16GB.',
      imageAsset: AppAssets.gpu,
      price: 41200,
      oldPrice: 46500,
      rating: 4.8,
      reviews: 128,
      stores: 6,
      badges: const ['الأفضل سعراً', 'متوفر محلياً', 'ضمان الوكيل'],
      highlights: const [
        '16GB GDDR6X',
        'DLSS 3.5',
        'Ada Lovelace',
        'Ray Tracing',
        'PCIe 4.0',
      ],
      low30d: 38900,
      high30d: 46500,
      change30dPercent: -11,
      offers: _offers(41200, storeCount: 6),
      priceHistory: _history(current: 41200, low: 38900, high: 46500),
    ),
    Product(
      id: 'cpu-i7-14700k',
      name: 'Intel Core i7-14700K',
      brand: 'Intel',
      category: ProductCategory.cpu,
      tagline: '20 نواة • 5.6GHz • مقبس LGA1700',
      description:
          'معالج من الجيل الرابع عشر يضم 20 نواة و28 مساراً، مناسب للألعاب '
          'والمونتاج وتجميعات العمل المتوازنة.',
      imageAsset: AppAssets.cpu,
      price: 19450,
      oldPrice: 21500,
      rating: 4.9,
      reviews: 214,
      stores: 6,
      badges: const ['الأكثر مبيعاً', 'متوافق مع LGA1700'],
      highlights: const [
        '20 نواة (8P + 12E)',
        '28 مساراً',
        'حتى 5.6GHz',
        'Intel LGA1700',
      ],
      low30d: 18900,
      high30d: 21800,
      change30dPercent: -9,
      offers: _offers(19450, storeCount: 6),
      priceHistory: _history(current: 19450, low: 18900, high: 21800),
    ),
    Product(
      id: 'mb-tuf-z790',
      name: 'ASUS TUF Gaming Z790-Plus WiFi',
      brand: 'ASUS',
      category: ProductCategory.motherboard,
      tagline: 'DDR5 • PCIe 5.0 • WiFi 6E • ATX',
      description:
          'لوحة أم من فئة TUF مصممة للتحمل مع دعم DDR5 وPCIe 5.0 وشبكة '
          'WiFi 6E، مع مميزات تبريد موسعة للمكونات.',
      imageAsset: AppAssets.motherboard,
      price: 12800,
      oldPrice: 13900,
      rating: 4.7,
      reviews: 86,
      stores: 4,
      badges: const ['متوافق مع Gen 14', 'DDR5 Ready'],
      highlights: const ['DDR5', 'PCIe 5.0', 'WiFi 6E', 'ATX', 'Intel LGA1700'],
      low30d: 12400,
      high30d: 14200,
      change30dPercent: -4,
      offers: _offers(12800, storeCount: 4),
      priceHistory: _history(current: 12800, low: 12400, high: 14200),
    ),
    Product(
      id: 'ram-vengeance-ddr5-32',
      name: 'Corsair Vengeance RGB DDR5 32GB',
      brand: 'Corsair',
      category: ProductCategory.ram,
      tagline: '2×16GB • 6000MT/s • CL36 • RGB',
      description:
          'طقم رامات DDR5 بسعة 32GB وسرعة 6000MT/s، مع إضاءة RGB قابلة '
          'للتخصيص وتصميم منخفض يسهّل التركيب.',
      imageAsset: AppAssets.ram,
      price: 5400,
      oldPrice: 6100,
      rating: 4.8,
      reviews: 156,
      stores: 5,
      badges: const ['DDR5 Ready', 'سرعة 6000'],
      highlights: const ['32GB (2×16GB)', '6000MT/s', 'CL36', 'RGB'],
      low30d: 5290,
      high30d: 6250,
      change30dPercent: -12,
      offers: _offers(5400, storeCount: 5),
      priceHistory: _history(current: 5400, low: 5290, high: 6250),
    ),
    Product(
      id: 'psu-rm850x',
      name: 'Corsair RM850x 850W',
      brand: 'Corsair',
      category: ProductCategory.psu,
      tagline: '850W • 80+ Gold • Full Modular',
      description:
          'مزود طاقة هادئ وموثوق بقدرة 850W وشهادة 80+ Gold، مناسب '
          'للتجميعات العالية وكروت الشاشة الحديثة.',
      price: 6950,
      oldPrice: 7500,
      rating: 4.9,
      reviews: 92,
      stores: 3,
      badges: const ['موصى به', '80+ Gold'],
      highlights: const ['850W', '80+ Gold', 'Full Modular', 'ATX 3.0'],
      low30d: 6800,
      high30d: 7700,
      change30dPercent: -8,
      offers: _offers(6950, storeCount: 3),
      priceHistory: _history(current: 6950, low: 6800, high: 7700),
    ),
    Product(
      id: 'storage-samsung-990-pro',
      name: 'Samsung 990 PRO NVMe 2TB',
      brand: 'Samsung',
      category: ProductCategory.storage,
      tagline: 'PCIe 4.0 • 7450MB/s • NVMe',
      description:
          'قرص SSD سريع بسعة 2TB وسرعة قراءة تصل إلى 7450MB/s، مثالي '
          'للألعاب والبرامج الاحترافية.',
      price: 8900,
      rating: 4.9,
      reviews: 301,
      stores: 6,
      badges: const ['الأسرع', 'متوفر محلياً'],
      highlights: const ['2TB', 'PCIe 4.0', '7450MB/s', 'NVMe'],
      low30d: 8550,
      high30d: 9500,
      change30dPercent: -5,
      offers: _offers(8900, storeCount: 6),
      priceHistory: _history(current: 8900, low: 8550, high: 9500),
    ),
    Product(
      id: 'cooler-deepcool-lt720',
      name: 'DeepCool LT720 360 AIO',
      brand: 'DeepCool',
      category: ProductCategory.cooler,
      tagline: '360mm • ARGB • 3100RPM',
      description:
          'مبرد مائي بثلاث مراوح 120mm وشاشة إنفينيتي، مع تبريد قوي '
          'وتصميم مناسب للصناديق الزجاجية.',
      price: 5600,
      rating: 4.6,
      reviews: 54,
      stores: 3,
      badges: const ['تبريد عالي', 'ARGB'],
      highlights: const ['360mm', 'ARGB', '3100RPM', 'LGA1700 / AM5'],
      low30d: 5450,
      high30d: 5900,
      change30dPercent: -3,
      offers: _offers(5600, storeCount: 3),
      priceHistory: _history(current: 5600, low: 5450, high: 5900),
    ),
    Product(
      id: 'case-nzxt-h7-flow',
      name: 'NZXT H7 Flow',
      brand: 'NZXT',
      category: ProductCategory.pcCase,
      tagline: 'Mid Tower • Airflow • زجاج مقوى',
      description:
          'صندوق Mid Tower بتصميم انسيابي وتهوية أمامية ممتازة، مع '
          'مساحة مريحة لتركيب المكونات والكابلات.',
      imageAsset: AppAssets.pcCase,
      price: 4800,
      oldPrice: 5200,
      rating: 4.7,
      reviews: 73,
      stores: 4,
      badges: const ['Airflow', 'زجاج مقوى'],
      highlights: const ['Mid Tower', 'ATX', '3 مراوح', 'زجاج مقوى'],
      low30d: 4700,
      high30d: 5300,
      change30dPercent: -8,
      offers: _offers(4800, storeCount: 4),
      priceHistory: _history(current: 4800, low: 4700, high: 5300),
    ),
    Product(
      id: 'laptop-legion-pro-5',
      name: 'Lenovo Legion Pro 5 16IRX9',
      brand: 'Lenovo',
      category: ProductCategory.laptop,
      tagline: 'i7-14700HX • RTX 4070 • 32GB • 1TB',
      description:
          'لابتوب ألعاب بشاشة 16 بوصة 2.5K بمعدل تحديث 240Hz، مع كارت '
          'RTX 4070 ومعالج i7 من الجيل الرابع عشر.',
      imageAsset: AppAssets.laptop,
      price: 65000,
      oldPrice: 69999,
      rating: 4.8,
      reviews: 67,
      stores: 4,
      badges: const ['الأفضل للألعاب', 'متوفر محلياً'],
      highlights: const [
        'Intel Core i7-14700HX',
        'RTX 4070 8GB',
        '32GB DDR5',
        '1TB NVMe',
        '16" 2.5K 240Hz',
      ],
      low30d: 63900,
      high30d: 71500,
      change30dPercent: -7,
      offers: _offers(65000, storeCount: 4),
      priceHistory: _history(current: 65000, low: 63900, high: 71500),
    ),
    Product(
      id: 'laptop-hp-victus-15',
      name: 'HP Victus 15',
      brand: 'HP',
      category: ProductCategory.laptop,
      tagline: 'i5-13420H • RTX 4060 • 16GB • 512GB',
      description:
          'لابتوب ألعاب اقتصادي بشاشة 15.6 بوصة 144Hz وكارت RTX 4060، '
          'خيار متوازن للدخول إلى عالم الألعاب.',
      imageAsset: AppAssets.laptop,
      price: 39999,
      oldPrice: 43999,
      rating: 4.5,
      reviews: 132,
      stores: 5,
      badges: const ['أفضل قيمة', 'متوفر محلياً'],
      highlights: const [
        'Intel Core i5-13420H',
        'RTX 4060 8GB',
        '16GB DDR5',
        '512GB NVMe',
        '15.6" FHD 144Hz',
      ],
      low30d: 38900,
      high30d: 44999,
      change30dPercent: -9,
      offers: _offers(39999, storeCount: 5),
      priceHistory: _history(current: 39999, low: 38900, high: 44999),
    ),
    Product(
      id: 'laptop-rog-zephyrus-g14',
      name: 'ASUS ROG Zephyrus G14',
      brand: 'ASUS',
      category: ProductCategory.laptop,
      tagline: 'Ryzen 9 • RTX 4070 • 32GB • OLED',
      description:
          'لابتوب خفيف بشاشة OLED مقاس 14 بوصة ومعالج Ryzen 9، مناسب '
          'للألعاب والتنقل والعمل الإبداعي.',
      imageAsset: AppAssets.laptop,
      price: 82500,
      rating: 4.9,
      reviews: 44,
      stores: 3,
      badges: const ['OLED', 'خفيف الوزن'],
      highlights: const [
        'AMD Ryzen 9',
        'RTX 4070 8GB',
        '32GB DDR5',
        '1TB NVMe',
        '14" OLED 120Hz',
      ],
      low30d: 80900,
      high30d: 85000,
      change30dPercent: -2,
      offers: _offers(82500, storeCount: 3),
      priceHistory: _history(current: 82500, low: 80900, high: 85000),
    ),
    Product(
      id: 'laptop-msi-thin-15',
      name: 'MSI Thin 15 B13V',
      brand: 'MSI',
      category: ProductCategory.laptop,
      tagline: 'i5-12450H • RTX 4050 • 16GB • 512GB',
      description:
          'لابتوب ألعاب خفيف بسعر مناسب، مع كارت RTX 4050 وشاشة 144Hz.',
      imageAsset: AppAssets.laptop,
      price: 45900,
      oldPrice: 48900,
      rating: 4.4,
      reviews: 58,
      stores: 4,
      badges: const ['سعر مناسب'],
      highlights: const [
        'Intel Core i5-12450H',
        'RTX 4050 6GB',
        '16GB DDR4',
        '512GB NVMe',
        '15.6" FHD 144Hz',
      ],
      low30d: 44900,
      high30d: 49900,
      change30dPercent: -6,
      offers: _offers(45900, storeCount: 4),
      priceHistory: _history(current: 45900, low: 44900, high: 49900),
    ),
  ];

  static List<Product> byCategory(ProductCategory category) {
    return products.where((product) => product.category == category).toList();
  }

  static Product? byId(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  static List<Product> get deals {
    final discounted = products
        .where((product) => product.discountPercent != null)
        .toList();
    discounted.sort(
      (a, b) => (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0),
    );
    return discounted;
  }

  static List<Product> get laptops => byCategory(ProductCategory.laptop);

  static List<MerchantOffer> _offers(int basePrice, {required int storeCount}) {
    const merchants = [
      'مول البستان',
      'النهضة تكنولوجي',
      'سوق البلد',
      'كمبيوتر شوب',
      'سيجما',
      'البدر',
    ];
    const increments = [0, 350, 700, 1100, 1600, 2100];
    const minutes = [12, 24, 38, 55, 71, 95];
    return List.generate(storeCount, (index) {
      return MerchantOffer(
        merchant: merchants[index],
        price: basePrice + increments[index],
        inStock: index < 4,
        lastSeen: 'منذ ${minutes[index]} دقيقة',
        isBest: index == 0,
      );
    });
  }

  static List<PricePoint> _history({
    required int current,
    required int low,
    required int high,
  }) {
    const days = [30, 27, 24, 21, 18, 15, 12, 9, 6, 3, 1, 0];
    const fractions = [
      1.0,
      0.94,
      0.88,
      0.75,
      0.82,
      0.62,
      0.55,
      0.60,
      0.40,
      0.35,
      0.52,
    ];
    final spread = high - low;
    return [
      for (var index = 0; index < fractions.length; index++)
        PricePoint(
          day: days[index],
          price: low + (spread * fractions[index]).round(),
        ),
      PricePoint(day: 0, price: current),
    ];
  }
}
