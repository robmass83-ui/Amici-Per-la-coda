import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../core/new_id.dart';
import '../../data/data_providers.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/enums.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/dog_labels.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/new_dog/new_dog_validation.dart';
import 'adoption_flow.dart';
import 'family_link.dart';

// ── CONTRATTO DI LAYOUT · Form famiglia ───────────────────────────────────
// AppScaffold compactHeader  titolo + pill Salva
// ListView padding=12
// ├ FormRow2  nome* | cognome*
// ├ SizedBox 9
// ├ FormRow2  telefono | email
// ├ SizedBox 9
// ├ FormRow2  città | indirizzo
// ├ SizedBox 9
// ├ FormRow2  documento tipo (tap sheet) | numero
// ├ SizedBox 9
// ├ AppFormField data nascita  digitabile + suffix
// ├ SizedBox 9
// └ AppFormField note  maxLines=3
// ───────────────────────────────────────────────────────────────────────────

class AdopterFormPage extends ConsumerStatefulWidget {
  const AdopterFormPage({super.key, this.adopterId, this.dogId});

  final String? adopterId;
  final String? dogId;

  static const nomeKey = Key('adopter-nome');
  static const cognomeKey = Key('adopter-cognome');

  @override
  ConsumerState<AdopterFormPage> createState() => _AdopterFormPageState();
}

class _AdopterFormPageState extends ConsumerState<AdopterFormPage> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _citta = TextEditingController();
  final _indirizzo = TextEditingController();
  final _docNumero = TextEditingController();
  final _dataNascita = TextEditingController();
  final _note = TextEditingController();
  String _docTipo = '';
  String? _nomeError;
  String? _cognomeError;
  String? _nascitaError;
  String? _loadedId;
  Adopter? _existing;

  static const _docTipi = ['CI', 'Patente', 'Passaporto'];

  @override
  void dispose() {
    _nome.dispose();
    _cognome.dispose();
    _telefono.dispose();
    _email.dispose();
    _citta.dispose();
    _indirizzo.dispose();
    _docNumero.dispose();
    _dataNascita.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fill(Adopter adopter) {
    _loadedId = adopter.id;
    _existing = adopter;
    _nome.text = adopter.nome;
    _cognome.text = adopter.cognome;
    _telefono.text = adopter.telefono;
    _email.text = adopter.email;
    _citta.text = adopter.citta;
    _indirizzo.text = adopter.indirizzo;
    _docTipo = adopter.docTipo;
    _docNumero.text = adopter.docNumero;
    _dataNascita.text = adopter.dataNascita == null
        ? ''
        : formatItalianDate(adopter.dataNascita!);
    _note.text = adopter.note;
  }

  Future<void> _pickDocTipo() async {
    await AppSheet.show<void>(
      context: context,
      title: 'Documento',
      children: [
        for (final tipo in _docTipi)
          OptionRow(
            icon: const IconBadge(AppIcons.anagrafe, size: IconBadge.inMenu),
            title: tipo,
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _docTipo = tipo);
            },
          ),
      ],
    );
  }

  Future<void> _save() async {
    final nome = _nome.text.trim();
    final cognome = _cognome.text.trim();
    final nascitaErr = validateOptionalItalianDate(_dataNascita.text);
    String? nomeError;
    String? cognomeError;
    if (nome.isEmpty) {
      nomeError = 'Inserisci il nome.';
    }
    if (cognome.isEmpty) {
      cognomeError = 'Inserisci il cognome.';
    }
    if (nomeError != null || cognomeError != null || nascitaErr != null) {
      setState(() {
        _nomeError = nomeError;
        _cognomeError = cognomeError;
        _nascitaError = nascitaErr;
      });
      return;
    }
    final repo = ref.read(adopterRepositoryProvider);
    final volunteer = ref.read(currentVolunteerProvider);
    if (repo == null || volunteer == null) {
      return;
    }
    final now = DateTime.now();
    final existing = _existing;
    if (existing == null) {
      final adopters = ref.read(adoptersStreamProvider).maybeWhen(
            data: (items) => items,
            orElse: () => const <Adopter>[],
          );
      final match = findMatchingAdopter(
        adopters,
        telefono: _telefono.text,
        email: _email.text,
      );
      if (match != null) {
        if (!mounted) {
          return;
        }
        final dogId = widget.dogId;
        if (dogId != null && dogId.isNotEmpty) {
          await _linkToDog(match, dogId);
          return;
        }
        AppToast.show(
          context,
          'Esiste già: ${match.nomeCompleto}. Apro quella scheda.',
        );
        context.go(AppRoutes.adottante(match.id));
        return;
      }
    }
    final audit = existing == null
        ? Audit(
            createdAt: now,
            createdBy: volunteer.id,
            updatedAt: now,
            updatedBy: volunteer.id,
          )
        : Audit(
            createdAt: existing.audit.createdAt,
            createdBy: existing.audit.createdBy,
            updatedAt: now,
            updatedBy: volunteer.id,
          );
    final adopter = Adopter(
      id: existing?.id ?? newEntityId('adp', now),
      nome: nome,
      cognome: cognome,
      telefono: _telefono.text.trim(),
      email: _email.text.trim(),
      citta: _citta.text.trim(),
      indirizzo: _indirizzo.text.trim(),
      docTipo: _docTipo,
      docNumero: _docNumero.text.trim(),
      dataNascita: parseItalianDate(_dataNascita.text),
      note: _note.text.trim(),
      adozioniIds: existing?.adozioniIds ?? const [],
      affidabilita: existing?.affidabilita ?? Affidabilita.daVerificare,
      audit: audit,
    );
    await repo.save(adopter);
    if (!mounted) {
      return;
    }
    final dogId = widget.dogId;
    if (dogId != null && dogId.isNotEmpty) {
      await _linkToDog(adopter, dogId);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.adottanti);
    }
  }

  Future<void> _linkToDog(Adopter adopter, String dogId) async {
    final adoptions = ref.read(adoptionRepositoryProvider);
    final adopterRepo = ref.read(adopterRepositoryProvider);
    final dogRepo = ref.read(dogRepositoryProvider);
    final volunteer = ref.read(currentVolunteerProvider);
    if (adoptions == null ||
        adopterRepo == null ||
        dogRepo == null ||
        volunteer == null) {
      return;
    }
    final existingLinks = ref.read(adoptionsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adoption>[],
        );
    final now = DateTime.now();
    await replaceDogFamily(
      adoptions: adoptions,
      adopters: adopterRepo,
      existing: existingLinks,
      adopter: adopter,
      dogId: dogId,
      uid: volunteer.id,
      now: now,
    );
    if (!mounted) {
      return;
    }
    final dog = ref.read(dogByIdProvider(dogId)).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (dog != null) {
      await AppSheet.present<void>(
        context: context,
        builder: (sheetContext) => AppSheet(
          title: 'Segnare ${dogDisplayName(dog.nome)} come adottato?',
          children: [
            AppButton(
              label: 'Sì',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                final result = markDogAdottatoIfNeeded(
                  dog: dog,
                  now: DateTime.now(),
                  autoreId: volunteer.id,
                );
                unawaited(dogRepo.save(result.dog));
              },
            ),
            const SizedBox(height: AppDim.gapM),
            AppButton(
              label: 'No',
              variant: AppButtonVariant.grey,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    }
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.dog(dogId));
  }

  @override
  Widget build(BuildContext context) {
    final adopterId = widget.adopterId;
    if (adopterId != null && _loadedId != adopterId) {
      final found = ref.watch(adoptersStreamProvider).maybeWhen(
            data: (items) {
              for (final item in items) {
                if (item.id == adopterId) {
                  return item;
                }
              }
              return null;
            },
            orElse: () => null,
          );
      if (found != null) {
        _fill(found);
      }
    }

    final editing = widget.adopterId != null;
    return AppScaffold(
      compactHeader: true,
      title: editing ? 'Modifica famiglia' : 'Nuova famiglia',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.adottanti);
        }
      },
      headerActions: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDim.minTouch,
            minHeight: AppDim.minTouch,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_save()),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColor.green,
                  borderRadius: BorderRadius.circular(AppDim.radChip),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDim.formSavePadH,
                    vertical: AppDim.formSavePadV,
                  ),
                  child: Text(
                    'Salva',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.segmented,
                      fontWeight: FontWeight.w700,
                      color: AppColor.card,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      body: ListView(
        padding: AppDim.pagePad,
        children: [
          FormRow2(
            left: AppFormField(
              key: AdopterFormPage.nomeKey,
              label: 'Nome',
              hint: 'Nome',
              controller: _nome,
              errorText: _nomeError,
              onChanged: (_) {
                if (_nomeError != null) {
                  setState(() => _nomeError = null);
                }
              },
            ),
            right: AppFormField(
              key: AdopterFormPage.cognomeKey,
              label: 'Cognome',
              hint: 'Cognome',
              controller: _cognome,
              errorText: _cognomeError,
              onChanged: (_) {
                if (_cognomeError != null) {
                  setState(() => _cognomeError = null);
                }
              },
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          FormRow2(
            left: AppFormField(
              label: 'Telefono',
              hint: 'Telefono',
              controller: _telefono,
              keyboardType: TextInputType.phone,
            ),
            right: AppFormField(
              label: 'Email',
              hint: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          FormRow2(
            left: AppFormField(
              label: 'Città',
              hint: 'Città',
              controller: _citta,
            ),
            right: AppFormField(
              label: 'Indirizzo',
              hint: 'Indirizzo',
              controller: _indirizzo,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          FormRow2(
            left: AppFormField(
              label: 'Documento',
              hint: _docTipo.isEmpty ? 'Tipo' : _docTipo,
              onTap: () => unawaited(_pickDocTipo()),
            ),
            right: AppFormField(
              label: 'Numero',
              hint: 'Numero',
              controller: _docNumero,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Data di nascita',
            hint: 'gg/mm/aaaa',
            controller: _dataNascita,
            keyboardType: TextInputType.datetime,
            errorText: _nascitaError,
            suffix: dateFieldSuffix(
              onTap: () => pickDogFormDate(
                context,
                _dataNascita,
                () => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Note',
            hint: 'Note',
            controller: _note,
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }
}
