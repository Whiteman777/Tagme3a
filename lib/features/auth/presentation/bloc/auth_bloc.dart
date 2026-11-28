import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthEmailSignUpRequested>(_onEmailSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthNoticeCleared>(_onNoticeCleared);
    on<AuthUserChanged>(_onUserChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = _repository.currentUser;
    emit(
      AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
      ),
    );

    await _subscription?.cancel();
    _subscription = _repository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
      onError: (_) => add(const AuthUserChanged(null)),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        action: AuthAction.none,
      ),
    );
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.signIn,
        errorMessage: null,
        noticeMessage: null,
      ),
    );
    try {
      final user = await _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          action: AuthAction.none,
        ),
      );
    } catch (error) {
      _emitFailure(emit, error);
    }
  }

  Future<void> _onEmailSignUp(
    AuthEmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.signUp,
        errorMessage: null,
        noticeMessage: null,
      ),
    );
    try {
      final user = await _repository.signUpWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          action: AuthAction.none,
        ),
      );
    } catch (error) {
      _emitFailure(emit, error);
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.google,
        errorMessage: null,
        noticeMessage: null,
      ),
    );
    try {
      final user = await _repository.signInWithGoogle();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          action: AuthAction.none,
        ),
      );
    } catch (error) {
      _emitFailure(emit, error);
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.reset,
        errorMessage: null,
        noticeMessage: null,
      ),
    );
    try {
      await _repository.sendPasswordReset(event.email);
      emit(
        state.copyWith(
          action: AuthAction.none,
          noticeMessage: 'بعتنالك لينك إعادة تعيين كلمة السر على بريدك.',
        ),
      );
    } catch (error) {
      _emitFailure(emit, error);
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(action: AuthAction.signOut, errorMessage: null));
    try {
      await _repository.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (error) {
      _emitFailure(emit, error);
    }
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    if (state.errorMessage == null) return;
    emit(state.copyWith(errorMessage: null));
  }

  void _onNoticeCleared(AuthNoticeCleared event, Emitter<AuthState> emit) {
    if (state.noticeMessage == null) return;
    emit(state.copyWith(noticeMessage: null));
  }

  void _emitFailure(Emitter<AuthState> emit, Object error) {
    if (error is AuthFailure && error.code == 'google-canceled') {
      emit(state.copyWith(action: AuthAction.none, errorMessage: null));
      return;
    }
    final message = error is AuthFailure
        ? error.message
        : 'حصلت مشكلة. جرّب تاني.';
    emit(state.copyWith(action: AuthAction.none, errorMessage: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
