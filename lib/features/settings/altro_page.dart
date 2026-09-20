import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_update/app_update_controller.dart';
import '../../core/app_version.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../dashboard/home_providers.dart';
import '../dogs/edit_permissions.dart';
import '../volunteers/volunteer_labels.dart';
import 'share_installed_apk.dart';

// ── CONTRATTO DI LAYOUT · Menu Altro (Step 17-bis, schermata 25) ──────────
// ListView padding=12
// ├ AppCard pad=12  tap → Impostazioni
// │  Row  avatar 44  gap=11  Expanded
// │     nome 15sp w800 maxLines=1
// │     ruolo · associazione  10.8sp muted maxLines=1
// │  chevron 18
// ├ SizedBox 14→ gapL+gapS  (12+6=18 troppi: gapL 12 + gapS 6)
// ├ _GroupLabel GESTIONE  10sp maiuscoletto muted tracking 0.9
// ├ SizedBox 6
// ├ AppCard pad 0/H? cardPad 10 → inner OptionRow minH=46 title 12.5
// │    Anagrafe · Richieste · Box · Calendario
// │    separatore 1px line2 fra le righe
// ├ SizedBox 12
// ├ ARCHIVIO  Documenti (canWrite) · Famiglie · Fornitori · Archiviati
// ├ SizedBox 12
// └ APP  Statistiche · Notifiche · Aggiornamenti · Condividi app
//    · Impostazioni · Esci rosso
//    Catalogo UI solo kDebugMode
// ───────────────────────────────────────────────────────────────────────────

class AltroPage extends ConsumerWidget {
  const AltroPage({super.key});

  static const listKey = Key('altro-list');
  static const profiloKey = Key('altro-profilo');
  static const anagrafeKey = Key('altro-anagrafe');
  static const richiesteKey = Key('altro-richieste');
  static const boxKey = Key('altro-box');
  static const calendarioKey = Key('altro-calendario');
  static const documentiKey = Key('altro-documenti');
  static const famiglieKey = Key('altro-famiglie');
  static const fornitoriKey = Key('altro-fornitori');
  static const archiviatiKey = Key('altro-archiviati');
  static const statsKey = Key('altro-statistiche');
  static const notificheKey = Key('altro-notifiche');
  static const aggiornamentiKey = Key('altro-aggiornamenti');
  static const condividiAppKey = Key('altro-condividi-app');
  static const impostazioniKey = Key('altro-impostazioni');
  static const esciKey = Key('altro-esci');
  static const catalogoKey = Key('altro-catalogo');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteer = ref.watch(currentVolunteerProvider);
    final canWrite = canWriteRecords(volunteer);
    final nome = volunteer == null
        ? ref.watch(homeVolunteerNameProvider)
        : volunteerDisplayName(volunteer);
    final ruolo = volunteer == null
        ? ''
        : volunteerRuoloLabel(volunteer.ruolo);
    final associazione = ref.watch(associationSettingsProvider).maybeWhen(
          data: (item) => item?.denominazione ?? '',
          orElse: () => '',
        );
    final initial = nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();
    final subtitle = [
      if (ruolo.isNotEmpty) ruolo,
      if (associazione.isNotEmpty) associazione,
    ].join(' · ');

    return ListView(
      key: listKey,
      padding: AppDim.pagePad,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppDim.gapL),
          onTap: () => context.push(AppRoutes.impostazioni),
          child: Row(
            children: [
              SizedBox(
                width: AppDim.listAvatar,
                height: AppDim.listAvatar,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColor.greenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.title,
                        fontWeight: FontWeight.w800,
                        color: AppColor.green,
                        height: AppDim.lineH,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDim.gapL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty ? 'Volontario' : nome,
                      key: profiloKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.title,
                        fontWeight: FontWeight.w800,
                        color: AppColor.ink,
                        height: AppDim.lineH,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: AppText.todo,
                          color: AppColor.muted,
                          height: AppDim.lineH,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: AppDim.iconNav,
                color: AppColor.faint,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapL),
        _MenuGroup(
          label: 'Gestione',
          rows: [
            _menuRow(
              key: anagrafeKey,
              icon: AppIcons.carattere,
              title: 'Anagrafe cani',
              onTap: () => context.go(AppRoutes.animali),
            ),
            _menuRow(
              key: richiesteKey,
              icon: AppIcons.richieste,
              title: 'Richieste e adozioni',
              onTap: () => context.push(AppRoutes.richieste),
            ),
            _menuRow(
              key: boxKey,
              icon: AppIcons.box,
              title: 'Box e settori',
              onTap: () => context.push(AppRoutes.box),
            ),
            _menuRow(
              key: calendarioKey,
              icon: AppIcons.data,
              title: 'Calendario',
              onTap: () => context.go(AppRoutes.calendario),
            ),
          ],
        ),
        const SizedBox(height: AppDim.gapL),
        _MenuGroup(
          label: 'Archivio',
          rows: [
            _menuRow(
              key: documentiKey,
              icon: AppIcons.documenti,
              title: 'Documenti e modulistica',
              onTap: () => context.push(AppRoutes.documenti),
            ),
            _menuRow(
              key: famiglieKey,
              icon: AppIcons.famiglie,
              title: 'Famiglie adottanti',
              onTap: () => context.push(AppRoutes.adottanti),
            ),
            _menuRow(
              key: fornitoriKey,
              icon: AppIcons.fornitori,
              title: 'Veterinari e fornitori',
              onTap: () => context.push(AppRoutes.fornitori),
            ),
            _menuRow(
              key: archiviatiKey,
              icon: AppIcons.archivia,
              title: 'Cani archiviati',
              onTap: () => context.push(AppRoutes.archiviati),
            ),
          ],
        ),
        const SizedBox(height: AppDim.gapL),
        _MenuGroup(
          label: 'App',
          rows: [
            _menuRow(
              key: statsKey,
              icon: AppIcons.statistiche,
              title: 'Statistiche e report',
              onTap: () => context.push(AppRoutes.statistiche),
            ),
            _menuRow(
              key: notificheKey,
              icon: AppIcons.notifiche,
              title: 'Notifiche',
              onTap: () => context.push(AppRoutes.notifiche),
            ),
            _menuRow(
              key: aggiornamentiKey,
              icon: AppIcons.aggiornamenti,
              title: 'Aggiornamenti',
              subtitle: ref.watch(appVersionProvider).maybeWhen(
                    data: (version) => 'Versione $version',
                    orElse: () => 'Controlla su GitHub',
                  ),
              onTap: () => unawaited(
                ref
                    .read(appUpdateControllerProvider.notifier)
                    .check(userInitiated: true),
              ),
            ),
            _menuRow(
              key: condividiAppKey,
              icon: AppIcons.condividi,
              title: 'Condividi app',
              subtitle: 'Invia l\'APK via WhatsApp o email',
              onTap: () => unawaited(shareInstalledApk(context, ref)),
            ),
            _menuRow(
              key: impostazioniKey,
              icon: AppIcons.impostazioni,
              title: 'Impostazioni',
              onTap: () => context.push(AppRoutes.impostazioni),
            ),
            if (kDebugMode && canWrite)
              _menuRow(
                key: catalogoKey,
                icon: AppIcons.catalogo,
                title: 'Catalogo UI',
                onTap: () => context.push(AppRoutes.debugUi),
              ),
            _menuRow(
              key: esciKey,
              icon: AppIcons.esci,
              title: 'Esci',
              titleColor: AppColor.red,
              onTap: () => unawaited(() async {
                await ref.read(authRepositoryProvider).signOut();
                onSignedOut(ref);
              }()),
            ),
          ],
        ),
      ],
    );
  }
}

OptionRow _menuRow({
  required Key key,
  required AppIconSpec icon,
  required String title,
  required VoidCallback onTap,
  String subtitle = '',
  Color? titleColor,
}) {
  return OptionRow(
    key: key,
    icon: IconBadge(icon, size: IconBadge.inMenu),
    title: title,
    subtitle: subtitle,
    titleColor: titleColor,
    titleSize: AppText.formCard,
    minHeight: AppDim.menuRowH,
    onTap: onTap,
  );
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.label, required this.rows});

  final String label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: AppDim.groupTracking,
            color: AppColor.muted,
            height: AppDim.lineH,
          ),
        ),
        const SizedBox(height: AppDim.gapS),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const ColoredBox(
                    color: AppColor.line2,
                    child: SizedBox(height: AppDim.gapHair, width: double.infinity),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
