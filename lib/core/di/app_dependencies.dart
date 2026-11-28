import '../../features/alerts/data/repositories/alerts_repository_impl.dart';
import '../../features/alerts/domain/repositories/alerts_repository.dart';
import '../../features/auth/data/repositories/fake_auth_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/builder/data/repositories/builder_repository_impl.dart';
import '../../features/builder/domain/repositories/builder_repository.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/laptops/data/repositories/laptops_repository_impl.dart';
import '../../features/laptops/domain/repositories/laptops_repository.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../storage/app_preferences.dart';

/// Composition root. Catalog data still points at mocks, while auth can be
/// backed by Firebase or by an in-memory fake for tests and previews.
class AppDependencies {
  const AppDependencies({
    required this.homeRepository,
    required this.catalogRepository,
    required this.productRepository,
    required this.builderRepository,
    required this.laptopsRepository,
    required this.alertsRepository,
    required this.authRepository,
    required this.preferences,
  });

  final HomeRepository homeRepository;
  final CatalogRepository catalogRepository;
  final ProductRepository productRepository;
  final BuilderRepository builderRepository;
  final LaptopsRepository laptopsRepository;
  final AlertsRepository alertsRepository;
  final AuthRepository authRepository;
  final AppPreferences preferences;

  factory AppDependencies.mock({
    AuthRepository? authRepository,
    AppPreferences? preferences,
  }) {
    return AppDependencies(
      homeRepository: HomeRepositoryImpl(HomeMockDataSource()),
      catalogRepository: CatalogRepositoryImpl(CatalogMockDataSource()),
      productRepository: ProductRepositoryImpl(ProductMockDataSource()),
      builderRepository: BuilderRepositoryImpl(BuilderMockDataSource()),
      laptopsRepository: LaptopsRepositoryImpl(LaptopsMockDataSource()),
      alertsRepository: AlertsRepositoryImpl(AlertsMockDataSource()),
      authRepository: authRepository ?? FakeAuthRepository(),
      preferences:
          preferences ??
          InMemoryAppPreferences(onboardingComplete: true, guest: true),
    );
  }

  factory AppDependencies.firebase() {
    return AppDependencies(
      homeRepository: HomeRepositoryImpl(HomeMockDataSource()),
      catalogRepository: CatalogRepositoryImpl(CatalogMockDataSource()),
      productRepository: ProductRepositoryImpl(ProductMockDataSource()),
      builderRepository: BuilderRepositoryImpl(BuilderMockDataSource()),
      laptopsRepository: LaptopsRepositoryImpl(LaptopsMockDataSource()),
      alertsRepository: AlertsRepositoryImpl(AlertsMockDataSource()),
      authRepository: FirebaseAuthRepository(),
      preferences: SharedPreferencesAppPreferences(),
    );
  }
}
