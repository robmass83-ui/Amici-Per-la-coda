import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/format_it.dart';
import '../../../data/documents/template_assets.dart';
import '../../../data/models/enums.dart';
import '../../../ui/tokens.dart';
import '../dog_labels.dart';
import 'adoption_profile.dart';

class AdoptionPdfFonts {
  const AdoptionPdfFonts({
    required this.regular,
    required this.italic,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font italic;
  final pw.Font bold;

  static const regularAsset = 'assets/fonts/Roboto-Regular.ttf';
  static const italicAsset = 'assets/fonts/Roboto-Italic.ttf';
  static const boldAsset = 'assets/fonts/Roboto-Bold.ttf';

  static Future<AdoptionPdfFonts> load([AssetBytesLoader? assets]) async {
    final loader = assets ?? const RootBundleAssetLoader();
    final regular = await loader.load(regularAsset);
    final italic = await loader.load(italicAsset);
    final bold = await loader.load(boldAsset);
    return AdoptionPdfFonts(
      regular: pw.Font.ttf(
        ByteData.sublistView(regular),
      ),
      italic: pw.Font.ttf(ByteData.sublistView(italic)),
      bold: pw.Font.ttf(ByteData.sublistView(bold)),
    );
  }
}

PdfColor _pdf(Color color) => PdfColor.fromInt(color.toARGB32());

final _green = _pdf(AppColor.green);
final _greenDark = _pdf(AppColor.greenDark);
final _greenSoft = _pdf(AppColor.greenSoft);
final _ink = _pdf(AppColor.ink);
final _muted = _pdf(AppColor.muted);
final _faint = _pdf(AppColor.faint);
final _line = _pdf(AppColor.line);
final _red = _pdf(AppColor.red);
final _orange = _pdf(AppColor.orange);
final _card = _pdf(AppColor.card);
final _pinkSoft = _pdf(AppColor.pinkSoft);
final _blueSoft = _pdf(AppColor.blueSoft);
final _redSoft = _pdf(AppColor.redSoft);
final _neutral = _pdf(AppColor.neutralSoft);

const _mm = PdfPageFormat.mm;
const _heroW = 62.0;
const _heroH = 52.0;
const _galleryCols = 3;
const _galleryAspect = 1.1;
const _galleryGap = 4.0;

pw.TextStyle _latin({
  double size = 8,
  pw.FontWeight? weight,
  PdfColor? color,
  double? spacing,
}) {
  return pw.TextStyle(
    font: weight == pw.FontWeight.bold
        ? pw.Font.helveticaBold()
        : pw.Font.helvetica(),
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
  );
}

Future<Uint8List> buildAdoptionPdf(
  AdoptionProfile profile, {
  AdoptionPdfFonts? fonts,
}) async {
  final loaded = fonts ?? await AdoptionPdfFonts.load();
  final theme = pw.ThemeData.withFont(
    base: loaded.regular,
    italic: loaded.italic,
    bold: loaded.bold,
  );
  final story = storiaSchedaAdozione(profile);
  final missing = [
    if (profile.haDatoSanitario &&
        (!profile.haVacciniRegistrati ||
            !profile.haAntiparassitarioRegistrato ||
            profile.testLeishmania == null))
      'non registrato',
  ];
  final catalog = [
    story,
    if (profile.altreFoto.isNotEmpty) 'Le foto di ${profile.nome}',
    ...missing,
  ].join('\n');

  final doc = pw.Document(
    theme: theme,
    title: 'Scheda di adozione ${profile.nome}',
    subject: catalog,
  );
  final pageFormat = PdfPageFormat.a4.copyWith(
    marginTop: 18 * _mm,
    marginBottom: 18 * _mm,
    marginLeft: 18 * _mm,
    marginRight: 18 * _mm,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      maxPages: 3,
      header: (context) => _Header(
        profile: profile,
        galleryPage: context.pageNumber > 1,
      ),
      footer: (context) => _Footer(
        profile: profile,
        page: context.pageNumber,
        pages: context.pagesCount,
        galleryPage: context.pageNumber > 1,
      ),
      build: (context) => [
        _Hero(profile: profile),
        pw.SizedBox(height: 6),
        _HealthBlock(profile: profile),
        pw.SizedBox(height: 6),
        _CarattereEStoria(profile: profile, story: story),
        ..._galleryBlocks(profile),
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _galleryBlocks(AdoptionProfile profile) {
  final photos = profile.altreFoto;
  if (photos.isEmpty) {
    return const [];
  }
  final out = <pw.Widget>[];
  final first = photos.take(_galleryCols).toList();
  out.add(pw.SizedBox(height: 6));
  out.add(_FirstGalleryBlock(nome: profile.nome, photos: first));
  for (var i = _galleryCols; i < photos.length; i += _galleryCols) {
    final end = i + _galleryCols > photos.length
        ? photos.length
        : i + _galleryCols;
    out.add(pw.SizedBox(height: _galleryGap * _mm));
    out.add(_GalleryRow(photos: photos.sublist(i, end)));
  }
  return out;
}

class _Header extends pw.StatelessWidget {
  _Header({required this.profile, required this.galleryPage});
  final AdoptionProfile profile;
  final bool galleryPage;

  @override
  pw.Widget build(pw.Context context) {
    final logo = profile.associazione.logo;
    final label = galleryPage
        ? 'LE FOTO DI ${profile.nome.toUpperCase()}'
        : 'SCHEDA DI ADOZIONE';
    return pw.Column(
      children: [
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(),
            1: pw.IntrinsicColumnWidth(),
          },
          children: [
            pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                if (logo != null && logo.isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(
                      pw.MemoryImage(logo),
                      height: 14 * _mm,
                      fit: pw.BoxFit.contain,
                    ),
                  )
                else
                  pw.SizedBox(height: 14 * _mm),
                pw.Text(
                  label,
                  style: _latin(
                    size: 7,
                    weight: pw.FontWeight.bold,
                    color: _green,
                    spacing: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, color: _green),
        pw.SizedBox(height: 6),
      ],
    );
  }
}

class _Hero extends pw.StatelessWidget {
  _Hero({required this.profile});
  final AdoptionProfile profile;

  @override
  pw.Widget build(pw.Context context) {
    final photo = profile.fotoCopertina;
    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(_heroW * _mm),
        1: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.ClipRRect(
              horizontalRadius: 3 * _mm,
              verticalRadius: 3 * _mm,
              child: pw.Container(
                width: _heroW * _mm,
                height: _heroH * _mm,
                color: _greenSoft,
                alignment: pw.Alignment.center,
                child: photo == null || photo.isEmpty
                    ? pw.Text(
                        _iniziale(profile.nome),
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: _greenDark,
                        ),
                      )
                    : pw.Image(
                        pw.MemoryImage(photo),
                        width: _heroW * _mm,
                        height: _heroH * _mm,
                        fit: pw.BoxFit.cover,
                      ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.nome,
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                      letterSpacing: -1,
                    ),
                  ),
                  if (profile.slogan.isNotEmpty)
                    pw.Text(
                      profile.slogan,
                      maxLines: 2,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: _muted,
                      ),
                    ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _pillColor(profile.statoPubblico),
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      profile.statoPillola,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: _card,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _FactsGrid(profile: profile),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

PdfColor _pillColor(String stato) {
  return switch (stato) {
    'in_preaffido' => _orange,
    'adottato' => _muted,
    _ => _green,
  };
}

class _FactsGrid extends pw.StatelessWidget {
  _FactsGrid({required this.profile});
  final AdoptionProfile profile;

  @override
  pw.Widget build(pw.Context context) {
    final femmina = profile.isFemmina;
    final facts = <(String, String, PdfColor)>[
      ('Sesso', dogSexLabel(profile.sesso), _pinkSoft),
      if (!profile.etaSconosciuta) ('Età', profile.etaTesto, _blueSoft),
      if (profile.razza.isNotEmpty)
        (
          'Razza · taglia',
          '${profile.razza} · ${tagliaLabel(profile.taglia)}',
          _neutral,
        ),
      if (!profile.pesoSconosciuto) ('Peso', profile.pesoTesto, _neutral),
      if (profile.provenienza.isNotEmpty)
        (
          femmina ? 'Arrivata da' : 'Arrivato da',
          profile.provenienza,
          _redSoft,
        ),
      if (profile.inRifugioDa.isNotEmpty)
        ('In rifugio da', profile.inRifugioDa, _blueSoft),
    ];
    final rows = <pw.TableRow>[];
    for (var i = 0; i < facts.length; i += 2) {
      rows.add(
        pw.TableRow(
          children: [
            _fact(facts[i]),
            if (i + 1 < facts.length) _fact(facts[i + 1]) else pw.SizedBox(),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.Widget _fact((String, String, PdfColor) item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 8, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: item.$3,
              borderRadius: pw.BorderRadius.circular(4),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.$1,
                maxLines: 1,
                style: pw.TextStyle(fontSize: 6.5, color: _muted),
              ),
              pw.Text(
                item.$2,
                maxLines: 2,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthBlock extends pw.StatelessWidget {
  _HealthBlock({required this.profile});
  final AdoptionProfile profile;

  @override
  pw.Widget build(pw.Context context) {
    if (!profile.haDatoSanitario) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.8),
          borderRadius: pw.BorderRadius.circular(7),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Dati sanitari non ancora registrati: chiedici pure.',
          maxLines: 1,
          style: _latin(size: 8, color: _muted),
        ),
      );
    }
    final femmina = profile.isFemmina;
    final sterileTitle = femmina ? 'Sterilizzata' : 'Castrato';
    final sterileSub = !profile.sterilizzato
        ? 'non registrato'
        : (profile.dataSterilizzazione == null
              ? 'Sì'
              : formatItalianDate(profile.dataSterilizzazione!));
    final vaccTitle = femmina ? 'Vaccinata' : 'Vaccinato';
    final String vaccSub;
    if (!profile.haVacciniRegistrati) {
      vaccSub = 'non registrato';
    } else if (profile.dataVaccino != null) {
      vaccSub = 'richiamo ${formatItalianDate(profile.dataVaccino!)}';
    } else {
      vaccSub = profile.vaccinatoInRegola ? 'in regola' : 'da fare';
    }
    final paraSub = !profile.haAntiparassitarioRegistrato
        ? 'non registrato'
        : (profile.antiparassitarioInRegola ? 'in regola' : 'da fare');
    final leish = profile.testLeishmania;
    final leishSub = leish == null
        ? 'non registrato'
        : (leish == 'negativo' ? 'negativa' : 'positiva');
    final tiles = [
      (sterileTitle, sterileSub),
      (vaccTitle, vaccSub),
      ('Antiparassitario', paraSub),
      ('Leishmania', leishSub),
    ];
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            for (var i = 0; i < tiles.length; i++)
              pw.Padding(
                padding: pw.EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: _tile(tiles[i].$1, tiles[i].$2),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _tile(String title, String sub) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            sub,
            maxLines: 1,
            style: pw.TextStyle(fontSize: 6.5, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _CarattereEStoria extends pw.StatelessWidget {
  _CarattereEStoria({required this.profile, required this.story});
  final AdoptionProfile profile;
  final String story;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 10),
              child: _CarattereCol(profile: profile),
            ),
            _StoriaCol(story: story),
          ],
        ),
      ],
    );
  }
}

class _CarattereCol extends pw.StatelessWidget {
  _CarattereCol({required this.profile});
  final AdoptionProfile profile;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CARATTERE',
          style: _latin(
            size: 8.5,
            weight: pw.FontWeight.bold,
            color: _green,
            spacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 5),
        if (profile.carattere.isNotEmpty) ...[
          pw.Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (final tag in profile.carattere) _chip(tag),
            ],
          ),
          pw.SizedBox(height: 7),
        ],
        _compat(
          'Con le persone',
          conPersoneLabel(profile.conPersone),
          _tonePersone(profile.conPersone),
        ),
        _compat(
          'Con altri cani',
          conCaniLabel(profile.conCani),
          _toneCani(profile.conCani),
        ),
        _compat(
          'Con i gatti',
          conGattiLabel(profile.conGatti),
          _toneGatti(profile.conGatti),
        ),
        _compat(
          'Con i bambini',
          conBambiniLabel(profile.conBambini),
          _toneBambini(profile.conBambini),
        ),
        if (profile.noteCarattere.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            profile.noteCarattere,
            maxLines: 4,
            style: pw.TextStyle(fontSize: 7, color: _muted),
          ),
        ],
      ],
    );
  }

  pw.Widget _chip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: _greenSoft,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _greenDark,
        ),
      ),
    );
  }

  pw.Widget _compat(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(),
          1: pw.IntrinsicColumnWidth(),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Text(
                label,
                maxLines: 1,
                style: pw.TextStyle(fontSize: 7.5, color: _ink),
              ),
              pw.Text(
                value,
                maxLines: 1,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoriaCol extends pw.StatelessWidget {
  _StoriaCol({required this.story});
  final String story;

  @override
  pw.Widget build(pw.Context context) {
    final compact = story.length > 900;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LA SUA STORIA',
          style: _latin(
            size: 8.5,
            weight: pw.FontWeight.bold,
            color: _green,
            spacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          story,
          textAlign: pw.TextAlign.justify,
          style: pw.TextStyle(
            fontSize: compact ? 7.5 : 8,
            lineSpacing: compact ? 3 : 4,
            color: _pdf(AppColor.ink2),
          ),
        ),
      ],
    );
  }
}

class _FirstGalleryBlock extends pw.StatelessWidget {
  _FirstGalleryBlock({required this.nome, required this.photos});
  final String nome;
  final List<Uint8List> photos;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (context.pageNumber == 1) ...[
          pw.Text(
            'Le foto di $nome',
            style: _latin(
              size: 8.5,
              weight: pw.FontWeight.bold,
              color: _green,
              spacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 4),
        ],
        _GalleryRow(photos: photos),
      ],
    );
  }
}

class _GalleryRow extends pw.StatelessWidget {
  _GalleryRow({required this.photos});
  final List<Uint8List> photos;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            for (var c = 0; c < _galleryCols; c++)
              pw.Padding(
                padding: pw.EdgeInsets.only(
                  right: c < _galleryCols - 1 ? _galleryGap * _mm : 0,
                ),
                child: c < photos.length
                    ? _cell(photos[c])
                    : pw.SizedBox(),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _cell(Uint8List bytes) {
    return pw.ClipRRect(
      horizontalRadius: 2 * _mm,
      verticalRadius: 2 * _mm,
      child: pw.AspectRatio(
        aspectRatio: _galleryAspect,
        child: pw.Image(
          pw.MemoryImage(bytes),
          fit: pw.BoxFit.cover,
        ),
      ),
    );
  }
}

class _Footer extends pw.StatelessWidget {
  _Footer({
    required this.profile,
    required this.page,
    required this.pages,
    required this.galleryPage,
  });

  final AdoptionProfile profile;
  final int page;
  final int pages;
  final bool galleryPage;

  @override
  pw.Widget build(pw.Context context) {
    final a = profile.associazione;
    final contact = [
      if (a.nome.isNotEmpty) a.nome,
      if (a.citta.isNotEmpty) a.citta,
    ].join(' · ');
    final lines = [
      if (a.telefono.isNotEmpty) a.telefono,
      if (a.email.isNotEmpty) a.email,
    ].join(' · ');
    final logo = a.logo;
    final leftTitle = galleryPage
        ? (a.nome.isNotEmpty ? a.nome : 'Amici per la Coda')
        : 'Vuoi conoscere ${profile.nome}?';
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.bottom,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (logo != null && logo.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(
                        pw.MemoryImage(logo),
                        height: 8 * _mm,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        leftTitle,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      if (contact.isNotEmpty)
                        pw.Text(
                          contact,
                          style: pw.TextStyle(fontSize: 7, color: _muted),
                        ),
                      if (lines.isNotEmpty)
                        pw.Text(
                          lines,
                          style: pw.TextStyle(fontSize: 7, color: _muted),
                        ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'pagina $page di $pages',
                    textAlign: pw.TextAlign.right,
                    style: _latin(
                      size: 8,
                      weight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.Text(
                    'Scheda generata il ${formatItalianDate(profile.dataGenerazione)}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 6, color: _faint),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _iniziale(String nome) {
  final t = nome.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

PdfColor _tonePersone(ConPersone v) => switch (v) {
  ConPersone.moltoSocievole => _green,
  ConPersone.selettivo => _orange,
  ConPersone.diffidente => _red,
};

PdfColor _toneCani(ConCani v) => switch (v) {
  ConCani.si => _green,
  ConCani.selettivo || ConCani.daTestare => _orange,
  ConCani.no => _red,
};

PdfColor _toneGatti(ConGatti v) => switch (v) {
  ConGatti.si => _green,
  ConGatti.daTestare => _orange,
  ConGatti.no => _red,
};

PdfColor _toneBambini(ConBambini v) => switch (v) {
  ConBambini.si => _green,
  ConBambini.soloGrandi || ConBambini.daTestare => _orange,
  ConBambini.no => _red,
};
