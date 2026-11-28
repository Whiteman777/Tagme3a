import 'package:firebase_auth/firebase_auth.dart';

/// A user-facing auth error with an Arabic message.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  factory AuthFailure.fromFirebase(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'البريد الإلكتروني مش صحيح.',
      'user-disabled' => 'الحساب ده متوقف. تواصل مع الدعم.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'البريد أو كلمة السر غلط.',
      'email-already-in-use' => 'البريد ده مسجل بالفعل. جرّب تسجيل الدخول.',
      'weak-password' => 'كلمة السر لازم تكون ٦ حروف على الأقل.',
      'too-many-requests' => 'محاولات كتير. استنى شوية وجرّب تاني.',
      'network-request-failed' => 'في مشكلة في الاتصال بالإنترنت.',
      'operation-not-allowed' => 'طريقة تسجيل الدخول دي مش مفعّلة.',
      'account-exists-with-different-credential' =>
        'البريد ده مسجل بطريقة تانية. جرّب تسجيل الدخول بالبريد.',
      'requires-recent-login' => 'سجّل دخولك تاني عشان تكمل.',
      _ => 'حصلت مشكلة. جرّب تاني.',
    };
    return AuthFailure(error.code, message);
  }

  final String code;
  final String message;

  @override
  String toString() => 'AuthFailure($code): $message';
}
