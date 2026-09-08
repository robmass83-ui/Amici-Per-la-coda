import 'package:amici_per_la_coda/features/dogs/new_dog/microchip_scanner.dart';
import 'package:flutter/material.dart';

class FakeMicrochipScanner implements MicrochipScanner {
  FakeMicrochipScanner({this.code = '380260170123456'});

  String? code;

  @override
  Future<String?> scan(BuildContext context) async => code;
}
