import '../../features/dogs/export/gallery_saver.dart';
import '../../features/dogs/export/web_gallery_saver.dart';
import 'file_actions.dart';
import 'web_file_actions.dart';

FileShare createFileShare() => WebFileShare();
FileOpener createFileOpener() => WebFileOpener();
GallerySaver createGallerySaver() => WebGallerySaver();
