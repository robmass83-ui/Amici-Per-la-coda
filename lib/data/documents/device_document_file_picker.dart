import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'document_file_picker.dart';

class DeviceDocumentFilePicker implements DocumentFilePicker {
  DeviceDocumentFilePicker({
    FilePicker? files,
    ImagePicker? images,
  }) : _files = files ?? FilePicker.platform,
       _images = images ?? ImagePicker();

  final FilePicker _files;
  final ImagePicker _images;

  @override
  Future<PickedDocumentFile?> pickPdf() async {
    final result = await _files.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return null;
    }
    return PickedDocumentFile(
      bytes: bytes,
      name: file.name,
      mime: 'application/pdf',
    );
  }

  @override
  Future<List<PickedDocumentFile>> pickImages() async {
    final picked = await _images.pickMultiImage(imageQuality: 95);
    final out = <PickedDocumentFile>[];
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        continue;
      }
      out.add(
        PickedDocumentFile(
          bytes: bytes,
          name: file.name,
          mime: file.mimeType ?? 'image/jpeg',
        ),
      );
    }
    return out;
  }
}
