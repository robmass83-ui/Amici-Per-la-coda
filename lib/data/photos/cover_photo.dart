import '../../data/models/photo.dart';

Photo? coverPhotoOf(List<Photo> photos, String? coverId) {
  if (coverId != null) {
    for (final photo in photos) {
      if (photo.id == coverId) {
        return photo;
      }
    }
  }
  for (final photo in photos) {
    if (photo.isCover) {
      return photo;
    }
  }
  return photos.isEmpty ? null : photos.first;
}
