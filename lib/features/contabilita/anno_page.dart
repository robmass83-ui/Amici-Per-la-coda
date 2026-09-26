import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format_it.dart';
import '../../data/data_providers.dart';
import '../../data/models/documento_contabile.dart';
import '../../router.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_sheet.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/icon_badge.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../affido/affido_providers.dart';
import '../dogs/edit_permissions.dart';
import 'contabilita_logic.dart';
import 'filtri_sheet.dart';

// AnnoContabilePage
// Column
//   Wrap: anno | AppButton ghost «Esporta documentazione annuale»
//   Row h=40: Expanded AppTextField h=38 | gapS | Filtri 40x40
//   SizedBox gapS
//   riepilogo 1 riga: conteggio e formatEuro dei visibili
//   Expanded ListView: card documento, nome Expanded maxLines=1
//   AppButton primary «Aggiungi documento»
// Ricerca + gap + riepilogo: 40 + gapS + una riga caption, sotto 120 dp.

class AnnoContabilePage extends ConsumerStatefulWidget {
  const AnnoContabilePage({super.key, required this.anno});

  final int anno;

  static const esportaKey = Key('contabilita-esporta');
  static const aggiungiKey = Key('contabilita-aggiungi-doc');
  static const cercaKey = Key('contabilita-cerca');
  static const filtriKey = Key('contabilita-filtri');

  @override
  ConsumerState<AnnoContabilePage> createState() => _AnnoContabilePageState();
}

class _AnnoContabilePageState extends ConsumerState<AnnoContabilePage> {
  String _ricerca = '';
  FiltriContabilita _filtri = const FiltriContabilita(
    nome: '',
    tipologia: null,
    dal: null,
    al: null,
  );

  Future<void> _apriFiltri(BuildContext context) async {
    final risultato = await AppSheet.show<FiltriContabilita>(
      context: context,
      title: 'Filtri',
      children: [
        FiltriContabilitaSheet(
          initial: FiltriContabilita(
            nome: _ricerca,
            tipologia: _filtri.tipologia,
            dal: _filtri.dal,
            al: _filtri.al,
          ),
        ),
      ],
    );
    if (risultato != null && mounted) {
      setState(() {
        _filtri = FiltriContabilita(
          nome: _ricerca,
          tipologia: risultato.tipologia,
          dal: risultato.dal,
          al: risultato.al,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(contabilitaRepositoryProvider);
    if (repo == null) {
      return const Center(child: Text('Archivio contabile non disponibile.'));
    }
    final volunteer = ref.watch(currentVolunteerProvider);
    final puoEsportare = canWriteRecords(volunteer);
    final puoAggiungere = canCreateNotes(volunteer);

    return StreamBuilder<List<DocumentoContabile>>(
      stream: repo.watchAnno(widget.anno),
      builder: (context, snapshot) {
        final documentiDellAnno = snapshot.data ?? const [];
        final ordinati = ordinaArchivio(documentiDellAnno);
        final visibili = filtraDocumenti(
          ordinati,
          FiltriContabilita(
            nome: _ricerca,
            tipologia: _filtri.tipologia,
            dal: _filtri.dal,
            al: _filtri.al,
          ),
        );
        return Padding(
          padding: AppDim.pagePad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppDim.gapS,
                runSpacing: AppDim.gapS,
                children: [
                  Text(
                    '${widget.anno}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.title,
                      fontWeight: FontWeight.w700,
                      color: AppColor.ink,
                      height: AppDim.lineH,
                    ),
                  ),
                  if (puoEsportare)
                    AppButton(
                      key: AnnoContabilePage.esportaKey,
                      label: 'Esporta documentazione annuale',
                      variant: AppButtonVariant.ghost,
                      expand: false,
                      onPressed: documentiDellAnno.isEmpty ? null : () {},
                    ),
                ],
              ),
              const SizedBox(height: AppDim.gapM),
              SizedBox(
                height: AppDim.minTouch,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: AppTextField(
                          key: AnnoContabilePage.cercaKey,
                          hint: 'Cerca per nome',
                          fieldHeight: AppDim.searchH,
                          onChanged: (value) => setState(() {
                            _ricerca = value;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDim.gapS),
                    Tooltip(
                      message: 'Filtri',
                      child: SizedBox(
                        key: AnnoContabilePage.filtriKey,
                        width: AppDim.minTouch,
                        height: AppDim.minTouch,
                        child: Material(
                          color: AppColor.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDim.radInput,
                            ),
                            side: const BorderSide(color: AppColor.line),
                          ),
                          child: InkWell(
                            onTap: () => _apriFiltri(context),
                            borderRadius: BorderRadius.circular(
                              AppDim.radInput,
                            ),
                            child: const Center(
                              child: IconBadge(
                                AppIcons.regolazioni,
                                size: IconBadge.inTitle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDim.gapS),
              Text(
                '${visibili.length} '
                '${visibili.length == 1 ? 'documento' : 'documenti'} · '
                '${formatEuro(sommaImporti(visibili))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.caption,
                  color: AppColor.muted,
                  height: AppDim.lineH,
                ),
              ),
              const SizedBox(height: AppDim.gapM),
              Expanded(
                child: ListView.separated(
                  itemCount: visibili.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDim.gapM),
                  itemBuilder: (context, index) {
                    final documento = visibili[index];
                    return _DocumentoRow(
                      documento: documento,
                      onTap: () => context.push(
                        AppRoutes.contabilitaDocumento(
                          widget.anno,
                          documento.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (puoAggiungere) ...[
                const SizedBox(height: AppDim.gapM),
                AppButton(
                  key: AnnoContabilePage.aggiungiKey,
                  label: 'Aggiungi documento',
                  onPressed: () {},
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DocumentoRow extends StatelessWidget {
  const _DocumentoRow({required this.documento, required this.onTap});

  final DocumentoContabile documento;
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
        child: Padding(
          padding: AppDim.cardPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      documento.nome,
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
                ],
              ),
              const SizedBox(height: AppDim.gapXs),
              Row(
                children: [
                  Text(
                    formatItalianDate(documento.data),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                  const SizedBox(width: AppDim.gapS),
                  Expanded(
                    child: Text(
                      documento.tipologia.etichetta,
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
                  if (documento.importo != null) ...[
                    const SizedBox(width: AppDim.gapS),
                    Flexible(
                      child: Text(
                        formatEuro(documento.importo!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
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
                ],
              ),
              if (documento.descrizione.isNotEmpty) ...[
                const SizedBox(height: AppDim.gapXs),
                Text(
                  documento.descrizione,
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
            ],
          ),
        ),
      ),
    );
  }
}
