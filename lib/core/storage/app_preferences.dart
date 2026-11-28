import 'package:shared_preferences/shared_preferences.dart';

/// Small, testable surface for the flags the startup flow needs.
abstract interface class AppPreferences {
  Future<bool> isOnboardingComplete();

  Future<void> markOnboardingComplete();

  Future<bool> isGuest();

  Future<void> setGuest(bool value);
}

class SharedPreferencesAppPreferences implements AppPreferences {
  SharedPreferencesAppPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _onboardingKey = 'onboarding_complete';
  static const _guestKey = 'guest_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isOnboardingComplete() async {
    return await _preferences.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<void> markOnboardingComplete() {
    return _preferences.setBool(_onboardingKey, true);
  }

  @override
  Future<bool> isGuest() async {
    return await _preferences.getBool(_guestKey) ?? false;
  }

  @override
  Future<void> setGuest(bool value) {
    return _preferences.setBool(_guestKey, value);
  }
}

/// Used by tests and by the mock composition root.
class InMemoryAppPreferences implements AppPreferences {
  InMemoryAppPreferences({this.onboardingComplete = false, this.guest = false});

  bool onboardingComplete;
  bool guest;

  @override
  Future<bool> isOnboardingComplete() async => onboardingComplete;

  @override
  Future<void> markOnboardingComplete() async {
    onboardingComplete = true;
  }

  @override
  Future<bool> isGuest() async => guest;

  @override
  Future<void> setGuest(bool value) async {
    guest = value;
  }
}
