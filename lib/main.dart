import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/di/app_dependencies.dart';
import 'core/storage/app_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  var dependencies = AppDependencies.mock(
    preferences: InMemoryAppPreferences(),
  );
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    dependencies = AppDependencies.firebase();
  } on UnsupportedError {
    // Linux desktop has no official Firebase support; keep the demo usable.
    debugPrint('Firebase is not configured for this platform. Using mocks.');
  }

  runApp(Tagme3aApp(dependencies: dependencies));
}
