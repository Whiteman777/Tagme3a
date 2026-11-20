import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../account/presentation/pages/account_page.dart';
import '../../../builder/presentation/pages/builder_page.dart';
import '../../../catalog/presentation/pages/catalog_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../laptops/presentation/pages/laptops_page.dart';
import '../cubit/navigation_cubit.dart';
import '../widgets/app_bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, int>(
      builder: (context, index) {
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: const [
              HomePage(),
              CatalogPage(),
              BuilderPage(),
              LaptopsPage(),
              AccountPage(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            selectedIndex: index,
            onSelected: (next) => context.read<NavigationCubit>().select(next),
          ),
        );
      },
    );
  }
}
