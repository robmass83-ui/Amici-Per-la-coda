import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/volunteer.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';
import 'dog_labels.dart';
import 'dog_stato.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Cambio stato ─────────────────────────────────────
// Column
// ├ SafeArea bottom=false
// │  └ AppHeader h=44  back 34×34  titolo «Stato di {nome}» 1 riga ellipsis
// └ Expanded ListView padding=12
//    ├ AppCard  fondo greenTint  bordo greenSoft  padding=12
//    │  Row
//    │   ├ IconBadge perStato  32×32
//    │   ├ SizedBox 9
//    │   └ Expanded Column
//    │      ├ Text stato  13sp w800  maxLines=1 ellipsis
//    │      └ Text box/giorni  10.5sp muted  maxLines=2 ellipsis
//    ├ SizedBox 12
//    ├ SectionTitle Cambia stato  icona 20
//    ├ SizedBox 9
//    ├ AppCard padding 10
//    │  └ 7 × riga  minHeight=40
//    │     IconBadge 32 · titolo 12sp · sottotitolo 10sp · radio 18
//    ├ SizedBox 12
//    ├ SectionTitle Dettagli del cambio  icona 20
//    ├ SizedBox 9
//    ├ AppTextField Data effettiva  h=40
//    ├ SizedBox 9
//    ├ AppTextField Motivazione  h=64  maxLines=3
//    ├ SizedBox 9
//    ├ AppTextField Volontario  h=40  readOnly → sheet
//    ├ SizedBox 6
//    └ AppButton Salva nuovo stato  h=40
// ───────────────────────────────────────────────────────────────────────────

class ChangeStatusPage extends ConsumerStatefulWidget {
  const ChangeStatusPage({super.key, required this.dogId});

  final String dogId;

  static const saveKey = Key('stato-salva');
  static const dataKey = Key('stato-data');
  static const noteKey = Key('stato-note');
  static const autoreKey = Key('stato-autore');
  static const confirmKey = Key('stato-conferma');
  static const cancelKey = Key('stato-annulla');

  static Key optionKey(DogStato stato) => Key('stato-opt-${stato.wire}');

  @override
  ConsumerState<ChangeStatusPage> createState() => _ChangeStatusPageState();
}

class _ChangeStatusPageState extends ConsumerState<ChangeStatusPage> {
  final _data = TextEditingController();
  final _note = TextEditingController();
  final _autore = TextEditingController();
  DogStato? _selected;
  String? _autoreId;
  String? _dataError;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final now = ref.read(dogListNowProvider);
      _data.text = formatItalianDate(now);
      _autoreId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _data.dispose();
    _note.dispose();
    _autore.dispose();
    super.dispose();
  }

  Future<void> _pickAutore(List<Volunteer> volunteers) async {
    final attivi = volunteers.where((item) => item.attivo).toList();
    await AppSheet.show<void>(
      context: context,
      title: 'Volontario che registra',
      children: [
        for (final volunteer in attivi)
          OptionRow(
            icon: const IconBadge(AppIcons.volontari, size: IconBadge.inMenu),
            title: volunteer.nome,
            subtitle: volunteer.email,
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _autoreId = volunteer.id;
                _autore.text = volunteer.nome;
              });
            },
          ),
      ],
    );
  }

  Future<void> _save(Dog dog) async {
    final selected = _selected;
    if (selected == null) {
      return;
    }
    if (!statoTransitionAllowed(dog.stato, selected)) {
      AppToast.show(
        context,
        dog.stato == selected
            ? 'Seleziona uno stato diverso da quello attuale.'
            : 'Transizione non ammessa.',
      );
      return;
    }
    final dal = parseItalianDate(_data.text);
    if (dal == null) {
      setState(() => _dataError = 'Inserisci una data nel formato gg/mm/aaaa.');
      return;
    }
    setState(() => _dataError = null);
    if (statoRequiresConfirmation(selected)) {
      final ok = await _confirm(selected);
      if (!ok || !mounted) {
        return;
      }
    }
    final repo = ref.read(dogRepositoryProvider);
    if (repo == null) {
      AppToast.show(context, 'Archivio cani non disponibile.');
      return;
    }
    setState(() => _busy = true);
    try {
      final now = ref.read(dogListNowProvider);
      final updated = applyDogStato(
        dog: dog,
        stato: selected,
        dal: dal,
        note: _note.text,
        autoreId: _autoreId ?? '',
        now: now,
      );
      await repo.save(updated);
      if (!mounted) {
        return;
      }
      AppToast.show(context, 'Stato aggiornato.');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.dog(dog.id));
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        AppToast.show(context, error.message?.toString() ?? 'Errore.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm(DogStato stato) async {
    final result = await AppSheet.present<bool>(
      context: context,
      builder: (context) {
        return AppSheet(
          title: 'Conferma cambio stato',
          children: [
            Text(
              'Il passaggio a ${dogStatoLabel(stato)} è definitivo. Confermi?',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.body,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
            const SizedBox(height: AppDim.gapL),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: ChangeStatusPage.cancelKey,
                    label: 'Annulla',
                    variant: AppButtonVariant.grey,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppDim.gapM),
                Expanded(
                  child: AppButton(
                    key: ChangeStatusPage.confirmKey,
                    label: 'Conferma',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final asyncDog = ref.watch(dogByIdProvider(widget.dogId));
    final volunteers = ref
        .watch(volunteersStreamProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Volunteer>[]);
    final now = ref.watch(dogListNowProvider);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: AppHeader(
            title: asyncDog.maybeWhen(
              data: (dog) => dog == null
                  ? 'Cambio stato'
                  : 'Stato di ${dogDisplayName(dog.nome)}',
              orElse: () => 'Cambio stato',
            ),
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.animali);
              }
            },
          ),
        ),
        Expanded(
          child: asyncDog.when(
            loading: () => const Center(
              child: SizedBox(
                width: AppDim.fabSize,
                height: AppDim.fabSize,
                child: CircularProgressIndicator(strokeWidth: AppDim.gapXs),
              ),
            ),
            error: (_, _) => const Center(
              child: EmptyState(
                icon: IconBadge(AppIcons.errore),
                message: 'Impossibile caricare lo stato.',
              ),
            ),
            data: (dog) {
              if (dog == null) {
                return const Center(
                  child: EmptyState(
                    icon: IconBadge(AppIcons.carattere),
                    message: 'Cane non trovato.',
                  ),
                );
              }
              _syncAutore(volunteers);
              return _ChangeStatusBody(
                dog: dog,
                now: now,
                selected: _selected ?? dog.stato,
                dataController: _data,
                noteController: _note,
                autoreController: _autore,
                dataError: _dataError,
                busy: _busy,
                onSelect: (stato) => _onSelect(dog, stato),
                onPickAutore: () => _pickAutore(volunteers),
                onSave: _busy ? null : () => _save(dog),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onSelect(Dog dog, DogStato stato) {
    if (stato == dog.stato || statoTransitionAllowed(dog.stato, stato)) {
      setState(() => _selected = stato);
      return;
    }
    AppToast.show(context, 'Transizione non ammessa.');
  }

  void _syncAutore(List<Volunteer> volunteers) {
    final label = _autoreLabel(volunteers);
    if (_autore.text == label) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autore.text == label) {
        return;
      }
      _autore.text = label;
    });
  }

  String _autoreLabel(List<Volunteer> volunteers) {
    final id = _autoreId ?? '';
    final nome = volunteerNomeDi(volunteers, id);
    if (nome.isNotEmpty) {
      return nome;
    }
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    if (email.isNotEmpty) {
      return email;
    }
    return 'Volontario';
  }
}

class _ChangeStatusBody extends StatelessWidget {
  const _ChangeStatusBody({
    required this.dog,
    required this.now,
    required this.selected,
    required this.dataController,
    required this.noteController,
    required this.autoreController,
    required this.dataError,
    required this.busy,
    required this.onSelect,
    required this.onPickAutore,
    required this.onSave,
  });

  final Dog dog;
  final DateTime now;
  final DogStato selected;
  final TextEditingController dataController;
  final TextEditingController noteController;
  final TextEditingController autoreController;
  final String? dataError;
  final bool busy;
  final ValueChanged<DogStato> onSelect;
  final VoidCallback onPickAutore;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppDim.pagePad,
      children: [
        AppCard(
          color: AppColor.greenTint,
          borderColor: AppColor.greenSoft,
          padding: const EdgeInsets.all(AppDim.gapL),
          child: Row(
            children: [
              IconBadge(
                AppIcons.perStato(dog.stato.wire),
                size: IconBadge.inMenu,
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dogStatoLabel(dog.stato),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.h2,
                        fontWeight: FontWeight.w800,
                        color: AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                    Text(
                      statoDalDettaglio(dog, now),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.label,
                        color: AppColor.muted,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapL),
        const SectionTitle(
          title: 'Cambia stato',
          icon: IconBadge(AppIcons.cambiaStato, size: IconBadge.inTitle),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            children: [
              for (final stato in DogStato.values)
                _StatoChoiceRow(
                  key: ChangeStatusPage.optionKey(stato),
                  stato: stato,
                  selected: selected == stato,
                  enabled:
                      stato == dog.stato ||
                      statoTransitionAllowed(dog.stato, stato),
                  onTap: () => onSelect(stato),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapL),
        const SectionTitle(
          title: 'Dettagli del cambio',
          icon: IconBadge(AppIcons.note, size: IconBadge.inTitle),
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: ChangeStatusPage.dataKey,
          label: 'Data effettiva',
          hint: 'gg/mm/aaaa',
          controller: dataController,
          errorText: dataError,
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: ChangeStatusPage.noteKey,
          label: 'Motivazione / note',
          hint: 'Es. trasferita in stallo da Marta R. per socializzazione…',
          controller: noteController,
          maxLines: 3,
          fieldHeight: AppDim.statoNoteH,
        ),
        const SizedBox(height: AppDim.gapM),
        AppTextField(
          key: ChangeStatusPage.autoreKey,
          label: 'Volontario che registra',
          controller: autoreController,
          readOnly: true,
          onTap: onPickAutore,
        ),
        const SizedBox(height: AppDim.gapS),
        AppButton(
          key: ChangeStatusPage.saveKey,
          label: busy ? 'Salvataggio…' : 'Salva nuovo stato',
          onPressed: onSave,
        ),
      ],
    );
  }
}

class _StatoChoiceRow extends StatelessWidget {
  const _StatoChoiceRow({
    super.key,
    required this.stato,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DogStato stato;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled ? AppColor.ink : AppColor.faint;
    final subtitleColor = enabled ? AppColor.muted : AppColor.faint;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppDim.minTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDim.gapS),
          child: Row(
            children: [
              IconBadge(
                AppIcons.perStato(stato.wire),
                size: IconBadge.inMenu,
              ),
              const SizedBox(width: AppDim.gapS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dogStatoChoiceTitle(stato),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        height: AppDim.lineH,
                      ),
                    ),
                    Text(
                      dogStatoChoiceSubtitle(stato),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: subtitleColor,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDim.gapS),
              _RadioMark(selected: selected, enabled: enabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected, required this.enabled});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColor.faint
        : (selected ? AppColor.green : AppColor.line);
    return SizedBox(
      width: AppDim.iconNav,
      height: AppDim.iconNav,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: AppDim.dashW),
        ),
        child: selected
            ? const Padding(
                padding: EdgeInsets.all(AppDim.gapXs),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.green,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
