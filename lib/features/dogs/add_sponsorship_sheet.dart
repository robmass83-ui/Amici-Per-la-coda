import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/sponsorship.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import 'dogs_providers.dart';
import 'record_actions.dart';

// ── CONTRATTO DI LAYOUT · Adozione a distanza (AppDialog) ────────────────────
// Header  AppIcons.aDistanza
// Body  gap 8
// ├ FormRow2  NOME | COGNOME
// ├ FormRow2  EMAIL | TELEFONO
// ├ FormRow2  IMPORTO MENSILE (€) | DAL
// └ NOTE
// Footer  [Chiudi adozione se existing] Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class AddSponsorshipSheet extends ConsumerStatefulWidget {
  const AddSponsorshipSheet({super.key, required this.dogId, this.existing});

  static const nomeKey = Key('dog-sponsorship-nome');
  static const importoKey = Key('dog-sponsorship-importo');
  static const saveKey = Key('dog-sponsorship-save');

  final String dogId;
  final Sponsorship? existing;

  static Future<void> open(
    BuildContext context, {
    required String dogId,
    Sponsorship? existing,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddSponsorshipSheet(dogId: dogId, existing: existing),
    );
  }

  @override
  ConsumerState<AddSponsorshipSheet> createState() =>
      _AddSponsorshipSheetState();
}

class _AddSponsorshipSheetState extends ConsumerState<AddSponsorshipSheet> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _importo = TextEditingController();
  final _dal = TextEditingController();
  final _note = TextEditingController();
  String? _nomeError;
  String? _importoError;
  String? _dalError;
  String? _formError;
  var _saving = false;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nome.text = existing.sostenitore.nome;
      _cognome.text = existing.sostenitore.cognome;
      _email.text = existing.sostenitore.email;
      _telefono.text = existing.sostenitore.telefono;
      _importo.text = formatItalianNumber(existing.importoMensile);
      _dal.text = formatItalianDate(existing.dal);
      _note.text = existing.note;
    } else {
      _dal.text = formatItalianDate(ref.read(dogListNowProvider));
    }
    _initial = _snapshot();
    for (final controller in [
      _nome,
      _cognome,
      _email,
      _telefono,
      _importo,
      _dal,
      _note,
    ]) {
      controller.addListener(_mark);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nome,
      _cognome,
      _email,
      _telefono,
      _importo,
      _dal,
      _note,
    ]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() {
    return [
      _nome.text,
      _cognome.text,
      _email.text,
      _telefono.text,
      _importo.text,
      _dal.text,
      _note.text,
    ].join('|');
  }

  bool get _canSave {
    final importo = parseItalianDecimal(_importo.text);
    return _nome.text.trim().isNotEmpty &&
        importo != null &&
        importo > 0 &&
        parseItalianDate(_dal.text) != null;
  }

  Future<void> _save() async {
    if (_nome.text.trim().isEmpty) {
      setState(() => _nomeError = 'Inserisci il nome del sostenitore.');
      return;
    }
    final importo = parseItalianDecimal(_importo.text);
    if (importo == null || importo <= 0) {
      setState(() => _importoError = 'Inserisci un importo mensile valido.');
      return;
    }
    final dal = parseItalianDate(_dal.text);
    if (dal == null) {
      setState(() => _dalError = 'Data non valida (gg/mm/aaaa).');
      return;
    }
    final repo = ref.read(sponsorshipRepositoryProvider);
    if (repo == null) {
      setState(() => _formError = 'Archivio non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    final sostenitore = Sostenitore(
      nome: _nome.text.trim(),
      cognome: _cognome.text.trim(),
      email: _email.text.trim(),
      telefono: _telefono.text.trim(),
    );
    setState(() {
      _saving = true;
      _formError = null;
      _nomeError = null;
      _importoError = null;
      _dalError = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        await repo.save(
          existing.copyWith(
            sostenitore: sostenitore,
            importoMensile: importo,
            dal: dal,
            note: _note.text.trim(),
            audit: existing.audit.touched(userId, now),
          ),
        );
      } else {
        await repo.save(
          Sponsorship(
            id: 's_${now.microsecondsSinceEpoch}',
            dogId: widget.dogId,
            sostenitore: sostenitore,
            importoMensile: importo,
            attiva: true,
            dal: dal,
            al: null,
            note: _note.text.trim(),
            audit: Audit(
              createdAt: now,
              createdBy: userId,
              updatedAt: now,
              updatedBy: userId,
            ),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Salvataggio non riuscito. Riprova.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _closeSponsorship() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    final nome =
        '${existing.sostenitore.nome} ${existing.sostenitore.cognome}'.trim();
    final sponsorships = ref.read(sponsorshipRepositoryProvider);
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final ok = await confirmAction(
      context: context,
      title: 'Chiudi adozione a distanza',
      message: 'Chiudere l\'adozione a distanza di $nome?',
      confirmLabel: 'Chiudi',
    );
    if (!ok) {
      return;
    }
    final now = DateTime.now();
    await sponsorships?.save(
      existing.copyWith(
        attiva: false,
        al: now,
        audit: existing.audit.touched(uid, now),
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: AppIcons.aDistanza,
      title: widget.existing == null
          ? 'Adozione a distanza'
          : 'Modifica adozione a distanza',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _saving,
      saveKey: AddSponsorshipSheet.saveKey,
      onSave: _save,
      onDelete: widget.existing == null ? null : _closeSponsorship,
      deleteLabel: widget.existing == null ? null : 'Chiudi adozione',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormRow2(
            left: AppFormField(
              key: AddSponsorshipSheet.nomeKey,
              label: 'Nome',
              controller: _nome,
              errorText: _nomeError,
            ),
            right: AppFormField(label: 'Cognome', controller: _cognome),
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            right: AppFormField(
              label: 'Telefono',
              controller: _telefono,
              keyboardType: TextInputType.phone,
            ),
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              key: AddSponsorshipSheet.importoKey,
              label: 'Importo mensile (€)',
              controller: _importo,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: _importoError,
            ),
            right: AppFormField(
              label: 'Dal',
              hint: 'gg/mm/aaaa',
              controller: _dal,
              readOnly: true,
              errorText: _dalError,
              suffix: dateFieldSuffix(
                onTap: () => pickAppDate(context, _dal),
              ),
              onTap: () => pickAppDate(context, _dal),
            ),
          ),
          const DialogBodyGap(),
          AppFormField(label: 'Note', controller: _note),
          if (_formError != null) ...[
            const DialogBodyGap(),
            Text(
              _formError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.red,
                height: AppDim.lineH,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
