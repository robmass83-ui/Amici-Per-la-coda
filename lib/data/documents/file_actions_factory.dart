import '../../features/dogs/export/gal_gallery_saver.dart';
import '../../features/dogs/export/gallery_saver.dart';
import 'device_file_actions.dart';
import 'file_actions.dart';

FileShare createFileShare() => SharePlusFileShare();
FileOpener createFileOpener() => OpenFilexOpener();
GallerySaver createGallerySaver() => GalGallerySaver();
