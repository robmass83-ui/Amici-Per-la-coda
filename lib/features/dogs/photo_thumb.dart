import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/models/photo.dart';
import '../../ui/tokens.dart';
import 'dog_labels.dart';

class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.nome,
    this.photo,
    this.width,
    this.height,
    this.radius,
    this.imageKey,
  });

  final String nome;
  final Photo? photo;
  final double? width;
  final double? height;
  final double? radius;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final w = width ?? AppDim.listAvatar;
    final h = height ?? AppDim.listAvatar;
    final r = radius ?? AppDim.gapM;
    Widget child;
    final b64 = photo?.thumbB64 ?? '';
    if (b64.isNotEmpty) {
      try {
        child = ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: Image.memory(
            base64Decode(b64),
            key: imageKey,
            width: w,
            height: h,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      } catch (_) {
        child = _Initial(nome: nome, large: h >= AppDim.photoH);
      }
    } else {
      child = _Initial(nome: nome, large: h >= AppDim.photoH);
    }
    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.greenSoft,
          borderRadius: BorderRadius.circular(r),
        ),
        child: child,
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.nome, required this.large});

  final String nome;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cleaned = dogDisplayName(nome);
    final initial = cleaned.isEmpty
        ? '?'
        : cleaned.substring(0, 1).toUpperCase();
    return Center(
      child: Text(
        initial,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: large ? AppText.display : AppText.title,
          fontWeight: FontWeight.w700,
          color: AppColor.greenDark,
          height: AppDim.lineH,
        ),
      ),
    );
  }
}
