import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_errors.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../volunteers/volunteer_account_service.dart';
import '../volunteers/volunteer_providers.dart';
import 'auth_providers.dart';

// ── CONTRATTO DI LAYOUT · Scegli la tua password ───────────────────────────
// SCHERMATA A SCHERMO INTERO  NESSUNA bottom nav  NESSUN FAB  nessun indietro
// AppScaffold compactHeader  titolo "Scegli la tua password"
// └ ListView padding=12
//    ├ AppFormField  NUOVA PASSWORD *   h=34  mostra/nascondi
//    ├ SizedBox 9
//    ├ AppFormField  RIPETI PASSWORD *  h=34  mostra/nascondi
//    ├ SizedBox 12
//    ├ AppButton "Salva password"  larghezza piena
//    ├ SizedBox 12
//    └ Center  AppButton ghost "Esci"  larghezza contenuta
// PopScope canPop=false  (Esci fa logout, non salta il cambio password)
// ───────────────────────────────────────────────────────────────────────────

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  static const nuovaKey = Key('change-password-nuova');
  static const ripetiKey = Key('change-password-ripeti');
  static const salvaKey = Key('change-password-salva');
  static const esciKey = Key('change-password-esci');
  static const listKey = Key('change-password-list');

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _nuova = TextEditingController();
  final _ripeti = TextEditingController();
  bool _obscureNuova = true;
  bool _obscureRipeti = true;
  bool _busy = false;
  String? _nuovaError;
  String? _ripetiError;
  String? _formError;

  @override
  void dispose() {
    _nuova.dispose();
    _ripeti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: 'Scegli la tua password',
        compactHeader: true,
        body: ListView(
          key: ChangePasswordPage.listKey,
          padding: AppDim.pagePad,
          children: [
            AppFormField(
              key: ChangePasswordPage.nuovaKey,
              label: 'Nuova password *',
              controller: _nuova,
              obscureText: _obscureNuova,
              errorText: _nuovaError,
              suffix: _eye(
                obscure: _obscureNuova,
                onTap: () => setState(() => _obscureNuova = !_obscureNuova),
              ),
            ),
            const SizedBox(height: AppDim.gapM),
            AppFormField(
              key: ChangePasswordPage.ripetiKey,
              label: 'Ripeti password *',
              controller: _ripeti,
              obscureText: _obscureRipeti,
              errorText: _ripetiError,
              suffix: _eye(
                obscure: _obscureRipeti,
                onTap: () => setState(() => _obscureRipeti = !_obscureRipeti),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: AppDim.gapS),
              Text(
                _formError!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  color: AppColor.red,
                  height: AppDim.lineH,
                ),
              ),
            ],
            const SizedBox(height: AppDim.gapL),
            AppButton(
              key: ChangePasswordPage.salvaKey,
              label: _busy ? 'Salvataggio…' : 'Salva password',
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: AppDim.gapL),
            Center(
              child: AppButton(
                key: ChangePasswordPage.esciKey,
                label: 'Esci',
                variant: AppButtonVariant.ghost,
                expand: false,
                onPressed: _busy ? null : _esci,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eye({required bool obscure, required VoidCallback onTap}) {
    return Tooltip(
      message: obscure ? 'Mostra password' : 'Nascondi password',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: IconBadge(
          obscure ? AppIcons.mostraPassword : AppIcons.nascondiPassword,
          size: IconBadge.inTitle,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final nuova = _nuova.text;
    final ripeti = _ripeti.text;
    String? nuovaError;
    String? ripetiError;
    if (nuova.length < 8) {
      nuovaError = 'Minimo 8 caratteri.';
    }
    if (ripeti != nuova) {
      ripetiError = 'Le password non coincidono.';
    }
    setState(() {
      _nuovaError = nuovaError;
      _ripetiError = ripetiError;
      _formError = null;
    });
    if (nuovaError != null || ripetiError != null) {
      return;
    }
    final service = ref.read(volunteerAccountServiceProvider);
    if (service == null) {
      setState(() => _formError = 'Archivio non disponibile.');
      return;
    }
    setState(() => _busy = true);
    try {
      await service.completePasswordChange(
        nuova,
        currentPassword: ref.read(sessionSecretsProvider).loginPassword,
      );
      final secrets = ref.read(sessionSecretsProvider);
      secrets.passwordChangeCompleted = true;
      secrets.loginPassword = null;
      if (mounted) {
        context.go('/');
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } on VolunteerAccountException catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _formError =
              'Non è stato possibile salvare la password. Riprova.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _esci() async {
    await ref.read(authRepositoryProvider).signOut();
    onSignedOut(ref);
  }
}
