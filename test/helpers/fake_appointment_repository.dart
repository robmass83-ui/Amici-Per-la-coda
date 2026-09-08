import 'dart:async';

import 'package:amici_per_la_coda/data/models/appointment.dart';
import 'package:amici_per_la_coda/data/repositories/data_repositories.dart';

class InMemoryAppointmentRepository implements AppointmentRepository {
  InMemoryAppointmentRepository([List<Appointment> items = const []])
    : _items = List.of(items);

  final List<Appointment> _items;
  final _controller = StreamController<List<Appointment>>.broadcast();

  @override
  Stream<List<Appointment>> watchAll() async* {
    yield List<Appointment>.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<void> save(Appointment appointment) async {
    _items.removeWhere((item) => item.id == appointment.id);
    _items.add(appointment);
    _controller.add(List<Appointment>.unmodifiable(_items));
  }
}
