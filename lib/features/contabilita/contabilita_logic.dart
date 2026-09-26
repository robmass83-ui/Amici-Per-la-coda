import '../../data/models/documento_contabile.dart';

const contabilitaAvviso400 =
    "L'archivio contabile supera i 400 MB. Resta spazio, ma conviene non "
    'accumulare file inutili.';
const contabilitaPieno =
    'Archivio contabile pieno (oltre 700 MB). Libera spazio eliminando '
    'documenti vecchi.';
const contabilitaExportOffline =
    'Connessione assente: l\'esportazione richiede i file.';
const contabilitaFileRifiutato = 'Usa un PDF, JPG o PNG.';
const contabilitaNomeVuoto = 'Indica il nome del documento.';
const contabilitaImportoNonValido = 'Importo non valido.';
const contabilitaFileMancante = 'Allega un PDF, JPG o PNG.';
const contabilitaElimina =
    'Eliminare questo documento? Il file verrà cancellato. Non si può '
    'annullare.';

String messaggioAnnoDuplicato(int anno) => 'Il $anno è già presente.';

String messaggioAnnoFuori(int massimo) =>
    "L'anno deve essere fra il 1990 e il $massimo.";

bool orologioAnnoUsabile(DateTime now) => now.year >= 1990 && now.year <= 2100;

int massimoAnno(DateTime now) {
  if (!orologioAnnoUsabile(now)) {
    throw StateError('Anno di sistema non valido');
  }
  return now.year + 1;
}

String? erroreAnno(
  String raw, {
  required DateTime now,
  required Set<int> esistenti,
}) {
  final valore = raw.trim();
  final anno = int.tryParse(valore);
  final massimo = now.year + 1;
  if (!orologioAnnoUsabile(now) ||
      valore.length != 4 ||
      anno == null ||
      anno < 1990 ||
      anno > massimo ||
      anno > 2100) {
    return messaggioAnnoFuori(massimo);
  }
  if (esistenti.contains(anno)) {
    return messaggioAnnoDuplicato(anno);
  }
  return null;
}

class QuotaEsito {
  const QuotaEsito({required this.avviso, required this.rifiuto});

  final bool avviso;
  final String? rifiuto;
}

QuotaEsito valutaQuota({required int usato, required int nuova, int? vecchia}) {
  const sogliaAvviso = 400 * 1024 * 1024;
  const sogliaMassima = 700 * 1024 * 1024;
  final superaTetto = vecchia == null
      ? usato + nuova > sogliaMassima
      : nuova > vecchia && usato - vecchia + nuova > sogliaMassima;
  return QuotaEsito(
    avviso: usato > sogliaAvviso,
    rifiuto: superaTetto ? contabilitaPieno : null,
  );
}

int sommaDimensioni(Iterable<DocumentoContabile> docs) =>
    docs.fold(0, (totale, doc) => totale + doc.dimensione);

double sommaImporti(Iterable<DocumentoContabile> docs) =>
    docs.fold(0, (totale, doc) => totale + (doc.importo ?? 0));

String formatArchivioMb(int bytes) {
  final megabyte = bytes / (1024 * 1024);
  return 'Archivio: ${megabyte.toStringAsFixed(1).replaceAll('.', ',')} MB';
}

class FiltriContabilita {
  const FiltriContabilita({
    required this.nome,
    required this.tipologia,
    required this.dal,
    required this.al,
  });

  final String nome;
  final TipologiaContabile? tipologia;
  final DateTime? dal;
  final DateTime? al;
}

List<DocumentoContabile> filtraDocumenti(
  List<DocumentoContabile> docs,
  FiltriContabilita filtri,
) {
  final nome = filtri.nome.trim().toLowerCase();
  final dal = filtri.dal == null ? null : _soloData(filtri.dal!);
  final al = filtri.al == null ? null : _soloData(filtri.al!);
  return docs.where((doc) {
    final data = _soloData(doc.data);
    return doc.nome.toLowerCase().contains(nome) &&
        (filtri.tipologia == null || doc.tipologia == filtri.tipologia) &&
        (dal == null || !data.isBefore(dal)) &&
        (al == null || !data.isAfter(al));
  }).toList();
}

List<DocumentoContabile> ordinaArchivio(List<DocumentoContabile> docs) {
  final ordinati = [...docs];
  ordinati.sort((a, b) {
    final perData = b.data.compareTo(a.data);
    if (perData != 0) {
      return perData;
    }
    return b.nome.toLowerCase().compareTo(a.nome.toLowerCase());
  });
  return ordinati;
}

String? erroreNome(String raw) {
  final nome = raw.trim();
  if (nome.isEmpty) {
    return contabilitaNomeVuoto;
  }
  if (nome.length > 120) {
    return 'Il nome può avere al massimo 120 caratteri.';
  }
  return null;
}

String? erroreNota(String raw) =>
    raw.length > 1000 ? 'La nota può avere al massimo 1000 caratteri.' : null;

String? erroreImporto(String raw) {
  final valore = raw.trim();
  if (valore.isEmpty) {
    return null;
  }
  final importo = double.tryParse(valore.replaceAll(',', '.'));
  return importo == null || !importo.isFinite || importo < 0
      ? contabilitaImportoNonValido
      : null;
}

double? leggiImporto(String raw) {
  final valore = raw.trim();
  if (valore.isEmpty) {
    return null;
  }
  return double.parse(valore.replaceAll(',', '.'));
}

String slugContabile(String nome) {
  var slug = nome.trim().toLowerCase();
  const accenti = {'à': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u'};
  for (final entry in accenti.entries) {
    slug = slug.replaceAll(entry.key, entry.value);
  }
  slug = slug
      .replaceAll(RegExp('[^a-z0-9]'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (slug.length > 40) {
    slug = slug.substring(0, 40);
  }
  return slug.isEmpty ? 'documento' : slug;
}

String nomeFileZip(DocumentoContabile doc, int occorrenza) {
  final data = doc.data;
  final base =
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}_'
      '${doc.tipologia.wire}_${slugContabile(doc.nome)}';
  final suffisso = occorrenza == 1 ? '' : '_$occorrenza';
  return '$base$suffisso.${_estensione(doc.mime)}';
}

List<({DocumentoContabile doc, String fileName})> assegnaNomiZip(
  List<DocumentoContabile> docs,
) {
  final ordinati = [...docs]
    ..sort((a, b) {
      final perData = a.data.toUtc().compareTo(b.data.toUtc());
      return perData != 0 ? perData : a.id.compareTo(b.id);
    });
  final occorrenze = <String, int>{};
  return ordinati.map((doc) {
    final primoNome = nomeFileZip(doc, 1);
    final nomeBase = primoNome.substring(0, primoNome.lastIndexOf('.'));
    final occorrenza = (occorrenze[nomeBase] ?? 0) + 1;
    occorrenze[nomeBase] = occorrenza;
    return (doc: doc, fileName: nomeFileZip(doc, occorrenza));
  }).toList();
}

String riepilogoCsv(List<({DocumentoContabile doc, String fileName})> rows) {
  final csv = StringBuffer('\uFEFFNome;Data;Tipologia;Importo;Nota;File\r\n');
  for (final row in rows) {
    final doc = row.doc;
    final data =
        '${doc.data.day.toString().padLeft(2, '0')}/'
        '${doc.data.month.toString().padLeft(2, '0')}/'
        '${doc.data.year.toString().padLeft(4, '0')}';
    final importo = doc.importo?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
    csv.write(
      [
        doc.nome,
        data,
        doc.tipologia.etichetta,
        importo,
        doc.descrizione,
        row.fileName,
      ].map(_campoCsv).join(';'),
    );
    csv.write('\r\n');
  }
  return csv.toString();
}

DateTime _soloData(DateTime data) => DateTime(data.year, data.month, data.day);

String _estensione(String mime) {
  return switch (mime) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    _ => 'pdf',
  };
}

String _campoCsv(String valore) {
  if (!valore.contains(RegExp(r'[";\r\n]'))) {
    return valore;
  }
  return '"${valore.replaceAll('"', '""')}"';
}
