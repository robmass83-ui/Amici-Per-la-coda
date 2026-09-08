import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amici_per_la_coda/data/models/photo.dart';
import 'package:amici_per_la_coda/data/photos/photo_codec.dart';
import 'package:amici_per_la_coda/data/photos/photo_limit.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

import 'fake_dog_repository.dart';

class InMemoryPhotoRepository implements PhotoRepository {
  InMemoryPhotoRepository({
    List<Photo> photos = const [],
    Map<String, Uint8List>? fulls,
    this.dogs,
  }) : _photos = List.of(photos),
       _fulls = Map.of(fulls ?? {});

  final List<Photo> _photos;
  final Map<String, Uint8List> _fulls;
  final InMemoryDogRepository? dogs;
  final _controller = StreamController<List<Photo>>.broadcast();
  int fullLoadCount = 0;

  void seed(Photo photo, Uint8List full) {
    _photos.removeWhere((item) => item.id == photo.id);
    _photos.add(photo);
    _fulls[photo.id] = full;
    _emit();
  }

  @override
  Stream<List<Photo>> watchByDog(String dogId) async* {
    yield _of(dogId);
    yield* _controller.stream.map((_) => _of(dogId));
  }

  List<Photo> _of(String dogId) {
    final list = _photos.where((item) => item.dogId == dogId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _emit() => _controller.add(List<Photo>.unmodifiable(_photos));

  @override
  Future<Photo> upload(
    String dogId,
    Uint8List bytes, {
    bool asCover = false,
    required String createdBy,
  }) async {
    final existing = _of(dogId);
    if (existing.length >= photoMaxPerDog) {
      throw const PhotoLimitReached();
    }
    final now = DateTime.now();
    final id = 'p_${now.microsecondsSinceEpoch}';
    final cover = asCover || existing.isEmpty;
    if (cover) {
      for (var i = 0; i < _photos.length; i++) {
        if (_photos[i].dogId == dogId) {
          _photos[i] = _photos[i].copyWith(isCover: false);
        }
      }
    }
    final photo = Photo(
      id: id,
      dogId: dogId,
      isCover: cover,
      w: 1,
      h: 1,
      mime: 'image/jpeg',
      thumbB64: base64Encode(bytes),
      bytesFull: bytes.lengthInBytes,
      createdAt: now,
      createdBy: createdBy,
    );
    _photos.add(photo);
    _fulls[id] = bytes;
    if (cover) {
      await _writeCover(dogId, id);
    }
    _emit();
    return photo;
  }

  @override
  Future<Uint8List?> loadFull(String photoId) async {
    fullLoadCount++;
    return _fulls[photoId];
  }

  @override
  Future<void> setCover(String dogId, String photoId) async {
    for (var i = 0; i < _photos.length; i++) {
      if (_photos[i].dogId == dogId) {
        _photos[i] = _photos[i].copyWith(isCover: _photos[i].id == photoId);
      }
    }
    await _writeCover(dogId, photoId);
    _emit();
  }

  Future<void> _writeCover(String dogId, String photoId) async {
    final dogsRepo = dogs;
    if (dogsRepo == null) {
      return;
    }
    final dog = await dogsRepo.getById(dogId);
    if (dog != null) {
      await dogsRepo.save(dog.withFotoCopertinaId(photoId));
    }
  }

  @override
  Future<void> delete(String photoId) async {
    Photo? removed;
    for (final photo in _photos) {
      if (photo.id == photoId) {
        removed = photo;
        break;
      }
    }
    _photos.removeWhere((item) => item.id == photoId);
    _fulls.remove(photoId);
    if (removed != null && removed.isCover) {
      final rest = _of(removed.dogId);
      if (rest.isEmpty) {
        final dog = await dogs?.getById(removed.dogId);
        if (dog != null) {
          await dogs?.save(dog.withFotoCopertinaId(null));
        }
      } else {
        await setCover(removed.dogId, rest.first.id);
        return;
      }
    }
    _emit();
  }
}
