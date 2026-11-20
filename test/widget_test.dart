import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagme3a/app/app.dart';
import 'package:tagme3a/core/di/app_dependencies.dart';

void main() {
  testWidgets('boots into the Arabic home feed and navigates to the builder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(Tagme3aApp(dependencies: AppDependencies.mock()));

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('صباح الخير، مصطفى'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('ابدأ التجميعة الآن'), findsOneWidget);

    await tester.tap(find.text('جمّع جهازك').last);
    await tester.pumpAndSettle();

    expect(find.text('تجميعتك الحالية'), findsOneWidget);
    expect(find.text('تنبيه مقترح من فريق تجميعة'), findsOneWidget);
    expect(find.textContaining('ترقية المزود'), findsOneWidget);
    expect(find.text('94%'), findsWidgets);
  });

  testWidgets('opens the store tab and filters to laptops', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(Tagme3aApp(dependencies: AppDependencies.mock()));
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('المتجر'));
    await tester.pumpAndSettle();

    expect(find.text('المتجر'), findsWidgets);
    expect(find.text('12 منتج'), findsOneWidget);

    await tester.tap(find.text('كروت الشاشة').first);
    await tester.pumpAndSettle();

    expect(find.text('1 منتج'), findsOneWidget);
  });
}
