import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format_it.dart';
import 'stats_aggregators.dart';

String _pdfText(String value) {
  return value
      .replaceAll('€', 'EUR')
      .replaceAll('—', '-')
      .replaceAll('–', '-');
}

Future<Uint8List> reportAnnualePdf(YearStats stats) async {
  final mesi = mesiBreviAnno();
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(
          _pdfText('Amici per la Coda - Report ${stats.year}'),
          style: const pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Bullet(text: 'Adozioni concluse: ${stats.adozioniConcluse}'),
        pw.Bullet(text: 'Nuovi ingressi: ${stats.nuoviIngressi}'),
        pw.Bullet(
          text: 'Giorni medi in rifugio: ${stats.giorniMediInRifugio}',
        ),
        pw.Bullet(text: 'Rientri dopo affido: ${stats.rientriDopoAffido}'),
        pw.SizedBox(height: 12),
        pw.Text(
          'Adozioni per mese',
          style: const pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          [
            for (var i = 0; i < 12; i++)
              '${mesi[i]} ${stats.adozioniPerMese[i]}',
          ].join(' / '),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Composizione del rifugio',
          style: const pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        for (final slice in stats.composizione)
          pw.Bullet(
            text: '${slice.label}: ${slice.count} (${slice.percentuale}%)',
          ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Bilancio spese sanitarie',
          style: const pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Bullet(
          text: _pdfText(
            'Spese totali ${stats.year}: ${formatEuro(stats.speseTotali)}',
          ),
        ),
        pw.Bullet(
          text: _pdfText(
            'Donazioni ricevute: ${formatEuro(stats.donazioniRicevute)}',
          ),
        ),
        pw.Bullet(
          text: _pdfText(
            'Adozioni a distanza: ${formatEuro(stats.adozioniADistanza)}',
          ),
        ),
        pw.Bullet(text: _pdfText('Saldo: ${formatSaldo(stats.saldo)}')),
        pw.SizedBox(height: 16),
        pw.Text(
          'Generato il ${formatItalianDate(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return doc.save();
}
