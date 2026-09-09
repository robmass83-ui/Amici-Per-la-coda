import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/documents/file_actions.dart';
import 'package:amici_per_la_coda/data/documents/template_assets.dart';

class FakeAssetBytesLoader implements AssetBytesLoader {
  FakeAssetBytesLoader(this.files);

  final Map<String, Uint8List> files;

  @override
  Future<Uint8List> load(String assetPath) async {
    final bytes = files[assetPath];
    if (bytes == null) {
      throw StateError('Asset mancante: $assetPath');
    }
    return bytes;
  }
}

class FakeDocumentFilePicker implements DocumentFilePicker {
  FakeDocumentFilePicker({this.pdf, this.images = const []});

  PickedDocumentFile? pdf;
  List<PickedDocumentFile> images;

  @override
  Future<PickedDocumentFile?> pickPdf() async => pdf;

  @override
  Future<List<PickedDocumentFile>> pickImages() async => images;
}

class RecordingFileShare implements FileShare {
  Uint8List? lastBytes;
  String? lastFileName;
  String? lastMime;
  String? lastText;

  @override
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
    required String text,
  }) async {
    lastBytes = Uint8List.fromList(bytes);
    lastFileName = fileName;
    lastMime = mime;
    lastText = text;
  }
}

class FakeFileOpener implements FileOpener {
  String? lastFileName;

  @override
  Future<void> openFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
  }) async {
    lastFileName = fileName;
  }
}
