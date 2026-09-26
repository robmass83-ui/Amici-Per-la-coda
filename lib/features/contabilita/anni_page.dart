import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/documento_contabile.dart';
import '../../data/repositories/contabilita_repository.dart';
import '../../router.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_sheet.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../auth/auth_providers.dart';
import '../dogs/edit_permissions.dart';
import 'contabilita_logic.dart';

// AnniContabiliPage
// Column
//   riga intestazione: titolo Contabilità | AppButton ghost «Aggiungi anno» h=40
//   testo archivio MB  caption 1 riga
//   se avviso: testo avviso  caption  maxLines 3
//   lista: riga anno Expanded + conteggio + formatEuro

class AnniContabiliPage extends ConsumerStatefulWidget {
  const AnniContabiliPage({super.key});

  static const aggiungiKey = Key('contabilita-aggiungi-anno');
  static const avvisoKey = Key('contabilita-avviso-400');
  static const archivioKey = Key('contabilita-archivio-mb');

  @override
  ConsumerState<AnniContabiliPage> createState() => _AnniContabiliPageState();
}

class _AnniContabiliPageState extends ConsumerState<AnniContabiliPage> {
  String? _errore;
  ContabilitaRepository? _repoVisibile;
  List<AnnoContabile>? _anniVisibili;
  bool _primoFramePassato = false;
  bool _creazioneAnnoPianificata = false;
  bool _creazioneAnnoTentata = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primoFramePassato = true;
      _pianificaAnnoCorrente();
    });
  }

  void _pianificaAnnoCorrente() {
    if (!_primoFramePassato ||
        _repoVisibile == null ||
        _anniVisibili == null ||
        _creazioneAnnoPianificata ||
        _creazioneAnnoTentata) {
      return;
    }
    _creazioneAnnoPianificata = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _creazioneAnnoPianificata = false;
      if (!mounted) {
        return;
      }
      _creazioneAnnoTentata = true;
      _creaAnnoCorrente(_repoVisibile!, _anniVisibili!);
    });
  }

  Future<void> _creaAnnoCorrente(
    ContabilitaRepository repo,
    List<AnnoContabile> anni,
  ) async {
    final now = DateTime.now();
    if (!orologioAnnoUsabile(now) ||
        anni.any((item) => item.anno == now.year)) {
      return;
    }
    try {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      await repo.createAnno(anno: now.year, uid: uid, now: now);
    } on AnnoGiaPresente {
      return;
    } catch (error) {
      if (mounted) {
        setState(() => _errore = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(contabilitaRepositoryProvider);
    if (repo == null) {
      return const Center(child: Text('Archivio contabile non disponibile.'));
    }
    final puoCreare = canCreateNotes(ref.watch(currentVolunteerProvider));

    return StreamBuilder<List<AnnoContabile>>(
      stream: repo.watchAnni(),
      builder: (context, anniSnapshot) {
        if (anniSnapshot.hasData) {
          _repoVisibile = repo;
          _anniVisibili = anniSnapshot.data;
          _pianificaAnnoCorrente();
        }
        final anni = [...?anniSnapshot.data]
          ..sort((a, b) => b.anno.compareTo(a.anno));
        return StreamBuilder<List<DocumentoContabile>>(
          stream: repo.watchTutti(),
          builder: (context, documentiSnapshot) {
            final documenti = documentiSnapshot.data ?? const [];
            final dimensione = sommaDimensioni(documenti);
            return Padding(
              padding: AppDim.pagePad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Contabilità',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: AppText.title,
                            fontWeight: FontWeight.w700,
                            color: AppColor.ink,
                            height: AppDim.lineH,
                          ),
                        ),
                      ),
                      if (puoCreare) ...[
                        const SizedBox(width: AppDim.gapS),
                        AppButton(
                          key: AnniContabiliPage.aggiungiKey,
                          label: 'Aggiungi anno',
                          variant: AppButtonVariant.ghost,
                          expand: false,
                          onPressed: () => _apriAggiungiAnno(
                            context,
                            repo,
                            anni.map((item) => item.anno).toSet(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDim.gapS),
                  Text(
                    formatArchivioMb(dimensione),
                    key: AnniContabiliPage.archivioKey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                  if (dimensione > 400 * 1024 * 1024) ...[
                    const SizedBox(height: AppDim.gapXs),
                    const Text(
                      contabilitaAvviso400,
                      key: AnniContabiliPage.avvisoKey,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: AppColor.orange,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                  if (_errore != null) ...[
                    const SizedBox(height: AppDim.gapXs),
                    Text(
                      _errore!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.caption,
                        color: AppColor.red,
                        height: AppDim.lineH,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDim.gapM),
                  Expanded(
                    child: ListView.separated(
                      itemCount: anni.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDim.gapM),
                      itemBuilder: (context, index) {
                        final anno = anni[index].anno;
                        final documentiAnno = documenti
                            .where((doc) => doc.anno == anno)
                            .toList();
                        return _AnnoRow(
                          anno: anno,
                          conteggio: documentiAnno.length,
                          importo: sommaImporti(documentiAnno),
                          onTap: () =>
                              context.push(AppRoutes.contabilitaAnno(anno)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _apriAggiungiAnno(
    BuildContext context,
    ContabilitaRepository repo,
    Set<int> anni,
  ) {
    return AppSheet.show<void>(
      context: context,
      title: 'Aggiungi anno',
      children: [_AggiungiAnnoForm(repo: repo, anni: anni)],
    );
  }
}

class _AnnoRow extends StatelessWidget {
  const _AnnoRow({
    required this.anno,
    required this.conteggio,
    required this.importo,
    required this.onTap,
  });

  final int anno;
  final int conteggio;
  final double importo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radCard),
        side: const BorderSide(color: AppColor.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.radCard),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDim.minTouch),
          child: Padding(
            padding: AppDim.cardPad,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$anno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.h2,
                      fontWeight: FontWeight.w700,
                      color: AppColor.ink,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
                const SizedBox(width: AppDim.gapS),
                Flexible(
                  child: Text(
                    '$conteggio documenti',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
                const SizedBox(width: AppDim.gapS),
                Flexible(
                  child: Text(
                    formatEuro(importo),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.value,
                      fontWeight: FontWeight.w700,
                      color: AppColor.ink,
                      height: AppDim.lineH,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AggiungiAnnoForm extends StatefulWidget {
  const _AggiungiAnnoForm({required this.repo, required this.anni});

  final ContabilitaRepository repo;
  final Set<int> anni;

  @override
  State<_AggiungiAnnoForm> createState() => _AggiungiAnnoFormState();
}

class _AggiungiAnnoFormState extends State<_AggiungiAnnoForm> {
  final _controller = TextEditingController();
  String? _errore;
  bool _salvando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _crea() async {
    final now = DateTime.now();
    final errore = erroreAnno(
      _controller.text,
      now: now,
      esistenti: widget.anni,
    );
    if (errore != null) {
      setState(() => _errore = errore);
      return;
    }
    setState(() {
      _errore = null;
      _salvando = true;
    });
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final uid = container.read(authRepositoryProvider).currentUser?.uid ?? '';
      await widget.repo.createAnno(
        anno: int.parse(_controller.text.trim()),
        uid: uid,
        now: now,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AnnoGiaPresente catch (error) {
      if (mounted) {
        setState(() => _errore = error.toString());
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errore = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _controller,
          hint: '2026',
          keyboardType: TextInputType.number,
          errorText: _errore,
        ),
        const SizedBox(height: AppDim.gapM),
        AppButton(label: 'Crea', onPressed: _salvando ? null : _crea),
      ],
    );
  }
}
