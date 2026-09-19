import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';
import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import '../dog_labels.dart';
import 'adoption_post_text.dart';
import 'adoption_profile.dart';

// ── CONTRATTO DI LAYOUT · Card social 1080×1350 ────────────────────────────
// SizedBox 1080×1350  Column
// ├ Stack  h=58%  (foto cover / segnaposto iniziale)
// │    ├ Image.memory fit=cover  oppure Container greenSoft + iniziale 110
// │    ├ gradient alto 15% nero + basso 72% nero
// │    ├ Positioned left=40 top=40
// │    │    pillola stato  h auto  pad 14/28  radius 20  testo 26 w800 bianco
// │    ├ Positioned right=40 top=32
// │    │    logo h=90  su riquadro bianco 85%  radius 16  pad 12
// │    └ Positioned left=40 bottom=32 right=40
// │         nome 110 w800 bianco + slogan 30 italic
// ├ Expanded  Padding 40  Column  gap=22
// │    ├ Row  4× Expanded riquadro bg radius=22  pad 16
// │    │    IconBadge 36 · valore 26 w800 maxLines=2 · etichetta 19 muted
// │    ├ Wrap chip  gap=10  max 6  (carattere + Ok cani/gatti/bambini)
// │    ├ Expanded  testo 24  height 1.45  maxLines=5
// │    └ CTA  h~72  green  radius=26  pad 20/28
// │         «Vuoi conoscerl*? Scrivici» 28 w800 · telefono · città 22
// ───────────────────────────────────────────────────────────────────────────

class AdoptionCardWidget extends StatelessWidget {
  const AdoptionCardWidget({super.key, required this.profile});

  static const boundaryKey = Key('adoption-card-boundary');
  static const logoKey = Key('adoption-card-logo');
  static const okCaniKey = Key('adoption-card-ok-cani');

  final AdoptionProfile profile;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColor.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: AppDim.exportCardH * AppDim.exportPhotoFrac,
            child: _Hero(profile: profile),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDim.exportCardPad,
                AppDim.exportCardGap,
                AppDim.exportCardPad,
                AppDim.exportCardPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Facts(profile: profile),
                  const SizedBox(height: AppDim.exportCardGap),
                  _Chips(profile: profile),
                  const SizedBox(height: AppDim.exportCardGap),
                  Expanded(
                    child: Text(
                      truncateStory(profile.descrizione),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppDim.exportBody,
                        height: 1.45,
                        color: AppColor.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDim.exportCardGap),
                  _Cta(profile: profile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.profile});
  final AdoptionProfile profile;

  @override
  Widget build(BuildContext context) {
    final photo = profile.fotoCopertina;
    final logo = profile.associazione.logo;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photo != null && photo.isNotEmpty)
          Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true)
        else
          ColoredBox(
            color: AppColor.greenSoft,
            child: Center(
              child: Text(
                _iniziale(profile.nome),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppDim.exportName,
                  fontWeight: FontWeight.w800,
                  color: AppColor.greenDark,
                ),
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x26000000),
                Color(0x00000000),
                Color(0x00000000),
                Color(0xB8000000),
              ],
              stops: [0, 0.35, 0.55, 1],
            ),
          ),
        ),
        Positioned(
          left: AppDim.exportOverlayPad,
          top: AppDim.exportOverlayPad,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDim.exportBadgePadH,
              vertical: AppDim.exportBadgePadV,
            ),
            decoration: BoxDecoration(
              color: _pillColor(profile.statoPubblico),
              borderRadius: BorderRadius.circular(AppDim.radChip),
            ),
            child: Text(
              profile.statoPillola,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppDim.exportBadge,
                fontWeight: FontWeight.w800,
                color: AppColor.card,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Positioned(
          right: AppDim.exportOverlayPad,
          top: AppDim.exportCardGap + AppDim.gapS,
          child: Container(
            key: AdoptionCardWidget.logoKey,
            padding: const EdgeInsets.all(AppDim.exportLogoPad),
            decoration: BoxDecoration(
              color: const Color(0xD9FFFFFF),
              borderRadius: BorderRadius.circular(AppDim.exportLogoRad),
            ),
            child: logo != null && logo.isNotEmpty
                ? (profile.associazione.logoFromAsset
                      ? Image.asset(
                          logoAssetPath,
                          height: AppDim.exportLogoH,
                          fit: BoxFit.contain,
                        )
                      : Image.memory(
                          logo,
                          height: AppDim.exportLogoH,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ))
                : Text(
                    profile.associazione.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.h2,
                      fontWeight: FontWeight.w800,
                      color: AppColor.ink,
                    ),
                  ),
          ),
        ),
        Positioned(
          left: AppDim.exportOverlayPad,
          right: AppDim.exportOverlayPad,
          bottom: AppDim.gapXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppDim.exportName,
                  fontWeight: FontWeight.w800,
                  color: AppColor.card,
                  height: 1,
                  letterSpacing: -1.2,
                  shadows: [
                    Shadow(color: Color(0x66000000), blurRadius: 8),
                  ],
                ),
              ),
              if (profile.slogan.isNotEmpty)
                Text(
                  profile.slogan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppDim.exportSlogan,
                    fontStyle: FontStyle.italic,
                    color: AppColor.card,
                    height: AppDim.lineH,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.profile});
  final AdoptionProfile profile;

  @override
  Widget build(BuildContext context) {
    final femmina = profile.isFemmina;
    final eta = _etaCorta(profile.etaTesto);
    final peso = profile.pesoTesto.replaceFirst('Circa ', '');
    final sterile = !profile.sterilizzato ? '—' : 'Sì';
    final vaccini = !profile.haVacciniRegistrati
        ? '—'
        : (profile.vaccinatoInRegola ? 'In regola' : 'Da fare');
    final items = [
      (
        femmina ? AppIcons.sessoF : AppIcons.sessoM,
        eta,
        dogSexLabel(profile.sesso),
      ),
      (AppIcons.razza, tagliaLabel(profile.taglia), peso),
      (
        AppIcons.sterilizzato,
        sterile,
        femmina ? 'Sterilizzata' : 'Castrato',
      ),
      (AppIcons.vaccino, vaccini, 'Vaccini'),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDim.gapS),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColor.bg,
                borderRadius: BorderRadius.circular(AppDim.exportFactRad),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDim.gapS,
                  horizontal: AppDim.gapXs,
                ),
                child: Column(
                  children: [
                    IconBadge(items[i].$1, size: AppDim.exportFactIcon),
                    const SizedBox(height: AppDim.gapXs),
                    Text(
                      items[i].$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppDim.exportFactValue,
                        fontWeight: FontWeight.w800,
                        color: AppColor.ink,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      items[i].$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppDim.exportFactLabel,
                        color: AppColor.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.profile});
  final AdoptionProfile profile;

  @override
  Widget build(BuildContext context) {
    final labels = <(String, Key?)>[
      for (final tag in profile.carattere) (tag, null),
      if (profile.conCani == ConCani.si)
        ('Ok cani', AdoptionCardWidget.okCaniKey),
      if (profile.conGatti == ConGatti.si) ('Ok gatti', null),
      if (profile.conBambini == ConBambini.si) ('Ok bambini', null),
    ];
    final shown = labels.take(6).toList();
    return Wrap(
      spacing: AppDim.gapS,
      runSpacing: AppDim.gapS,
      children: [
        for (final item in shown)
          Container(
            key: item.$2,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDim.gapM,
              vertical: AppDim.gapXs,
            ),
            decoration: BoxDecoration(
              color: AppColor.greenSoft,
              borderRadius: BorderRadius.circular(AppDim.radChip),
            ),
            child: Text(
              item.$1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppDim.exportChip,
                fontWeight: FontWeight.w700,
                color: AppColor.greenDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.profile});
  final AdoptionProfile profile;

  @override
  Widget build(BuildContext context) {
    final verb = profile.isFemmina ? 'conoscerla' : 'conoscerlo';
    final a = profile.associazione;
    final trailing = [
      if (a.telefono.isNotEmpty) a.telefono,
      if (a.citta.isNotEmpty) a.citta,
    ].join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.green,
        borderRadius: BorderRadius.circular(AppDim.exportCtaRad),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDim.gapXl,
          vertical: AppDim.gapL,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Vuoi $verb? Scrivici',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppDim.exportCta,
                  fontWeight: FontWeight.w800,
                  color: AppColor.card,
                ),
              ),
            ),
            if (trailing.isNotEmpty)
              Flexible(
                child: Text(
                  trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppDim.exportCtaSub,
                    color: AppColor.card,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _pillColor(String stato) {
  return switch (stato) {
    'in_preaffido' => AppColor.orange,
    'adottato' => AppColor.muted,
    _ => AppColor.green,
  };
}

String _iniziale(String nome) {
  final t = nome.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

String _etaCorta(String eta) {
  return eta
      .replaceFirst('Circa ', '')
      .replaceFirst(' e mezzo', ' ½')
      .replaceFirst('1 anno', '1 anno');
}
