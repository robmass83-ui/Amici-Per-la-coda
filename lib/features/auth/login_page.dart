import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_errors.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'auth_providers.dart';

/// Schermata 1 del riferimento: logo, email, password, resta collegato.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _staySignedIn = true;
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _staySignedIn = !_staySignedIn),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: AppDim.minTouch,
                              height: AppDim.minTouch,
                              child: Checkbox(
                                value: _staySignedIn,
                                onChanged: (value) {
                                  setState(() => _staySignedIn = value ?? true);
                                },
                                activeColor: AppColor.green,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const Text(
                              'Resta collegato',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: AppText.caption,
                                color: AppColor.muted,
                                height: AppDim.lineH,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => AppToast.show(
                          context,
                          'Chiedi al presidente di reimpostare la password.',
                        ),
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
                    ],
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
                  const Text(
                    'Versione 1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
