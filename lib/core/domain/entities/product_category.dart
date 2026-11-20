enum ProductCategory {
  cpu(id: 'cpu', label: 'المعالجات'),
  gpu(id: 'gpu', label: 'كروت الشاشة'),
  motherboard(id: 'motherboard', label: 'اللوحات الأم'),
  ram(id: 'ram', label: 'الرامات'),
  storage(id: 'storage', label: 'التخزين'),
  psu(id: 'psu', label: 'مزودات الطاقة'),
  cooler(id: 'cooler', label: 'التبريد'),
  pcCase(id: 'case', label: 'الصناديق'),
  laptop(id: 'laptop', label: 'اللابتوبات');

  const ProductCategory({required this.id, required this.label});

  final String id;
  final String label;

  bool get isLaptop => this == ProductCategory.laptop;
}
