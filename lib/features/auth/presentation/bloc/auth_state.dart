import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum AuthAction { none, signIn, signUp, google, reset, signOut }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.action = AuthAction.none,
    this.errorMessage,
    this.noticeMessage,
  });

  static const Object _unset = Object();

  final AuthStatus status;
  final AppUser? user;
  final AuthAction action;
  final String? errorMessage;
  final String? noticeMessage;

  bool get isBusy => action != AuthAction.none;

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _unset,
    AuthAction? action,
    Object? errorMessage = _unset,
    Object? noticeMessage = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as AppUser?,
      action: action ?? this.action,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      noticeMessage: identical(noticeMessage, _unset)
          ? this.noticeMessage
          : noticeMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    action,
    errorMessage,
    noticeMessage,
  ];
}
