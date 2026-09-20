import 'dart:async';

import 'package:amici_per_la_coda/core/firestore_codec.dart';
import 'package:amici_per_la_coda/data/models/association_settings.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this._settings]);

  AssociationSettings? _settings;
  final _controller = StreamController<AssociationSettings?>.broadcast();

  AssociationSettings? get current => _settings;

  @override
  Future<AssociationSettings?> getAssociation() async => _settings;

  @override
  Stream<AssociationSettings?> watchAssociation() async* {
    yield _settings;
    yield* _controller.stream;
  }

  @override
  Future<void> saveAssociation(AssociationSettings settings) async {
    _settings = settings;
    _controller.add(_settings);
  }
}

AssociationSettings testAssociationSettings({
  int capienzaAutorizzata = 54,
}) {
  return AssociationSettings(
    denominazione: 'Amici per la Coda ODV',
    codiceFiscale: '93081210721',
    sede: 'Corleto Perticara (PZ)',
    capienzaAutorizzata: capienzaAutorizzata,
    logoB64: null,
    telefono: '333 000 0000',
    email: 'info@amiciperlacoda.it',
    audit: Audit.seed(DateTime.utc(2024, 6, 25), by: 'test'),
  );
}
