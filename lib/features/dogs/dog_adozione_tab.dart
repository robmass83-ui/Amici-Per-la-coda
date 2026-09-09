import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/photo.dart';
import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'dog_labels.dart';
import 'dog_share.dart';
import 'dogs_providers.dart';
import 'tab_labels.dart';

// ── CONTRATTO DI LAYOUT · Tab Adozione ─────────────────────────────────────
// Padding 12/9  Column stretch
// ├ AppCard  banner adottabile  fondo greenTint
// │  SectionTitle IconBadge 20  titolo maxLines=2
// │  SizedBox 9  Text 11.5sp maxLines=4
// │  SizedBox 9  AppButton h=40
// ├ SizedBox 9
// ├ AppCard  richieste  (se presenti)
// │  riga: Expanded nome maxLines=1 · MiniBadge · data flex none
// ├ SizedBox 9
// ├ AppCard  Iter  TimelineList 5 voci
// ├ SizedBox 9
// └ AppCard  Annuncio
//    KeyValueRow  Pubblicato  (data oppure «Non pubblicato»)
//    SizedBox 9
//    AppButton grey  «Condividi scheda»
// ───────────────────────────────────────────────────────────────────────────

class DogAdozioneTab extends ConsumerWidget {
  const DogAdozioneTab({super.key, required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(dogAdoptionsProvider(dog.id));
    final nome = dogDisplayName(dog.nome);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                title: dog.adottabile
                    ? '$nome è adottabile'
                    : '$nome non è adottabile',
                icon: const IconBadge(
                  AppIcons.adottabile,
                  size: IconBadge.inTitle,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              Text(
                _bannerText(dog),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.value,
                  color: AppColor.ink2,
                  height: AppDim.lineH,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                label: 'Registra nuova richiesta',
                onPressed: () => context.push(
                  AppRoutes.nuovaRichiestaPer(dog.id),
                ),
              ),
            ],
          ),
        ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: AppDim.gapM),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  title: 'Richieste ricevute',
                  icon: IconBadge(AppIcons.richieste, size: IconBadge.inTitle),
                ),
                const SizedBox(height: AppDim.gapM),
                for (var i = 0; i < requests.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDim.gapS),
                  _RequestRow(adoption: requests[i]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppDim.gapM),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                title: 'Iter di adozione',
                icon: IconBadge(AppIcons.iter, size: IconBadge.inTitle),
              ),
              SizedBox(height: AppDim.gapM),
              TimelineList(
                items: [
                  TimelineItem(
                    title: '1 · Richiesta ricevuta',
                    subtitle: 'Modulo online o in sede',
                  ),
                  TimelineItem(
                    title: '2 · Colloquio conoscitivo',
                    subtitle: 'Con il volontario referente',
                  ),
                  TimelineItem(
                    title: '3 · Visita pre-affido',
                    subtitle: 'Controllo casa e recinzione',
                  ),
                  TimelineItem(
                    title: '4 · Preaffido 30 giorni',
                    subtitle: 'Modulo firmato + documento identità',
                  ),
                  TimelineItem(
                    title: '5 · Adozione definitiva',
                    subtitle: 'Passaggio microchip in anagrafe canina',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDim.gapM),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Annuncio pubblico',
                icon: IconBadge(AppIcons.annuncio, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapM),
              KeyValueRow(
                label: 'Pubblicato',
                value: _pubblicatoValue(dog),
                valueColor: dog.pubblicato ? AppColor.green : null,
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                label: 'Condividi scheda',
                variant: AppButtonVariant.grey,
                onPressed: () async {
                  final photos = ref
                      .read(photosByDogProvider(dog.id))
                      .maybeWhen(
                        data: (items) => items,
                        orElse: () => const <Photo>[],
                      );
                  await condividiSchedaCane(
                    dog: dog,
                    now: ref.read(dogListNowProvider),
                    photos: photos,
                    photosRepo: ref.read(photoRepositoryProvider),
                  );
                  if (context.mounted) {
                    AppToast.show(context, 'Testo copiato negli appunti.');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _pubblicatoValue(Dog dog) {
  if (!dog.pubblicato) {
    return 'Non pubblicato';
  }
  final at = dog.dataPubblicazione;
  if (at == null) {
    return 'Sì';
  }
  return formatItalianDate(at);
}

String _bannerText(Dog dog) {
  if (dog.slogan.isNotEmpty) {
    return dog.slogan;
  }
  if (dog.descrizione.isNotEmpty) {
    return dog.descrizione;
  }
  if (dog.adottabile) {
    return 'In attesa di una famiglia.';
  }
  return 'Al momento non è in adozione.';
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.adoption});

  final Adoption adoption;

  @override
  Widget build(BuildContext context) {
    final name =
        '${adoption.richiedente.nome} ${adoption.richiedente.cognome}'.trim();
    return InkWell(
      onTap: () => context.push(AppRoutes.richiesta(adoption.id)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name.isEmpty ? '—' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.value,
                fontWeight: FontWeight.w600,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
          ),
          const SizedBox(width: AppDim.gapS),
          MiniBadge(
            label: adoptionStatoLabel(adoption.stato),
            variant: MiniBadgeVariant.purple,
          ),
          const SizedBox(width: AppDim.gapS),
          Text(
            formatItalianDate(adoption.dataRichiesta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.caption,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
        ],
      ),
    );
  }
}
