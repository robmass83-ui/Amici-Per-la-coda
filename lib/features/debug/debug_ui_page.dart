import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

/// Catalogo di tutti i componenti del design system.
class DebugUiPage extends StatefulWidget {
  const DebugUiPage({super.key});

  @override
  State<DebugUiPage> createState() => _DebugUiPageState();
}

class _DebugUiPageState extends State<DebugUiPage> {
  String _chip = 'In rifugio';
  int _segment = 0;

  static const _tabs = [
    'Scheda',
    'Salute',
    'Adozione',
    'Spese',
    'Documenti',
    'Note',
    'Altro',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: AppScaffold(
        title: 'Catalogo UI',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
        onEdit: () => AppToast.show(context, 'Modifica'),
        onShare: () => AppToast.show(context, 'Condividi'),
        onMore: () => _openSheet(context),
        body: SingleChildScrollView(
          padding: AppDim.pagePad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'Logo',
                icon: IconBadge(AppIcons.adottabile, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapS),
              const AppCard(
                child: Column(
                  children: [
                    AppLogo(),
                    SizedBox(height: AppDim.gapL),
                    AppLogo(variant: AppLogoVariant.hero),
                  ],
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(
                title: 'Card e testi',
                icon: IconBadge(AppIcons.carattere, size: IconBadge.inTitle),
              ),
              const SizedBox(height: AppDim.gapS),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      icon: IconBadge(AppIcons.inRifugio),
                      label: 'Box',
                      value: 'B7 — settore B',
                    ),
                    SizedBox(height: AppDim.gapS),
                    InfoRow(
                      icon: IconBadge(AppIcons.microchip),
                      label: 'Microchip',
                      value: '380260043210987',
                    ),
                    SizedBox(height: AppDim.gapS),
                    KeyValueRow(label: 'Peso', value: '18,5 kg'),
                    KeyValueRow(
                      label: 'Provenienza',
                      value: 'Corleto Perticara (PZ)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(title: 'Badge e filtri'),
              const SizedBox(height: AppDim.gapS),
              const Wrap(
                spacing: AppDim.gapS,
                runSpacing: AppDim.gapS,
                children: [
                  MiniBadge(
                    label: 'In rifugio',
                    variant: MiniBadgeVariant.green,
                  ),
                  MiniBadge(label: 'Adozione', variant: MiniBadgeVariant.red),
                  MiniBadge(label: 'Sanitario', variant: MiniBadgeVariant.blue),
                  MiniBadge(label: 'Spese', variant: MiniBadgeVariant.orange),
                  MiniBadge(
                    label: 'Documenti',
                    variant: MiniBadgeVariant.purple,
                  ),
                  MiniBadge(label: 'Neutro', variant: MiniBadgeVariant.neutral),
                ],
              ),
              const SizedBox(height: AppDim.gapS),
              Wrap(
                spacing: AppDim.gapS,
                runSpacing: AppDim.gapS,
                children: [
                  for (final label in const [
                    'In rifugio',
                    'In stallo',
                    'Adottabile',
                    'In cura',
                  ])
                    AppChip(
                      label: label,
                      selected: _chip == label,
                      onSelected: () => setState(() => _chip = label),
                    ),
                ],
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(title: 'Statistiche'),
              const SizedBox(height: AppDim.gapS),
              const Wrap(
                spacing: AppDim.gapM,
                runSpacing: AppDim.gapM,
                children: [
                  SizedBox(
                    width: AppDim.fabSize * 2 + AppDim.gapXl,
                    child: StatTile(
                      icon: IconBadge(
                        AppIcons.inRifugio,
                        size: IconBadge.inStat,
                      ),
                      label: 'In rifugio',
                      value: '24',
                    ),
                  ),
                  SizedBox(
                    width: AppDim.fabSize * 2 + AppDim.gapXl,
                    child: StatTile(
                      icon: IconBadge(
                        AppIcons.adottabile,
                        size: IconBadge.inStat,
                      ),
                      label: 'Adozioni',
                      value: '11',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(title: 'Form'),
              const SizedBox(height: AppDim.gapS),
              const AppTextField(
                label: 'Email',
                hint: 'nome@associazione.it',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDim.gapS),
              const AppTextField(
                label: 'Microchip',
                hint: '15 cifre',
                errorText: 'Il microchip deve avere 15 cifre',
              ),
              const SizedBox(height: AppDim.gapS),
              AppSegmented(
                values: const ['Sì', 'No', 'Da testare'],
                selectedIndex: _segment,
                onChanged: (index) => setState(() => _segment = index),
              ),
              const SizedBox(height: AppDim.gapS),
              AppButton(
                label: 'Primario',
                onPressed: () => AppToast.show(context, 'Salvato'),
              ),
              const SizedBox(height: AppDim.gapS),
              const Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Ghost',
                      variant: AppButtonVariant.ghost,
                      onPressed: null,
                      expand: true,
                    ),
                  ),
                  SizedBox(width: AppDim.gapS),
                  Expanded(
                    child: AppButton(
                      label: 'Grigio',
                      variant: AppButtonVariant.grey,
                      onPressed: null,
                      expand: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDim.gapS),
              AppButton(
                label: 'Ghost attivo',
                variant: AppButtonVariant.ghost,
                onPressed: () => AppToast.show(context, 'Ghost'),
              ),
              const SizedBox(height: AppDim.gapS),
              AppButton(
                label: 'Grigio attivo',
                variant: AppButtonVariant.grey,
                onPressed: () => AppToast.show(context, 'Grigio'),
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(title: 'Timeline e menu'),
              const SizedBox(height: AppDim.gapS),
              const AppCard(
                child: TimelineList(
                  items: [
                    TimelineItem(
                      title: 'Vaccino cimurro',
                      subtitle: '12/03/2026 · Dr. Greco',
                    ),
                    TimelineItem(
                      title: 'Sverminazione',
                      subtitle: '02/02/2026',
                      color: AppColor.blue,
                    ),
                    TimelineItem(
                      title: 'Visita ingresso',
                      subtitle: '18/01/2026',
                      color: AppColor.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDim.gapS),
              AppCard(
                child: Column(
                  children: [
                    OptionRow(
                      icon: const IconBadge(
                        AppIcons.modifica,
                        size: IconBadge.inMenu,
                      ),
                      title: 'Modifica scheda',
                      subtitle: 'Anagrafica, box, referente',
                      onTap: () => AppToast.show(context, 'Modifica scheda'),
                    ),
                    OptionRow(
                      icon: const IconBadge(
                        AppIcons.foto,
                        size: IconBadge.inMenu,
                      ),
                      title: 'Aggiungi foto',
                      subtitle: 'Fotocamera o galleria',
                      onTap: () => AppToast.show(context, 'Foto'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(title: 'Stato vuoto'),
              const AppCard(
                child: EmptyState(
                  icon: IconBadge(AppIcons.carattere),
                  message: 'Nessun cane corrisponde ai filtri.',
                  actionLabel: 'Azzera filtri',
                  onAction: null,
                ),
              ),
              const SizedBox(height: AppDim.gapS),
              EmptyState(
                icon: const IconBadge(AppIcons.cerca),
                message: 'Nessun risultato in archivio.',
                actionLabel: 'Nuova ricerca',
                onAction: () => AppToast.show(context, 'Ricerca'),
              ),
              const SizedBox(height: AppDim.gapM),
              const SectionTitle(title: 'TabBar 7 voci'),
              const SizedBox(height: AppDim.gapS),
              const AppCard(
                padding: EdgeInsets.zero,
                child: TabBar(
                  isScrollable: false,
                  tabs: [
                    _CompactTab(label: 'Scheda'),
                    _CompactTab(label: 'Salute'),
                    _CompactTab(label: 'Adozione'),
                    _CompactTab(label: 'Spese'),
                    _CompactTab(label: 'Documenti'),
                    _CompactTab(label: 'Note'),
                    _CompactTab(label: 'Altro'),
                  ],
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              AppButton(
                label: 'Apri bottom sheet',
                variant: AppButtonVariant.grey,
                onPressed: () => _openSheet(context),
              ),
              const SizedBox(height: AppDim.gapXl),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    unawaited(
      AppSheet.show(
        context: context,
        title: 'Nuovo',
        children: [
          OptionRow(
            icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
            title: 'Nuovo cane',
            subtitle: 'Profilo in tre passaggi',
            onTap: () => Navigator.of(context).pop(),
          ),
          OptionRow(
            icon: const IconBadge(AppIcons.adottabile, size: IconBadge.inMenu),
            title: 'Richiesta adozione',
            subtitle: 'Collega a un cane',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _CompactTab extends StatelessWidget implements PreferredSizeWidget {
  const _CompactTab({required this.label});

  final String label;

  @override
  Size get preferredSize => const Size.fromHeight(AppDim.tabBarH);

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: AppDim.tabBarH,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppText.micro,
          height: AppDim.lineH,
        ),
      ),
    );
  }
}
