import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_version.dart';
import '../../core/auth_errors.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/record_actions.dart';
import '../volunteers/volunteer_providers.dart';
import 'auth_providers.dart';

/// Schermata 1 del riferimento: logo, email, password, accesso.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const forgotPasswordKey = Key('login-password-dimenticata');
  static const versionKey = Key('login-versione');

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greenTint,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.card, AppColor.greenTint],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppDim.pagePad,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    AppDim.gapL * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDim.gapXl * 2),
                  const Center(child: AppLogo(variant: AppLogoVariant.hero)),
                  const SizedBox(height: AppDim.gapM),
                  const Text(
                    'Gestionale rifugio e adozioni',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.label,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                  const SizedBox(height: AppDim.gapXl),
                  AppTextField(
                    label: 'Email volontario',
                    hint: 'nome@associazione.it',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) => setState(() => _emailError = null),
                  ),
                  const SizedBox(height: AppDim.gapM),
                  AppTextField(
                    label: 'Password',
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onChanged: (_) => setState(() => _passwordError = null),
                    suffix: Tooltip(
                      message: _obscure
                          ? 'Mostra password'
                          : 'Nascondi password',
                      child: InkWell(
                        onTap: () => setState(() => _obscure = !_obscure),
                        customBorder: const CircleBorder(),
                        child: IconBadge(
                          _obscure
                              ? AppIcons.mostraPassword
                              : AppIcons.nascondiPassword,
                          size: IconBadge.inTitle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDim.gapS),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: LoginPage.forgotPasswordKey,
                      onPressed: _busy ? null : _forgotPassword,
                      child: const Text(
                        'Password dimenticata?',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w600,
                          color: AppColor.green,
                          height: AppDim.lineH,
                        ),
                      ),
                    ),
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: AppDim.gapS),
                    Text(
                      _formError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        color: AppColor.red,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDim.gapM),
                  AppButton(
                    label: _busy ? 'Accesso…' : 'Accedi',
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: AppDim.gapL),
                  Text(
                    key: LoginPage.versionKey,
                    'Versione ${ref.watch(appVersionProvider).maybeWhen(data: (v) => v, orElse: () => '…')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.faint,
                      height: AppDim.lineH,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    var emailError = email.isEmpty ? 'Inserisci l\'email.' : null;
    if (emailError == null && !_looksLikeEmail(email)) {
      emailError = italianAuthMessage('invalid-email');
    }
    setState(() {
      _emailError = emailError;
      _formError = null;
    });
    if (emailError != null) {
      return;
    }
    final ok = await confirmAction(
      context: context,
      title: 'Password dimenticata',
      message: 'Inviare l\'email di reimpostazione a $email?',
      confirmLabel: 'Invia',
    );
    if (!ok) {
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email);
      if (mounted) {
        AppToast.show(context, 'Email di reimpostazione inviata.');
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    var emailError = email.isEmpty ? 'Inserisci l\'email.' : null;
    if (emailError == null && !_looksLikeEmail(email)) {
      emailError = italianAuthMessage('invalid-email');
    }
    final passwordError = password.isEmpty ? 'Inserisci la password.' : null;

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });
    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      ref.read(sessionSecretsProvider).loginPassword = password;
      ref.read(sessionSecretsProvider).passwordChangeCompleted = false;
      refreshAuthSession(ref);
      final user = ref.read(authRepositoryProvider).currentUser;
      final service = ref.read(volunteerAccountServiceProvider);
      if (user != null && service != null) {
        await service.recordLogin(
          uid: user.uid,
          email: user.email,
          now: ref.read(dogListNowProvider),
          password: password,
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  static bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }
}
