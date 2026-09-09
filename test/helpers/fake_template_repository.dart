import 'dart:async';
import 'dart:convert';

import 'package:amici_per_la_coda/data/documents/template_assets.dart';
import 'package:amici_per_la_coda/data/models/document_template.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryTemplateRepository implements TemplateRepository {
  InMemoryTemplateRepository([List<DocumentTemplate> items = const []])
    : _items = List.of(items);

  final List<DocumentTemplate> _items;
  final _controller = StreamController<List<DocumentTemplate>>.broadcast();

  List<DocumentTemplate> get items => List.unmodifiable(_items);

  @override
  Stream<List<DocumentTemplate>> watchAll() async* {
    yield List<DocumentTemplate>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<DocumentTemplate?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> save(DocumentTemplate template) async {
    _items.removeWhere((item) => item.id == template.id);
    _items.add(template);
    _controller.add(List<DocumentTemplate>.unmodifiable(_items));
  }

  @override
  Future<void> ensureDefaults({
    required AssetBytesLoader loader,
    required String uid,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    for (final spec in defaultTemplates) {
      if (await getById(spec.id) != null) {
        continue;
      }
      final bytes = await loader.load(spec.assetPath);
      await save(
        DocumentTemplate(
          id: spec.id,
          nome: spec.nome,
          descrizione: spec.descrizione,
          fileName: spec.fileName,
          mime: 'application/pdf',
          pdfB64: base64Encode(bytes),
          versione: 1,
          aggiornatoIl: at,
          aggiornatoDa: uid,
        ),
      );
    }
  }
}
