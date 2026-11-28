import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/app_dependencies.dart';
import '../core/presentation/app_scroll_behavior.dart';
import '../core/storage/app_preferences.dart';
import '../core/theme/app_theme.dart';
import '../features/alerts/domain/repositories/alerts_repository.dart';
import '../features/alerts/domain/usecases/get_price_alerts.dart';
import '../features/alerts/presentation/bloc/alerts_bloc.dart';
import '../features/alerts/presentation/bloc/alerts_event.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/builder/domain/repositories/builder_repository.dart';
import '../features/builder/domain/usecases/get_builder_data.dart';
import '../features/builder/presentation/bloc/builder_bloc.dart';
import '../features/builder/presentation/bloc/builder_event.dart';
import '../features/catalog/domain/repositories/catalog_repository.dart';
import '../features/catalog/domain/usecases/get_catalog_products.dart';
import '../features/catalog/presentation/bloc/catalog_bloc.dart';
import '../features/catalog/presentation/bloc/catalog_event.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/get_home_feed.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/home/presentation/bloc/home_event.dart';
import '../features/laptops/domain/repositories/laptops_repository.dart';
import '../features/laptops/domain/usecases/get_laptops.dart';
import '../features/laptops/presentation/bloc/laptops_bloc.dart';
import '../features/laptops/presentation/bloc/laptops_event.dart';
import '../features/navigation/presentation/cubit/navigation_cubit.dart';
import '../features/product/domain/repositories/product_repository.dart';
import 'app_gate.dart';

class Tagme3aApp extends StatelessWidget {
  const Tagme3aApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HomeRepository>.value(
          value: dependencies.homeRepository,
        ),
        RepositoryProvider<CatalogRepository>.value(
          value: dependencies.catalogRepository,
        ),
        RepositoryProvider<ProductRepository>.value(
          value: dependencies.productRepository,
        ),
        RepositoryProvider<BuilderRepository>.value(
          value: dependencies.builderRepository,
        ),
        RepositoryProvider<LaptopsRepository>.value(
          value: dependencies.laptopsRepository,
        ),
        RepositoryProvider<AlertsRepository>.value(
          value: dependencies.alertsRepository,
        ),
        RepositoryProvider<AuthRepository>.value(
          value: dependencies.authRepository,
        ),
        RepositoryProvider<AppPreferences>.value(
          value: dependencies.preferences,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(
            create: (context) => HomeBloc(
              getHomeFeed: GetHomeFeed(context.read<HomeRepository>()),
            )..add(const HomeStarted()),
          ),
          BlocProvider(
            create: (context) => CatalogBloc(
              getCatalogProducts: GetCatalogProducts(
                context.read<CatalogRepository>(),
              ),
            )..add(const CatalogStarted()),
          ),
          BlocProvider(
            create: (context) => BuilderBloc(
              getInitialBuild: GetInitialBuild(
                context.read<BuilderRepository>(),
              ),
              getBuildOptions: GetBuildOptions(
                context.read<BuilderRepository>(),
              ),
            )..add(const BuilderStarted()),
          ),
          BlocProvider(
            create: (context) => LaptopsBloc(
              getLaptops: GetLaptops(context.read<LaptopsRepository>()),
            )..add(const LaptopsStarted()),
          ),
          BlocProvider(
            create: (context) => AlertsBloc(
              getPriceAlerts: GetPriceAlerts(context.read<AlertsRepository>()),
            )..add(const AlertsStarted()),
          ),
          BlocProvider(
            create: (context) =>
                AuthBloc(context.read<AuthRepository>())
                  ..add(const AuthStarted()),
          ),
        ],
        child: _Tagme3aView(preferences: dependencies.preferences),
      ),
    );
  }
}

class _Tagme3aView extends StatelessWidget {
  const _Tagme3aView({required this.preferences});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تجميعة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppGate(preferences: preferences),
    );
  }
}
