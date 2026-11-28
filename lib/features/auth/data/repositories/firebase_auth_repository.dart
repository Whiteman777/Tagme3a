import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Future<void>? _googleInitialization;

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      return user == null ? null : AppUser.fromFirebase(user);
    });
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AppUser.fromFirebase(user);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _requireUser(credential.user);
      try {
        await credential.user?.updateDisplayName(name);
      } on FirebaseAuthException {
        // The account is already created; keep the local name for this session.
      }
      return AppUser(
        uid: user.uid,
        email: user.email,
        displayName: name,
        photoUrl: user.photoUrl,
        provider: user.provider,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await (_googleInitialization ??= _googleSignIn.initialize());
      final account = await _googleSignIn.authenticate();
      final authentication = account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'google-token',
          'تعذّر تسجيل الدخول بجوجل. جرّب تاني.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return _requireUser(result.user);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('google-canceled', '');
      }
      throw const AuthFailure(
        'google-failed',
        'تعذّر تسجيل الدخول بجوجل. جرّب تاني.',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebase(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      // Firebase is the source of truth; a failed Google cleanup is harmless.
    }
  }

  AppUser _requireUser(User? user) {
    if (user == null) {
      throw const AuthFailure('missing-user', 'حصلت مشكلة. جرّب تاني.');
    }
    return AppUser.fromFirebase(user);
  }
}
