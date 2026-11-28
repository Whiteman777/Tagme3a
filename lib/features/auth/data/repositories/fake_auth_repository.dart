import 'dart:async';

import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory auth used by the mock composition root and by widget tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, this.failure})
    : _user = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// When set, the next credential call throws this instead of succeeding.
  AuthFailure? failure;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _maybeThrow();
    return _authenticate(
      AppUser(
        uid: email,
        email: email,
        displayName: email.split('@').first,
        provider: 'password',
      ),
    );
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _maybeThrow();
    return _authenticate(
      AppUser(
        uid: email,
        email: email,
        displayName: name,
        provider: 'password',
      ),
    );
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    _maybeThrow();
    return _authenticate(
      const AppUser(
        uid: 'google-user',
        email: 'mostafa@tagme3a.demo',
        displayName: 'مصطفى محمود',
        provider: 'google.com',
      ),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _maybeThrow();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }

  void _maybeThrow() {
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
  }

  AppUser _authenticate(AppUser user) {
    _user = user;
    _controller.add(user);
    return user;
  }
}
