import '../../core/firestore_codec.dart';
import 'enums.dart';

class Vendor {
  const Vendor({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.telefono,
    required this.email,
    required this.indirizzo,
    required this.convenzionato,
    required this.note,
    required this.audit,
  });

  final String id;
  final String nome;
  final VendorTipo tipo;
  final String telefono;
  final String email;
  final String indirizzo;
  final bool convenzionato;
  final String note;
  final Audit audit;

  factory Vendor.fromMap(String id, Map<String, dynamic> map) {
    return Vendor(
      id: id,
      nome: map['nome'] as String? ?? '',
      tipo: VendorTipo.parse(map['tipo'] as String?),
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      indirizzo: map['indirizzo'] as String? ?? '',
      convenzionato: map['convenzionato'] as bool? ?? false,
      note: map['note'] as String? ?? '',
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo.wire,
      'telefono': telefono,
      'email': email,
      'indirizzo': indirizzo,
      'convenzionato': convenzionato,
      'note': note,
      ...audit.toMap(),
    };
  }
}
