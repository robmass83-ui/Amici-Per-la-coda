import 'package:flutter/services.dart';

const templatePreaffidoId = 'preaffido';
const templateAdozioneId = 'adozione';

const templatePreaffidoAsset = 'assets/moduli/modulo-preaffido.pdf';
const templateAdozioneAsset = 'assets/moduli/modulo-adozione.pdf';

const templatePreaffidoNome = 'Modulo di preaffido';
const templateAdozioneNome = 'Modulo di adozione';

abstract interface class AssetBytesLoader {
  Future<Uint8List> load(String assetPath);
}

class RootBundleAssetLoader implements AssetBytesLoader {
  const RootBundleAssetLoader();

  @override
  Future<Uint8List> load(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}

class DefaultTemplateSpec {
  const DefaultTemplateSpec({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.fileName,
    required this.assetPath,
  });

  final String id;
  final String nome;
  final String descrizione;
  final String fileName;
  final String assetPath;
}

const defaultTemplates = [
  DefaultTemplateSpec(
    id: templatePreaffidoId,
    nome: templatePreaffidoNome,
    descrizione: 'Modulo in bianco da compilare e firmare fuori dall\'app.',
    fileName: 'modulo-preaffido.pdf',
    assetPath: templatePreaffidoAsset,
  ),
  DefaultTemplateSpec(
    id: templateAdozioneId,
    nome: templateAdozioneNome,
    descrizione: 'Modulo in bianco da compilare e firmare fuori dall\'app.',
    fileName: 'modulo-adozione.pdf',
    assetPath: templateAdozioneAsset,
  ),
];
