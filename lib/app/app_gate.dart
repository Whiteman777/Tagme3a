import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/storage/app_preferences.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/navigation/presentation/pages/app_shell.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  _BootState? _boot;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final onboardingFuture = widget.preferences.isOnboardingComplete();
    final guestFuture = widget.preferences.isGuest();
    final splashFuture = Future<void>.delayed(
      const Duration(milliseconds: 1100),
    );

    var onboardingComplete = false;
    var guest = false;
    try {
      onboardingComplete = await onboardingFuture;
    } catch (_) {
      // If preferences are unavailable, show onboarding rather than hanging.
    }
    try {
      guest = await guestFuture;
    } catch (_) {
      // Treat unreadable guest state as signed out.
    }
    await splashFuture;
    if (!mounted) return;
    setState(() {
      _boot = _BootState(onboardingComplete: onboardingComplete, guest: guest);
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      await widget.preferences.markOnboardingComplete();
    } catch (_) {
      // Continue even if the flag cannot be persisted.
    }
    if (!mounted) return;
    setState(() {
      _boot = _boot?.copyWith(onboardingComplete: true);
    });
  }

  Future<void> _continueAsGuest() async {
    try {
      await widget.preferences.setGuest(true);
    } catch (_) {
      // Continue as a guest for this session.
    }
    if (!mounted) return;
    setState(() {
      _boot = _boot?.copyWith(guest: true);
    });
  }

  Future<void> _clearGuest() async {
    if (_boot?.guest != true) return;
    try {
      await widget.preferences.setGuest(false);
    } catch (_) {
      // The signed-in user takes priority over the guest flag.
    }
    if (!mounted) return;
    setState(() {
      _boot = _boot?.copyWith(guest: false);
    });
  }

  Widget _destination(AuthState auth) {
    if (_boot == null) {
      return const SplashPage(key: ValueKey('splash'));
    }
    if (!_boot!.onboardingComplete) {
      return OnboardingPage(
        key: const ValueKey('onboarding'),
        onFinished: _completeOnboarding,
        onSkipped: _completeOnboarding,
      );
    }
    if (auth.user != null || _boot!.guest) {
      return const AppShell(key: ValueKey('shell'));
    }
    return AuthPage(
      key: const ValueKey('auth'),
      onContinueAsGuest: _continueAsGuest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user == null && current.user != null,
      listener: (context, state) => _clearGuest(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _destination(auth),
      ),
    );
  }
}

class _BootState {
  const _BootState({required this.onboardingComplete, required this.guest});

  final bool onboardingComplete;
  final bool guest;

  _BootState copyWith({bool? onboardingComplete, bool? guest}) {
    return _BootState(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      guest: guest ?? this.guest,
    );
  }
}
