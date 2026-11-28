import 'package:flutter/material.dart';

import '../core/domain/entities/product.dart';
import '../features/alerts/presentation/pages/alerts_page.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/catalog/presentation/pages/search_page.dart';
import '../features/product/presentation/pages/product_details_screen.dart';

abstract final class AppRoutes {
  static Route<void> product(Product product) {
    return MaterialPageRoute<void>(
      builder: (context) => ProductDetailsScreen(product: product),
    );
  }

  static Route<void> alerts() {
    return MaterialPageRoute<void>(builder: (context) => const AlertsPage());
  }

  static Route<void> auth() {
    return MaterialPageRoute<void>(
      builder: (context) => const AuthPage(popOnSuccess: true),
    );
  }

  static Route<void> search() {
    return MaterialPageRoute<void>(builder: (context) => const SearchPage());
  }
}
