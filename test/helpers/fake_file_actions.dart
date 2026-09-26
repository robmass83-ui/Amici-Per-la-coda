import 'dart:typed_data';

import 'package:amici_per_la_coda/data/documents/document_file_picker.dart';
import 'package:amici_per_la_coda/data/documents/file_actions.dart';
import 'package:amici_per_la_coda/data/documents/template_assets.dart';
import 'package:amici_per_la_coda/features/dogs/export/gallery_saver.dart';

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
  String? lastPath;
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
    lastPath = null;
    lastFileName = fileName;
    lastMime = mime;
    lastText = text;
  }

  @override
  Future<void> shareExistingFile({
    required String path,
    required String fileName,
    required String mime,
    required String text,
  }) async {
    lastBytes = null;
    lastPath = path;
    lastFileName = fileName;
    lastMime = mime;
    lastText = text;
  }

  @override
  Future<void> shareText(String text) async {
    lastBytes = null;
    lastPath = null;
    lastFileName = null;
    lastMime = null;
    lastText = text;
  }
}

class RecordingGallerySaver implements GallerySaver {
  Uint8List? lastBytes;
  String? lastFileName;

  @override
  Future<void> saveImage(Uint8List bytes, {required String fileName}) async {
    lastBytes = Uint8List.fromList(bytes);
    lastFileName = fileName;
  }
}

class FakeFileOpener implements FileOpener {
  Uint8List? lastBytes;
  String? lastFileName;
  String? lastMime;

  @override
  Future<void> openFile({
    required Uint8List bytes,
    required String fileName,
    required String mime,
  }) async {
    lastBytes = Uint8List.fromList(bytes);
    lastFileName = fileName;
    lastMime = mime;
  }
}
