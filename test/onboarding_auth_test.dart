import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagme3a/app/app.dart';
import 'package:tagme3a/core/di/app_dependencies.dart';
import 'package:tagme3a/core/storage/app_preferences.dart';
import 'package:tagme3a/features/account/presentation/pages/account_page.dart';
import 'package:tagme3a/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:tagme3a/features/auth/domain/entities/app_user.dart';
import 'package:tagme3a/features/auth/domain/repositories/auth_repository.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required AppPreferences preferences,
  AuthRepository? authRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    Tagme3aApp(
      dependencies: AppDependencies.mock(
        preferences: preferences,
        authRepository: authRepository ?? FakeAuthRepository(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows onboarding and skip opens auth', (
    tester,
  ) async {
    final preferences = InMemoryAppPreferences();
    await _pumpApp(tester, preferences: preferences);

    expect(find.text('قارن الأسعار في مكان واحد'), findsOneWidget);
    expect(find.text('١ من ٣'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('أهلاً بيك في تجميعة'), findsOneWidget);
    expect(preferences.onboardingComplete, isTrue);
  });

  testWidgets('onboarding walks all three slides and starts auth', (
    tester,
  ) async {
    await _pumpApp(tester, preferences: InMemoryAppPreferences());

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('اتأكد إن القطع متوافقة'), findsOneWidget);
    expect(find.text('٢ من ٣'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('ما تفوّتش أفضل سعر'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بيك في تجميعة'), findsOneWidget);
  });

  testWidgets('guest can continue from auth into the app', (tester) async {
    final preferences = InMemoryAppPreferences();
    await _pumpApp(tester, preferences: preferences);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كزائر'));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(preferences.guest, isTrue);
  });

  testWidgets('email sign in opens the app shell', (tester) async {
    await _pumpApp(tester, preferences: InMemoryAppPreferences());

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'mostafa@tagme3a.demo');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('creates an account and opens the app shell', (tester) async {
    await _pumpApp(tester, preferences: InMemoryAppPreferences());

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حساب جديد'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'مصطفى محمود');
    await tester.enterText(fields.at(1), 'mostafa@tagme3a.demo');
    await tester.enterText(fields.at(2), '123456');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('google sign in opens the app shell', (tester) async {
    await _pumpApp(tester, preferences: InMemoryAppPreferences());

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المتابعة بجوجل'));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('password reset shows a confirmation notice', (tester) async {
    await _pumpApp(tester, preferences: InMemoryAppPreferences());

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'mostafa@tagme3a.demo',
    );
    await tester.tap(find.text('نسيت كلمة السر؟'));
    await tester.pumpAndSettle();
    expect(find.text('استعادة كلمة السر'), findsOneWidget);

    await tester.tap(find.text('ابعت اللينك'));
    await tester.pumpAndSettle();

    expect(
      find.text('بعتنالك لينك إعادة تعيين كلمة السر على بريدك.'),
      findsOneWidget,
    );
  });

  testWidgets('auth validates empty fields before submitting', (tester) async {
    await _pumpApp(tester, preferences: InMemoryAppPreferences());

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('اكتب البريد الإلكتروني.'), findsOneWidget);
    expect(find.text('اكتب كلمة السر.'), findsOneWidget);
  });

  testWidgets('returning signed-in user lands on the shell', (tester) async {
    await _pumpApp(
      tester,
      preferences: InMemoryAppPreferences(onboardingComplete: true),
      authRepository: FakeAuthRepository(
        initialUser: const AppUser(
          uid: 'user-1',
          email: 'mostafa@tagme3a.demo',
          displayName: 'مصطفى محمود',
          provider: 'password',
        ),
      ),
    );

    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('returning signed-out user lands on auth', (tester) async {
    await _pumpApp(
      tester,
      preferences: InMemoryAppPreferences(onboardingComplete: true),
    );

    expect(find.text('أهلاً بيك في تجميعة'), findsOneWidget);
  });

  testWidgets('signs out from the account tab', (tester) async {
    await _pumpApp(
      tester,
      preferences: InMemoryAppPreferences(onboardingComplete: true),
      authRepository: FakeAuthRepository(
        initialUser: const AppUser(
          uid: 'user-1',
          email: 'mostafa@tagme3a.demo',
          displayName: 'مصطفى محمود',
          provider: 'password',
        ),
      ),
    );

    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('account-sign-out')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(AccountPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('account-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();

    expect(find.text('أهلاً بيك في تجميعة'), findsOneWidget);
  });
}
