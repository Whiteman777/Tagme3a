import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.provider,
  });

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      provider: user.providerData.isEmpty
          ? null
          : user.providerData.first.providerId,
    );
  }

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? provider;

  String get name {
    final value = displayName?.trim();
    if (value != null && value.isNotEmpty) return value;
    final address = email;
    if (address != null && address.contains('@')) {
      return address.split('@').first;
    }
    return 'مستخدم تجميعة';
  }

  bool get isGoogle => provider == 'google.com';

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, provider];
}
