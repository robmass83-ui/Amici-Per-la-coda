import '../../core/firestore_codec.dart';
import 'enums.dart';

class Expense {
  const Expense({
    required this.id,
    required this.dogId,
    required this.categoria,
    required this.importo,
    required this.data,
    required this.descrizione,
    required this.fornitore,
    required this.audit,
  });

  final String id;
  final String? dogId;
  final ExpenseCategoria categoria;
  final double importo;
  final DateTime data;
  final String descrizione;
  final String fornitore;
  final Audit audit;

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      dogId: map['dogId'] as String?,
      categoria: ExpenseCategoria.parse(map['categoria'] as String?),
      importo: numberFrom(map['importo']) ?? 0,
      data: dateTimeRequired(map['data']),
      descrizione: map['descrizione'] as String? ?? '',
      fornitore: map['fornitore'] as String? ?? '',
      audit: Audit.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'categoria': categoria.wire,
      'importo': importo,
      'data': dateTimeTo(data),
      'descrizione': descrizione,
      'fornitore': fornitore,
      ...audit.toMap(),
    };
  }

  Expense copyWith({
    ExpenseCategoria? categoria,
    double? importo,
    DateTime? data,
    String? descrizione,
    String? fornitore,
    Audit? audit,
  }) {
    return Expense(
      id: id,
      dogId: dogId,
      categoria: categoria ?? this.categoria,
      importo: importo ?? this.importo,
      data: data ?? this.data,
      descrizione: descrizione ?? this.descrizione,
      fornitore: fornitore ?? this.fornitore,
      audit: audit ?? this.audit,
    );
  }
}
