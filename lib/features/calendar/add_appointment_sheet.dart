import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/appointment.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import '../adoptions/adoption_labels.dart';
import '../auth/auth_providers.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/pick_dog_sheet.dart';
import '../dogs/record_actions.dart';
import '../dogs/tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Appuntamento (AppDialog) ────────────────────────────
// Header  AppIcons.data
// Body  gap 8
// ├ TIPO  Wrap AppChip
// ├ TITOLO
// ├ FormRow2  DATA | ORA  (ORA disabilitata se tutto il giorno)
// ├ FormRow2  CANE | RICHIESTA  opzionali
// ├ LUOGO
// └ ☐ Tutto il giorno  riga 30
// Footer  [🗑 se existing] Annulla | Salva
// ───────────────────────────────────────────────────────────────────────────

class AddAppointmentSheet extends ConsumerStatefulWidget {
  const AddAppointmentSheet({super.key, this.existing, this.initialDay});

  static const titoloKey = Key('appointment-titolo');
  static const saveKey = Key('appointment-save');
  static const caneKey = Key('appointment-cane');
  static const richiestaKey = Key('appointment-richiesta');
  static const tuttoIlGiornoKey = Key('appointment-tutto-il-giorno');

  final Appointment? existing;
  final DateTime? initialDay;

  static Future<void> open(
    BuildContext context, {
    Appointment? existing,
    DateTime? initialDay,
  }) {
    return AppDialog.show<void>(
      context: context,
      form: AddAppointmentSheet(existing: existing, initialDay: initialDay),
    );
  }

  @override
  ConsumerState<AddAppointmentSheet> createState() =>
      _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends ConsumerState<AddAppointmentSheet> {
  final _titolo = TextEditingController();
  final _data = TextEditingController();
  final _ora = TextEditingController();
  final _luogo = TextEditingController();
  AppointmentTipo _tipo = AppointmentTipo.visita;
  String? _error;
  String? _dogId;
  String? _adoptionId;
  var _tuttoIlGiorno = false;
  var _saving = false;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = ref.read(dogListNowProvider);
    if (existing != null) {
      _tipo = existing.tipo;
      _titolo.text = existing.titolo;
      _data.text = formatItalianDate(existing.inizio);
      _ora.text = formatItalianTime(existing.inizio);
      _luogo.text = existing.luogo;
      _dogId = existing.dogId;
      _adoptionId = existing.adoptionId;
      _tuttoIlGiorno = existing.tuttoIlGiorno;
    } else {
      final day = widget.initialDay ?? now;
      _data.text = formatItalianDate(day);
      _ora.text = formatItalianTime(now);
    }
    _initial = _snapshot();
    for (final controller in [_titolo, _data, _ora, _luogo]) {
      controller.addListener(_mark);
    }
  }

  @override
  void dispose() {
    for (final controller in [_titolo, _data, _ora, _luogo]) {
      controller.removeListener(_mark);
      controller.dispose();
    }
    super.dispose();
  }

  void _mark() => setState(() {});

  String _snapshot() {
    return [
      _tipo.wire,
      _titolo.text,
      _data.text,
      _ora.text,
      _luogo.text,
      _dogId ?? '',
      _adoptionId ?? '',
      _tuttoIlGiorno ? '1' : '0',
    ].join('|');
  }

  DateTime? _parseInizio() {
    final day = parseItalianDate(_data.text);
    if (day == null) {
      return null;
    }
    if (_tuttoIlGiorno) {
      return DateTime(day.year, day.month, day.day);
    }
    return parseItalianTime(_ora.text, day);
  }

  bool get _canSave {
    if (_titolo.text.trim().isEmpty) {
      return false;
    }
    return _parseInizio() != null;
  }

  Future<void> _save() async {
    final titolo = _titolo.text.trim();
    if (titolo.isEmpty) {
      setState(() => _error = 'Inserisci un titolo.');
      return;
    }
    final inizio = _parseInizio();
    if (inizio == null) {
      setState(() => _error = 'Data o ora non valida.');
      return;
    }
    final repo = ref.read(appointmentRepositoryProvider);
    if (repo == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        await repo.save(
          existing.copyWith(
            tipo: _tipo,
            titolo: titolo,
            inizio: inizio,
            luogo: _luogo.text.trim(),
            dogId: _dogId,
            clearDogId: _dogId == null,
            adoptionId: _adoptionId,
            clearAdoptionId: _adoptionId == null,
            tuttoIlGiorno: _tuttoIlGiorno,
            audit: existing.audit.touched(userId, now),
          ),
        );
      } else {
        await repo.save(
          Appointment(
            id: 'ap_${now.microsecondsSinceEpoch}',
            tipo: _tipo,
            titolo: titolo,
            dogId: _dogId,
            adoptionId: _adoptionId,
            inizio: inizio,
            fine: null,
            tuttoIlGiorno: _tuttoIlGiorno,
            luogo: _luogo.text.trim(),
            stato: AppointmentStato.previsto,
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
        setState(() => _error = 'Salvataggio non riuscito. Riprova.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    final appointments = ref.read(appointmentRepositoryProvider);
    final ok = await confirmDeleteNamed(
      context,
      'l\'appuntamento «${existing.titolo}»',
    );
    if (!ok) {
      return;
    }
    await appointments?.delete(existing.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  String _dogHint(List<Dog> dogs) {
    final id = _dogId;
    if (id == null) {
      return 'Nessuno';
    }
    for (final dog in dogs) {
      if (dog.id == id) {
        return dogDisplayName(dog.nome);
      }
    }
    return 'Cane non trovato';
  }

  String _richiestaHint(List<Adoption> adoptions) {
    final id = _adoptionId;
    if (id == null) {
      return 'Nessuna';
    }
    for (final adoption in adoptions) {
      if (adoption.id == id) {
        final name =
            '${adoption.richiedente.nome} ${adoption.richiedente.cognome}'
                .trim();
        return name.isEmpty ? adoptionListBadgeLabel(adoption.stato) : name;
      }
    }
    return 'Richiesta non trovata';
  }

  Future<void> _pickDog() async {
    final pick = await PickDogSheet.show(context, noneLabel: 'Nessun cane');
    if (pick == null || !mounted) {
      return;
    }
    setState(() {
      _dogId = pick.dogId;
      if (_dogId == null) {
        _adoptionId = null;
        return;
      }
      final stillValid = ref
          .read(adoptionsStreamProvider)
          .maybeWhen(
            data: (items) => items.any(
              (item) => item.id == _adoptionId && item.dogId == _dogId,
            ),
            orElse: () => false,
          );
      if (!stillValid) {
        _adoptionId = null;
      }
    });
  }

  Future<void> _pickRichiesta(List<Adoption> adoptions) async {
    final dogId = _dogId;
    if (dogId == null) {
      return;
    }
    final filtered = adoptions.where((item) => item.dogId == dogId).toList();
    final chosen = await AppSheet.present<String?>(
      context: context,
      builder: (context) {
        return AppSheet(
          title: 'Richiesta',
          children: [
            OptionRow(
              icon: const IconBadge(AppIcons.richieste, size: IconBadge.inMenu),
              title: 'Nessuna richiesta',
              subtitle: 'Campo lasciato vuoto',
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final adoption in filtered)
              OptionRow(
                key: Key('appointment-richiesta-${adoption.id}'),
                icon: const IconBadge(
                  AppIcons.richieste,
                  size: IconBadge.inMenu,
                ),
                title:
                    '${adoption.richiedente.nome} ${adoption.richiedente.cognome}'
                        .trim()
                        .isEmpty
                    ? '—'
                    : '${adoption.richiedente.nome} ${adoption.richiedente.cognome}'
                          .trim(),
                subtitle: adoptionListBadgeLabel(adoption.stato),
                onTap: () => Navigator.of(context).pop(adoption.id),
              ),
          ],
        );
      },
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() => _adoptionId = chosen.isEmpty ? null : chosen);
  }

  @override
  Widget build(BuildContext context) {
    final dogs = ref
        .watch(dogsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Dog>[]);
    final adoptions = ref
        .watch(adoptionsStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Adoption>[]);
    return AppDialog(
      icon: AppIcons.data,
      title: widget.existing == null
          ? 'Nuovo appuntamento'
          : 'Modifica appuntamento',
      canSave: _canSave,
      isDirty: _snapshot() != _initial,
      saving: _saving,
      saveKey: AddAppointmentSheet.saveKey,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            label: 'Tipo',
            child: Wrap(
              spacing: AppDim.gapS,
              runSpacing: AppDim.gapS,
              children: [
                for (final tipo in AppointmentTipo.values)
                  AppChip(
                    label: appointmentTipoLabel(tipo),
                    selected: _tipo == tipo,
                    height: AppDim.formChipH,
                    padding: AppDim.formChipPad,
                    onSelected: () => setState(() => _tipo = tipo),
                  ),
              ],
            ),
          ),
          const DialogBodyGap(),
          AppFormField(
            key: AddAppointmentSheet.titoloKey,
            label: 'Titolo',
            controller: _titolo,
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              label: 'Data',
              hint: 'gg/mm/aaaa',
              controller: _data,
              readOnly: true,
              suffix: dateFieldSuffix(
                onTap: () => pickAppDate(context, _data),
              ),
              onTap: () => pickAppDate(context, _data),
            ),
            right: AppFormField(
              label: 'Ora',
              hint: 'hh:mm',
              controller: _ora,
              enabled: !_tuttoIlGiorno,
              readOnly: true,
              onTap: _tuttoIlGiorno
                  ? null
                  : () => pickAppTime(context, _ora),
            ),
          ),
          const DialogBodyGap(),
          FormRow2(
            left: AppFormField(
              key: AddAppointmentSheet.caneKey,
              label: 'Cane',
              hint: _dogHint(dogs),
              onTap: _pickDog,
            ),
            right: AppFormField(
              key: AddAppointmentSheet.richiestaKey,
              label: 'Richiesta',
              hint: _richiestaHint(adoptions),
              onTap: _dogId == null ? null : () => _pickRichiesta(adoptions),
            ),
          ),
          const DialogBodyGap(),
          AppFormField(label: 'Luogo', controller: _luogo),
          const DialogBodyGap(),
          _AllDayRow(
            key: AddAppointmentSheet.tuttoIlGiornoKey,
            value: _tuttoIlGiorno,
            onChanged: (value) => setState(() => _tuttoIlGiorno = value),
          ),
          if (_error != null) ...[
            const DialogBodyGap(),
            Text(
              _error!,
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

class _AllDayRow extends StatelessWidget {
  const _AllDayRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.checkRowH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            SizedBox(
              width: AppDim.checkBox,
              height: AppDim.checkBox,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: value ? AppColor.green : AppColor.card,
                  borderRadius: BorderRadius.circular(AppDim.gapXs),
                  border: Border.all(
                    color: value ? AppColor.green : AppColor.line,
                  ),
                ),
                child: value
                    ? const Center(
                        child: Text(
                          '✓',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: AppText.micro,
                            fontWeight: FontWeight.w700,
                            color: AppColor.card,
                            height: 1,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppDim.gapS),
            const Expanded(
              child: Text(
                'Tutto il giorno',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.body,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
