import 'package:flutter/material.dart';

import '../domain/entities/product_category.dart';

extension ProductCategoryPresentation on ProductCategory {
  IconData get icon => switch (this) {
    ProductCategory.cpu => Icons.memory_rounded,
    ProductCategory.gpu => Icons.videogame_asset_rounded,
    ProductCategory.motherboard => Icons.developer_board_rounded,
    ProductCategory.ram => Icons.view_module_rounded,
    ProductCategory.storage => Icons.storage_rounded,
    ProductCategory.psu => Icons.bolt_rounded,
    ProductCategory.cooler => Icons.ac_unit_rounded,
    ProductCategory.pcCase => Icons.computer_rounded,
    ProductCategory.laptop => Icons.laptop_mac_rounded,
  };
}
