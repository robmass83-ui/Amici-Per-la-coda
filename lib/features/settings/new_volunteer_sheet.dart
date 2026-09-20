import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_errors.dart';
import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';
import '../volunteers/volunteer_account_service.dart';
import '../volunteers/volunteer_labels.dart';
import '../volunteers/volunteer_privilege_picker.dart';
import '../volunteers/volunteer_providers.dart';

// ── CONTRATTO DI LAYOUT · Nuovo volontario (AppDialog) ──────────────────────
// Header  AppIcons.volontari  «Nuovo volontario»
// Body  gap 8
// ├ FormRow2  NOME * | COGNOME *
// ├ EMAIL *
// ├ PASSWORD INIZIALE *  mostra/nascondi + Genera
// ├ testo 10sp  muted (vuota) / rosso (1–7 caratteri): minimo 8, altrimenti
// │  non si può procedere
// ├ VolunteerPrivilegePicker
// ├ testo 10sp muted  primo accesso
// ├ se errore: testo 10sp rosso (maxLines 4)
// └ se profilo disattivato: AppButton ghost «Riattiva account» h=40
// Footer  Annulla | Salva (Crea account)
// ───────────────────────────────────────────────────────────────────────────

class NewVolunteerSheet extends ConsumerStatefulWidget {
  const NewVolunteerSheet({super.key});

  static const nomeKey = Key('new-volunteer-nome');
  static const cognomeKey = Key('new-volunteer-cognome');
  static const emailKey = Key('new-volunteer-email');
  static const passwordKey = Key('new-volunteer-password');
  static const passwordHintKey = Key('new-volunteer-password-hint');
  static const generaKey = Key('new-volunteer-genera');
  static const creaKey = Key('new-volunteer-crea');
  static const ruoloKey = Key('new-volunteer-ruolo');
  static const riattivaKey = Key('new-volunteer-riattiva');

  static Future<void> show(BuildContext context) {
    return AppDialog.show<void>(
      context: context,
      form: const NewVolunteerSheet(),
    );
  }

  @override
  ConsumerState<NewVolunteerSheet> createState() => _NewVolunteerSheetState();
}

class _NewVolunteerSheetState extends ConsumerState<NewVolunteerSheet> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _ruolo = VolunteerRuolo.volontario;
  bool _obscure = true;
  bool _busy = false;
  String? _nomeError;
  String? _cognomeError;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  Volunteer? _inactiveVolunteer;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    _initial = _snapshot();
    for (final controller in [_nome, _cognome, _email, _password]) {
      controller.addListener(_mark);
    }
    _email.addListener(_clearInactive);
  }

  @override
  void dispose() {
    _email.removeListener(_clearInactive);
    for (final controller in [_nome, _cognome, _email, _password]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  void _clearInactive() {
    if (_inactiveVolunteer == null && _formError == null) {
      return;
    }
    setState(() {
      _inactiveVolunteer = null;
      _formError = null;
    });
  }

  String _snapshot() {
    return '${_nome.text}|${_cognome.text}|${_email.text}|${_password.text}|${_ruolo.wire}';
  }

  bool get _canSave {
    return _nome.text.trim().isNotEmpty &&
        _cognome.text.trim().isNotEmpty &&
        looksLikeEmail(_email.text.trim()) &&
        _password.text.length >= 8;
  }

  bool get _passwordTooShort =>
      _password.text.isNotEmpty && _password.text.length < 8;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: AppIcons.volontari,
      title: 'Nuovo volontario',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _busy,
      saveLabel: 'Crea account',
      saveKey: NewVolunteerSheet.creaKey,
      onSave: _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormRow2(
            left: AppFormField(
              key: NewVolunteerSheet.nomeKey,
              label: 'Nome *',
              controller: _nome,
              errorText: _nomeError,
            ),
            right: AppFormField(
              key: NewVolunteerSheet.cognomeKey,
              label: 'Cognome *',
              controller: _cognome,
              errorText: _cognomeError,
            ),
          ),
          const DialogBodyGap(),
          AppFormField(
            key: NewVolunteerSheet.emailKey,
            label: 'Email *',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
          const DialogBodyGap(),
          AppFormField(
            key: NewVolunteerSheet.passwordKey,
            label: 'Password iniziale *',
            controller: _password,
            hint: 'Almeno 8 caratteri',
            obscureText: _obscure,
            errorText: _passwordError,
            suffix: Tooltip(
              message: _obscure ? 'Mostra password' : 'Nascondi password',
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
          if (_password.text.length < 8) ...[
            const SizedBox(height: AppDim.gapXs),
            Text(
              key: NewVolunteerSheet.passwordHintKey,
              _passwordTooShort
                  ? 'La password inserita è troppo corta: servono almeno '
                      '8 caratteri, altrimenti non si può creare l\'account.'
                  : 'Almeno 8 caratteri. Se è più corta, Crea account resta '
                      'disattivato.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: _passwordTooShort ? AppColor.red : AppColor.muted,
                height: AppDim.lineH,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: NewVolunteerSheet.generaKey,
              onPressed: () {
                _password.text = generateInitialPassword();
                setState(() => _passwordError = null);
              },
              child: const Text(
                'Genera',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  fontWeight: FontWeight.w700,
                  color: AppColor.green,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ),
          VolunteerPrivilegePicker(
            key: NewVolunteerSheet.ruoloKey,
            selected: _ruolo,
            onChanged: (ruolo) => setState(() => _ruolo = ruolo),
          ),
          const DialogBodyGap(),
          const Text(
            'Il volontario dovrà cambiare la password al primo accesso. '
            'Comunicagli email e password a voce o di persona.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.caption,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
          if (_formError != null) ...[
            const DialogBodyGap(),
            Text(
              _formError!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.red,
                height: AppDim.lineH,
              ),
            ),
          ],
          if (_inactiveVolunteer != null) ...[
            const DialogBodyGap(),
            AppButton(
              key: NewVolunteerSheet.riattivaKey,
              label: 'Riattiva account',
              variant: AppButtonVariant.ghost,
              onPressed: _busy ? null : () => unawaited(_riattiva()),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final nome = _nome.text.trim();
    final cognome = _cognome.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _nomeError = nome.isEmpty ? 'Obbligatorio.' : null;
      _cognomeError = cognome.isEmpty ? 'Obbligatorio.' : null;
      _emailError = looksLikeEmail(email)
          ? null
          : italianAuthMessage('invalid-email');
      _passwordError = password.length < 8
          ? 'Password troppo corta: minimo 8 caratteri. Non si può procedere.'
          : null;
      _formError = null;
      _inactiveVolunteer = null;
    });
    if (_nomeError != null ||
        _cognomeError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }
    final service = ref.read(volunteerAccountServiceProvider);
    if (service == null) {
      setState(() => _formError = 'Archivio non disponibile.');
      return;
    }
    setState(() => _busy = true);
    try {
      final created = await service.createVolunteer(
        nome: nome,
        cognome: cognome,
        email: email,
        password: password,
        ruolo: _ruolo,
        now: ref.read(dogListNowProvider),
      );
      if (!mounted) {
        return;
      }
      AppToast.show(
        context,
        'Account creato per ${volunteerDisplayName(created)}',
      );
      Navigator.of(context, rootNavigator: true).pop();
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } on VolunteerAccountException catch (error) {
      if (mounted) {
        setState(() {
          _formError = error.message;
          _inactiveVolunteer = error.inactiveVolunteer;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _riattiva() async {
    final volunteer = _inactiveVolunteer;
    if (volunteer == null) {
      return;
    }
    final service = ref.read(volunteerAccountServiceProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (service == null) {
      setState(() => _formError = 'Archivio non disponibile.');
      return;
    }
    final all = ref.read(volunteersStreamProvider).maybeWhen(
      data: (items) => items,
      orElse: () => const <Volunteer>[],
    );
    setState(() => _busy = true);
    try {
      await service.setAttivo(
        volunteer: volunteer,
        attivo: true,
        editorUid: uid,
        now: ref.read(dogListNowProvider),
        all: all,
      );
      if (!mounted) {
        return;
      }
      AppToast.show(
        context,
        'Account di ${volunteerDisplayName(volunteer)} riattivato.',
      );
      Navigator.of(context, rootNavigator: true).pop();
    } on VolunteerAccountException catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
