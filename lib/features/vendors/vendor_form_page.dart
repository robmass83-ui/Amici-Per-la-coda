import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firestore_codec.dart';
import '../../core/new_id.dart';
import '../../data/data_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/vendor.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import 'vendor_logic.dart';
import 'vendor_providers.dart';

// ── CONTRATTO DI LAYOUT · Form fornitore ──────────────────────────────────
// AppScaffold compactHeader  titolo + pill Salva 40 min
// ListView padding=12
// ├ AppFormField nome *
// ├ SizedBox 9
// ├ AppFormField tipo  tap → AppSheet 6 OptionRow
// ├ SizedBox 9
// ├ AppFormField telefono / email / indirizzo
// ├ SizedBox 9
// ├ etichetta Convenzionato + AppSegmented Sì/No  h=40  default No
// ├ SizedBox 9
// └ AppFormField note  maxLines=3
// ───────────────────────────────────────────────────────────────────────────

class VendorFormPage extends ConsumerStatefulWidget {
  const VendorFormPage({
    super.key,
    this.vendorId,
    this.prefillNome,
    this.prefillTipo,
  });

  final String? vendorId;
  final String? prefillNome;
  final String? prefillTipo;

  static const nomeKey = Key('vendor-nome');

  @override
  ConsumerState<VendorFormPage> createState() => _VendorFormPageState();
}

class _VendorFormPageState extends ConsumerState<VendorFormPage> {
  final _nome = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _indirizzo = TextEditingController();
  final _note = TextEditingController();
  VendorTipo _tipo = VendorTipo.veterinario;
  var _convenzionato = false;
  String? _nomeError;
  String? _loadedId;
  Audit? _existingAudit;

  static const _tipi = VendorTipo.values;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillNome?.trim();
    if (prefill != null && prefill.isNotEmpty) {
      _nome.text = prefill;
    }
    if (widget.prefillTipo != null) {
      _tipo = VendorTipo.parse(widget.prefillTipo);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefono.dispose();
    _email.dispose();
    _indirizzo.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fill(Vendor vendor) {
    _loadedId = vendor.id;
    _existingAudit = vendor.audit;
    _nome.text = vendor.nome;
    _telefono.text = vendor.telefono;
    _email.text = vendor.email;
    _indirizzo.text = vendor.indirizzo;
    _note.text = vendor.note;
    _tipo = vendor.tipo;
    _convenzionato = vendor.convenzionato;
  }

  Future<void> _pickTipo() async {
    await AppSheet.show<void>(
      context: context,
      title: 'Tipo',
      children: [
        for (final tipo in _tipi)
          OptionRow(
            icon: const IconBadge(AppIcons.fornitori, size: IconBadge.inMenu),
            title: vendorTipoLabel(tipo),
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _tipo = tipo);
            },
          ),
      ],
    );
  }

  Future<void> _save() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _nomeError = 'Inserisci il nome.');
      return;
    }
    final repo = ref.read(vendorRepositoryProvider);
    final volunteer = ref.read(currentVolunteerProvider);
    if (repo == null || volunteer == null) {
      return;
    }
    final now = DateTime.now();
    final existing = _existingAudit;
    final audit = existing == null
        ? Audit(createdAt: now, createdBy: volunteer.id, updatedAt: now, updatedBy: volunteer.id)
        : Audit(
            createdAt: existing.createdAt,
            createdBy: existing.createdBy,
            updatedAt: now,
            updatedBy: volunteer.id,
          );
    final vendor = Vendor(
      id: widget.vendorId ?? newEntityId('ven', now),
      nome: nome,
      tipo: _tipo,
      telefono: _telefono.text.trim(),
      email: _email.text.trim(),
      indirizzo: _indirizzo.text.trim(),
      convenzionato: _convenzionato,
      note: _note.text.trim(),
      audit: audit,
    );
    await repo.save(vendor);
    if (!mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.fornitori);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorId = widget.vendorId;
    if (vendorId != null && _loadedId != vendorId) {
      final found = ref.watch(vendorsStreamProvider).maybeWhen(
            data: (items) {
              for (final item in items) {
                if (item.id == vendorId) {
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

    final editing = widget.vendorId != null;
    return AppScaffold(
      compactHeader: true,
      title: editing ? 'Modifica fornitore' : 'Nuovo fornitore',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.fornitori);
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
          AppFormField(
            key: VendorFormPage.nomeKey,
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
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Tipo',
            hint: vendorTipoLabel(_tipo),
            onTap: () => unawaited(_pickTipo()),
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Telefono',
            hint: 'Telefono',
            controller: _telefono,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Email',
            hint: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppDim.gapM),
          AppFormField(
            label: 'Indirizzo',
            hint: 'Indirizzo',
            controller: _indirizzo,
          ),
          const SizedBox(height: AppDim.gapM),
          const Text(
            'CONVENZIONATO',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.caption,
              fontWeight: FontWeight.w600,
              color: AppColor.muted,
              height: AppDim.formLabelLineH,
            ),
          ),
          const SizedBox(height: AppDim.formLabelGap),
          AppSegmented(
            values: const ['Sì', 'No'],
            selectedIndex: _convenzionato ? 0 : 1,
            onChanged: (i) => setState(() => _convenzionato = i == 0),
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
