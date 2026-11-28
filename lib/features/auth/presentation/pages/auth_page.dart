import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/app_snack.dart';
import '../../../../core/presentation/widgets/brand_wordmark.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.onContinueAsGuest,
    this.popOnSuccess = false,
  });

  final VoidCallback? onContinueAsGuest;
  final bool popOnSuccess;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _formKey = GlobalKey<FormState>();
  var _isSignUp = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool signUp) {
    if (_isSignUp == signUp) return;
    setState(() {
      _isSignUp = signUp;
      _formKey = GlobalKey<FormState>();
      _passwordController.clear();
    });
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  void _clearError() {
    if (context.read<AuthBloc>().state.errorMessage != null) {
      context.read<AuthBloc>().add(const AuthErrorCleared());
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final bloc = context.read<AuthBloc>();
    if (_isSignUp) {
      bloc.add(
        AuthEmailSignUpRequested(
          name: _nameController.text.trim(),
          email: email,
          password: password,
        ),
      );
    } else {
      bloc.add(AuthEmailSignInRequested(email: email, password: password));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      AppSnack.show(
        context,
        'اكتب بريدك الإلكتروني الأول.',
        icon: Icons.mail_outline_rounded,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'استعادة كلمة السر',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'هنبعت لينك إعادة التعيين على $email',
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.5,
            height: 1.7,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ابعت اللينك'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
    }
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'اكتب اسمك.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'اكتب البريد الإلكتروني.';
    if (!_emailPattern.hasMatch(email)) return 'البريد الإلكتروني مش صحيح.';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'اكتب كلمة السر.';
    if ((value ?? '').length < 6) {
      return 'كلمة السر لازم تكون ٦ حروف على الأقل.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final busy = state.isBusy;
    final primaryLoading =
        state.action == AuthAction.signIn || state.action == AuthAction.signUp;
    final canGoBack = Navigator.of(context).canPop();

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user == null && current.user != null,
      listener: (context, state) {
        if (widget.popOnSuccess && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canGoBack)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: 'رجوع',
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    Center(child: const BrandMark(size: 46)),
                    const SizedBox(height: 10),
                    const Center(
                      child: BrandWordmark(
                        size: 22,
                        tagline: false,
                        alignment: CrossAxisAlignment.center,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _isSignUp ? 'اعمل حسابك في دقيقة' : 'أهلاً بيك في تجميعة',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 24,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'خطوة واحدة وتقدر تحفظ تجميعاتك وتنبيهاتك.'
                          : 'سجّل دخولك عشان تحفظ تجميعاتك وتنبيهاتك.',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ModeToggle(
                      isSignUp: _isSignUp,
                      enabled: !busy,
                      onChanged: _setMode,
                    ),
                    const SizedBox(height: 18),
                    if (_isSignUp) ...[
                      AuthTextField(
                        controller: _nameController,
                        label: 'الاسم',
                        hint: 'اسمك الكامل',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: _validateName,
                        onChanged: (_) => _clearError(),
                        enabled: !busy,
                      ),
                      const SizedBox(height: 12),
                    ],
                    AuthTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'name@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      onChanged: (_) => _clearError(),
                      enabled: !busy,
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'كلمة السر',
                      hint: '٦ حروف على الأقل',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        _isSignUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      validator: _validatePassword,
                      onChanged: (_) => _clearError(),
                      onFieldSubmitted: (_) => _submit(),
                      enabled: !busy,
                      suffix: IconButton(
                        tooltip: _obscurePassword
                            ? 'إظهار كلمة السر'
                            : 'إخفاء كلمة السر',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                      ),
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: busy ? null : _forgotPassword,
                          child: const Text('نسيت كلمة السر؟'),
                        ),
                      ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      AuthErrorBanner(message: state.errorMessage!),
                    ],
                    if (state.noticeMessage != null) ...[
                      const SizedBox(height: 12),
                      AuthErrorBanner(
                        message: state.noticeMessage!,
                        isNotice: true,
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        key: const Key('auth-submit'),
                        onPressed: busy ? null : _submit,
                        child: primaryLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isSignUp ? 'إنشاء الحساب' : 'تسجيل الدخول',
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _OrDivider(),
                    const SizedBox(height: 18),
                    GoogleSignInButton(
                      loading: state.action == AuthAction.google,
                      enabled: !busy,
                      onPressed: () => context.read<AuthBloc>().add(
                        const AuthGoogleSignInRequested(),
                      ),
                    ),
                    if (widget.onContinueAsGuest != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: busy ? null : widget.onContinueAsGuest,
                        child: const Text('متابعة كزائر'),
                      ),
                    ],
                    if (_isSignUp) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'بإنشاء حسابك، أنت موافق على شروط الاستخدام وسياسة الخصوصية.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 9.5,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isSignUp,
    required this.enabled,
    required this.onChanged,
  });

  final bool isSignUp;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeItem(
            label: 'دخول',
            selected: !isSignUp,
            enabled: enabled,
            onTap: () => onChanged(false),
          ),
          _ModeItem(
            label: 'حساب جديد',
            selected: isSignUp,
            enabled: enabled,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'أو',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
