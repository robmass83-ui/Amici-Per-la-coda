import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../data/data_providers.dart';
import '../../data/models/association_settings.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import '../dogs/dogs_providers.dart';

// ── CONTRATTO DI LAYOUT · Modifica dati associazione ───────────────────────
// AppSheet titolo "Dati associazione"
// ├ AppFormField  Denominazione
// ├ SizedBox 8
// ├ AppFormField  Codice fiscale
// ├ SizedBox 8
// ├ AppFormField  Sede
// ├ SizedBox 8
// ├ AppFormField  Capienza autorizzata  (cifre)
// ├ SizedBox 12
// └ AppButton  Salva
// ───────────────────────────────────────────────────────────────────────────

class EditAssociationSheet extends ConsumerStatefulWidget {
  const EditAssociationSheet({super.key, required this.current});

  final AssociationSettings? current;

  static const denominazioneKey = Key('associazione-denominazione');
  static const cfKey = Key('associazione-cf');
  static const sedeKey = Key('associazione-sede');
  static const capienzaKey = Key('associazione-capienza');
  static const telefonoKey = Key('associazione-telefono');
  static const emailKey = Key('associazione-email');
  static const salvaKey = Key('associazione-salva');

  static Future<void> open(
    BuildContext context, {
    required AssociationSettings? current,
  }) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => EditAssociationSheet(current: current),
    );
  }

  @override
  ConsumerState<EditAssociationSheet> createState() =>
      _EditAssociationSheetState();
}

class _EditAssociationSheetState extends ConsumerState<EditAssociationSheet> {
  late final TextEditingController _denominazione;
  late final TextEditingController _cf;
  late final TextEditingController _sede;
  late final TextEditingController _capienza;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _denominazione = TextEditingController(text: current?.denominazione ?? '');
    _cf = TextEditingController(text: current?.codiceFiscale ?? '');
    _sede = TextEditingController(text: current?.sede ?? '');
    _capienza = TextEditingController(
      text: current == null ? '' : '${current.capienzaAutorizzata}',
    );
    _telefono = TextEditingController(text: current?.telefono ?? '');
    _email = TextEditingController(text: current?.email ?? '');
  }

  @override
  void dispose() {
    _denominazione.dispose();
    _cf.dispose();
    _sede.dispose();
    _capienza.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null || _busy) {
      return;
    }
    final capienza = int.tryParse(_capienza.text.trim());
    if (capienza == null || capienza <= 0) {
      AppToast.show(context, 'Indica la capienza autorizzata.');
      return;
    }
    final nome = _denominazione.text.trim();
    if (nome.isEmpty) {
      AppToast.show(context, 'Indica la denominazione.');
      return;
    }
    setState(() => _busy = true);
    final now = ref.read(dogListNowProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final previous = widget.current;
    final audit = previous == null
        ? Audit.seed(now, by: uid)
        : previous.audit.touched(uid, now);
    final next = (previous ??
            AssociationSettings(
              denominazione: nome,
              codiceFiscale: _cf.text.trim(),
              sede: _sede.text.trim(),
              capienzaAutorizzata: capienza,
              logoB64: null,
              audit: audit,
            ))
        .copyWith(
          denominazione: nome,
          codiceFiscale: _cf.text.trim(),
          sede: _sede.text.trim(),
          capienzaAutorizzata: capienza,
          telefono: _telefono.text.trim(),
          email: _email.text.trim(),
          audit: audit,
        );
    try {
      await repo.saveAssociation(next);
      if (mounted) {
        Navigator.of(context).pop();
        AppToast.show(context, 'Dati associazione salvati.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        AppToast.show(context, 'Salvataggio non riuscito.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Dati associazione',
      children: [
        AppFormField(
          key: EditAssociationSheet.denominazioneKey,
          label: 'Denominazione',
          controller: _denominazione,
        ),
        const SizedBox(height: AppDim.formRowGap),
        AppFormField(
          key: EditAssociationSheet.cfKey,
          label: 'Codice fiscale',
          controller: _cf,
        ),
        const SizedBox(height: AppDim.formRowGap),
        AppFormField(
          key: EditAssociationSheet.sedeKey,
          label: 'Sede',
          controller: _sede,
        ),
        const SizedBox(height: AppDim.formRowGap),
        AppFormField(
          key: EditAssociationSheet.capienzaKey,
          label: 'Capienza autorizzata',
          controller: _capienza,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppDim.formRowGap),
        AppFormField(
          key: EditAssociationSheet.telefonoKey,
          label: 'Telefono',
          controller: _telefono,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppDim.formRowGap),
        AppFormField(
          key: EditAssociationSheet.emailKey,
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppDim.gapL),
        AppButton(
          key: EditAssociationSheet.salvaKey,
          label: 'Salva',
          onPressed: _busy ? null : () => unawaited(_save()),
        ),
      ],
    );
  }
}
