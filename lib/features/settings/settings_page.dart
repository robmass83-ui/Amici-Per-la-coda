import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_version.dart';
import '../../core/firestore_codec.dart';
import '../../core/format_it.dart';
import '../../data/backup_json.dart';
import '../../data/data_providers.dart';
import '../../data/models/adopter.dart';
import '../../data/models/adoption.dart';
import '../../data/models/app_document.dart';
import '../../data/models/appointment.dart';
import '../../data/models/association_settings.dart';
import '../../data/models/document_template.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/health_record.dart';
import '../../data/models/shelter_box.dart';
import '../../data/models/sponsorship.dart';
import '../../data/models/volunteer.dart';
import '../../data/seed/seed_cleanup.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_providers.dart';
import '../dogs/dogs_providers.dart';
import '../dogs/edit_permissions.dart';
import '../dogs/record_actions.dart';
import '../stats/stats_csv.dart';
import '../stats/stats_providers.dart';
import '../volunteers/volunteer_labels.dart';
import 'edit_association_sheet.dart';
import 'users_card.dart';

// ── CONTRATTO DI LAYOUT · Impostazioni (Step 18, schermata 26) ────────────
// AppScaffold  titolo Impostazioni  back
// ListView  padding=12
// ├ FormCard Associazione  icona 20
// │    KeyValueRow ×4  10.5 / 11.5  maxLines=2
// │    se presidente: AppButton grey  Modifica dati
// ├ SizedBox 12
// ├ SectionTitle Notifiche
// ├ SizedBox 6
// ├ AppCard
// │    riga h=40  titolo 12sp  ·  AppSwitch 38×22  (presidente scrive)
// ├ SizedBox 12
// ├ SectionTitle Aspetto e dati
// ├ SizedBox 6
// ├ AppCard
// │    Tema  trailing Chiaro
// │    Lingua trailing Italiano
// │    Backup  (solo presidente)  subtitle Ultimo export
// │    Esporta anagrafe CSV
// │    Modalità offline  subtitle
// ├ SizedBox 12
// ├ SectionTitle Permessi volontari
// ├ SizedBox 6
// ├ AppCard  KeyValueRow ×3
// ├ SizedBox 12
// ├ FormCard Utenti  (solo presidente)
// ├ AppCard  Rimuovi dati di prova  (solo presidente, se seed_*)
// └ footer  10sp faint  padV=18  Amici per la Coda · v
// ───────────────────────────────────────────────────────────────────────────

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const listKey = Key('settings-list');
  static const associazioneKey = Key('settings-associazione');
  static const modificaAssociazioneKey = Key('settings-modifica-associazione');
  static const notificheKey = Key('settings-notifiche');
  static const scadenzeSwitchKey = Key('settings-notif-scadenze');
  static const richiesteSwitchKey = Key('settings-notif-richieste');
  static const preaffidiSwitchKey = Key('settings-notif-preaffidi');
  static const riepilogoSwitchKey = Key('settings-notif-riepilogo');
  static const aspettoKey = Key('settings-aspetto');
  static const temaKey = Key('settings-tema');
  static const linguaKey = Key('settings-lingua');
  static const backupKey = Key('settings-backup');
  static const csvKey = Key('settings-export-csv');
  static const offlineKey = Key('settings-offline');
  static const permessiKey = Key('settings-permessi');
  static const rimuoviDatiProvaKey = Key('settings-rimuovi-prova');
  static const versioneKey = Key('settings-versione');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteer = ref.watch(currentVolunteerProvider);
    final canManage = canManageSettings(volunteer);
    final association = ref.watch(associationSettingsProvider).maybeWhen(
          data: (item) => item,
          orElse: () => null,
        );
    final seedCount = countSeedDocuments(
      dogIds: ref.watch(dogsStreamProvider).maybeWhen(
            data: (items) => items.map((d) => d.id),
            orElse: () => const <String>[],
          ),
      adoptionIds: ref.watch(adoptionsStreamProvider).maybeWhen(
            data: (items) => items.map((a) => a.id),
            orElse: () => const <String>[],
          ),
      volunteerIds: ref.watch(volunteersStreamProvider).maybeWhen(
            data: (items) => items.map((v) => v.id),
            orElse: () => const <String>[],
          ),
      adopterIds: ref.watch(adoptersStreamProvider).maybeWhen(
            data: (items) => items.map((a) => a.id),
            orElse: () => const <String>[],
          ),
    );
    final showRimuoviProva = canManage && seedCount > 0;
    final version = ref.watch(appVersionProvider).maybeWhen(
          data: (value) => value,
          orElse: () => '…',
        );

    return AppScaffold(
      title: 'Impostazioni',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      body: ListView(
        key: listKey,
        padding: AppDim.pagePad,
        children: [
          _AssociazioneCard(
            settings: association,
            canManage: canManage,
            onEdit: () => unawaited(
              EditAssociationSheet.open(context, current: association),
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Notifiche',
            icon: IconBadge(AppIcons.notifiche, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapS),
          _NotificheCard(
            settings: association,
            canManage: canManage,
            onToggle: (update) => unawaited(
              _saveNotifiche(context, ref, association, update),
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Aspetto e dati',
            icon: IconBadge(AppIcons.tema, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapS),
          AppCard(
            key: aspettoKey,
            child: Column(
              children: [
                OptionRow(
                  key: temaKey,
                  icon: const IconBadge(AppIcons.tema, size: IconBadge.inMenu),
                  title: 'Tema',
                  minHeight: AppDim.menuRowH,
                  titleSize: AppText.formCard,
                  trailing: const _MutedValue('Chiaro'),
                  onTap: () => AppToast.show(
                    context,
                    'Disponibile solo il tema chiaro.',
                  ),
                ),
                OptionRow(
                  key: linguaKey,
                  icon: const IconBadge(AppIcons.lingua, size: IconBadge.inMenu),
                  title: 'Lingua',
                  minHeight: AppDim.menuRowH,
                  titleSize: AppText.formCard,
                  trailing: const _MutedValue('Italiano'),
                  onTap: () => AppToast.show(
                    context,
                    'Disponibile solo l\'italiano.',
                  ),
                ),
                if (canManage)
                  OptionRow(
                    key: backupKey,
                    icon: const IconBadge(
                      AppIcons.backup,
                      size: IconBadge.inMenu,
                    ),
                    title: 'Backup dati',
                    subtitle: association?.ultimoExportAt == null
                        ? 'Mai eseguito'
                        : 'Ultimo export: ${formatItalianDate(association!.ultimoExportAt!)}',
                    minHeight: AppDim.menuRowH,
                    titleSize: AppText.formCard,
                    onTap: () => unawaited(_exportBackup(context, ref)),
                  ),
                OptionRow(
                  key: csvKey,
                  icon: const IconBadge(
                    AppIcons.esporta,
                    size: IconBadge.inMenu,
                  ),
                  title: 'Esporta anagrafe (CSV)',
                  minHeight: AppDim.menuRowH,
                  titleSize: AppText.formCard,
                  onTap: () => unawaited(_exportCsv(context, ref)),
                ),
                OptionRow(
                  key: offlineKey,
                  icon: const IconBadge(
                    AppIcons.offline,
                    size: IconBadge.inMenu,
                  ),
                  title: 'Modalità offline',
                  subtitle: ref.watch(homeOfflineProvider)
                      ? 'Sei offline: i dati si sincronizzano al rientro del segnale'
                      : 'Sincronizza al rientro del segnale',
                  minHeight: AppDim.menuRowH,
                  titleSize: AppText.formCard,
                  onTap: () => AppToast.show(
                    context,
                    ref.read(homeOfflineProvider)
                        ? 'Sei offline. I dati si sincronizzano al rientro del segnale.'
                        : 'Sei in linea. Senza rete i dati restano sul telefono.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          const SectionTitle(
            title: 'Permessi volontari',
            icon: IconBadge(AppIcons.volontari, size: IconBadge.inTitle),
          ),
          const SizedBox(height: AppDim.gapS),
          AppCard(
            key: permessiKey,
            child: Column(
              children: [
                for (final ruolo in VolunteerRuolo.values) ...[
                  if (ruolo != VolunteerRuolo.values.first)
                    const SizedBox(height: AppDim.gapS),
                  KeyValueRow(
                    label: volunteerRuoloLabel(ruolo),
                    value: volunteerRuoloPermessi(ruolo),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: AppDim.gapL),
            const UsersCard(),
          ],
          if (showRimuoviProva) ...[
            const SizedBox(height: AppDim.gapM),
            AppCard(
              child: OptionRow(
                key: rimuoviDatiProvaKey,
                icon: const IconBadge(AppIcons.elimina, size: IconBadge.inMenu),
                title: 'Rimuovi dati di prova',
                subtitle: seedCount == 1
                    ? '1 documento con prefisso seed_'
                    : '$seedCount documenti con prefisso seed_',
                titleColor: AppColor.red,
                onTap: () => unawaited(
                  _removeSeedData(context, ref, seedCount),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDim.footerPadV),
            child: Text(
              'Amici per la Coda · v$version',
              key: versioneKey,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.faint,
                height: AppDim.lineH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedValue extends StatelessWidget {
  const _MutedValue(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.value,
        color: AppColor.muted,
        height: AppDim.lineH,
      ),
    );
  }
}

class _AssociazioneCard extends StatelessWidget {
  const _AssociazioneCard({
    required this.settings,
    required this.canManage,
    required this.onEdit,
  });

  final AssociationSettings? settings;
  final bool canManage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final item = settings;
    return FormCard(
      key: SettingsPage.associazioneKey,
      title: 'Associazione',
      icon: AppIcons.associazione,
      children: [
        KeyValueRow(
          label: 'Denominazione',
          value: item == null || item.denominazione.isEmpty
              ? '—'
              : item.denominazione,
          maxLines: 2,
        ),
        KeyValueRow(
          label: 'Codice fiscale',
          value: item == null || item.codiceFiscale.isEmpty
              ? '—'
              : item.codiceFiscale,
          maxLines: 2,
        ),
        KeyValueRow(
          label: 'Sede',
          value: item == null || item.sede.isEmpty ? '—' : item.sede,
          maxLines: 2,
        ),
        KeyValueRow(
          label: 'Capienza autorizzata',
          value: item == null ? '—' : '${item.capienzaAutorizzata} posti',
          maxLines: 1,
        ),
        if (canManage)
          AppButton(
            key: SettingsPage.modificaAssociazioneKey,
            label: 'Modifica dati',
            variant: AppButtonVariant.grey,
            onPressed: onEdit,
          ),
      ],
    );
  }
}

class _NotificheCard extends StatelessWidget {
  const _NotificheCard({
    required this.settings,
    required this.canManage,
    required this.onToggle,
  });

  final AssociationSettings? settings;
  final bool canManage;
  final void Function(AssociationSettings Function(AssociationSettings))
      onToggle;

  @override
  Widget build(BuildContext context) {
    final item = settings;
    return AppCard(
      key: SettingsPage.notificheKey,
      child: Column(
        children: [
          _NotifyRow(
            key: SettingsPage.scadenzeSwitchKey,
            title: 'Scadenze sanitarie',
            value: item?.notificheScadenzeSanitarie ?? true,
            enabled: canManage,
            onChanged: (on) => onToggle(
              (current) => current.copyWith(notificheScadenzeSanitarie: on),
            ),
          ),
          _NotifyRow(
            key: SettingsPage.richiesteSwitchKey,
            title: 'Nuove richieste di adozione',
            value: item?.notificheNuoveRichieste ?? true,
            enabled: canManage,
            onChanged: (on) => onToggle(
              (current) => current.copyWith(notificheNuoveRichieste: on),
            ),
          ),
          _NotifyRow(
            key: SettingsPage.preaffidiSwitchKey,
            title: 'Scadenza preaffidi',
            value: item?.notificheScadenzaPreaffidi ?? true,
            enabled: canManage,
            onChanged: (on) => onToggle(
              (current) => current.copyWith(notificheScadenzaPreaffidi: on),
            ),
          ),
          _NotifyRow(
            key: SettingsPage.riepilogoSwitchKey,
            title: 'Riepilogo settimanale',
            value: item?.notificheRiepilogoSettimanale ?? false,
            enabled: canManage,
            onChanged: (on) => onToggle(
              (current) => current.copyWith(notificheRiepilogoSettimanale: on),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyRow extends StatelessWidget {
  const _NotifyRow({
    super.key,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => onChanged(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppDim.minTouch,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.body,
                  fontWeight: FontWeight.w500,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
            ),
            AppSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _saveNotifiche(
  BuildContext context,
  WidgetRef ref,
  AssociationSettings? current,
  AssociationSettings Function(AssociationSettings) update,
) async {
  final repo = ref.read(settingsRepositoryProvider);
  if (repo == null) {
    return;
  }
  final now = ref.read(dogListNowProvider);
  final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
  final base = current ??
      AssociationSettings(
        denominazione: 'Amici per la Coda ODV',
        codiceFiscale: '',
        sede: '',
        capienzaAutorizzata: 54,
        logoB64: null,
        audit: Audit.seed(now, by: uid),
      );
  try {
    await repo.saveAssociation(
      update(base).copyWith(audit: base.audit.touched(uid, now)),
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Impostazione non salvata.');
    }
  }
}

Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
  final dogs = ref.read(dogsStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Dog>[],
      );
  final volunteers = ref.read(volunteersStreamProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Volunteer>[],
      );
  final csv = anagrafeCsvDi(dogs, volunteers: volunteers);
  try {
    await ref.read(fileShareProvider).shareFile(
          bytes: Uint8List.fromList(utf8.encode(csv)),
          fileName: 'anagrafe-cani.csv',
          mime: 'text/csv',
          text: 'Anagrafe cani',
        );
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Export non riuscito.');
    }
  }
}

Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
  final now = ref.read(dogListNowProvider);
  final backup = buildBackupMap(
    exportedAt: now,
    dogs: ref.read(dogsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Dog>[],
        ),
    volunteers: ref.read(volunteersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Volunteer>[],
        ),
    boxes: ref.read(boxesStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <ShelterBox>[],
        ),
    adoptions: ref.read(adoptionsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adoption>[],
        ),
    adopters: ref.read(adoptersStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Adopter>[],
        ),
    appointments: ref.read(appointmentsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Appointment>[],
        ),
    health: ref.read(healthAllProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <HealthRecord>[],
        ),
    expenses: ref.read(expensesAllProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Expense>[],
        ),
    sponsorships: ref.read(sponsorshipsAllProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <Sponsorship>[],
        ),
    documents: ref.read(documentsStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <AppDocument>[],
        ),
    templates: ref.read(templatesStreamProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <DocumentTemplate>[],
        ),
    association: ref.read(associationSettingsProvider).maybeWhen(
          data: (item) => item,
          orElse: () => null,
        ),
  );
  try {
    await ref.read(fileShareProvider).shareFile(
          bytes: Uint8List.fromList(utf8.encode(backupJsonOf(backup))),
          fileName: backupFileName(now),
          mime: 'application/json',
          text: 'Export dati Amici per la Coda',
        );
    final repo = ref.read(settingsRepositoryProvider);
    final current = ref.read(associationSettingsProvider).maybeWhen(
          data: (item) => item,
          orElse: () => null,
        );
    final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (repo != null && current != null) {
      await repo.saveAssociation(
        current.copyWith(
          ultimoExportAt: now,
          audit: current.audit.touched(uid, now),
        ),
      );
    }
    if (context.mounted) {
      AppToast.show(context, 'Export pronto.');
    }
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, 'Export non riuscito.');
    }
  }
}

Future<void> _removeSeedData(
  BuildContext context,
  WidgetRef ref,
  int count,
) async {
  final ok = await confirmAction(
    context: context,
    title: 'Rimuovi dati di prova',
    message: count == 1
        ? 'Eliminare 1 documento di prova (prefisso seed_)?'
        : 'Eliminare $count documenti di prova (prefisso seed_)?',
    confirmLabel: 'Rimuovi',
  );
  if (!ok || !context.mounted) {
    return;
  }
  final cleanup = ref.read(seedCleanupProvider);
  if (cleanup == null) {
    AppToast.show(context, 'Archivio non disponibile.');
    return;
  }
  final report = await cleanup.deleteSeed();
  if (!context.mounted) {
    return;
  }
  final removed = report.dogs + report.adoptions + report.volunteers;
  AppToast.show(
    context,
    removed == 0
        ? 'Nessun dato di prova da rimuovere.'
        : 'Rimossi $removed documenti di prova.',
  );
}
