import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../ui/components.dart';
import '../calendar/add_appointment_sheet.dart';
import '../dogs/add_expense_sheet.dart';
import '../dogs/add_treatment_sheet.dart';
import '../dogs/pick_dog_sheet.dart';

abstract final class NewItemSheetKeys {
  static const nuovoCane = Key('fab-nuovo-cane');
  static const richiesta = Key('fab-richiesta');
  static const trattamento = Key('fab-trattamento');
  static const spesa = Key('fab-spesa');
  static const appuntamento = Key('fab-appuntamento');
  static const foto = Key('fab-foto');
}

Future<void> showNewItemSheet(BuildContext hostContext) {
  return AppSheet.show(
    context: hostContext,
    title: 'Cosa vuoi creare?',
    children: [
      OptionRow(
        key: NewItemSheetKeys.nuovoCane,
        icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
        title: 'Nuovo cane',
        subtitle: 'Profilo completo in 3 passaggi',
        onTap: () {
          _afterClose(hostContext, () async {
            await hostContext.push(AppRoutes.nuovo);
          });
        },
      ),
      OptionRow(
        key: NewItemSheetKeys.richiesta,
        icon: const IconBadge(AppIcons.adottabile, size: IconBadge.inMenu),
        title: 'Richiesta di adozione',
        subtitle: 'Registra un potenziale adottante',
        onTap: () {
          _afterClose(hostContext, () async {
            await hostContext.push(AppRoutes.nuovaRichiesta);
          });
        },
      ),
      OptionRow(
        key: NewItemSheetKeys.trattamento,
        icon: const IconBadge(AppIcons.vaccino, size: IconBadge.inMenu),
        title: 'Trattamento sanitario',
        subtitle: 'Vaccino, farmaco, visita',
        onTap: () {
          _afterClose(hostContext, () async {
            final pick = await PickDogSheet.show(hostContext);
            final dogId = pick?.dogId;
            if (dogId == null || !hostContext.mounted) {
              return;
            }
            await AddTreatmentSheet.open(hostContext, dogId: dogId);
          });
        },
      ),
      OptionRow(
        key: NewItemSheetKeys.spesa,
        icon: const IconBadge(AppIcons.spese, size: IconBadge.inMenu),
        title: 'Spesa',
        subtitle: 'Veterinario, cibo, farmaci',
        onTap: () {
          _afterClose(hostContext, () async {
            final pick = await PickDogSheet.show(
              hostContext,
              showGeneralExpense: true,
            );
            if (pick == null || !hostContext.mounted) {
              return;
            }
            await AddExpenseSheet.open(hostContext, dogId: pick.dogId);
          });
        },
      ),
      OptionRow(
        key: NewItemSheetKeys.appuntamento,
        icon: const IconBadge(AppIcons.data, size: IconBadge.inMenu),
        title: 'Appuntamento',
        subtitle: 'Visita, colloquio, scadenza',
        onTap: () {
          _afterClose(hostContext, () {
            return AddAppointmentSheet.open(hostContext);
          });
        },
      ),
      OptionRow(
        key: NewItemSheetKeys.foto,
        icon: const IconBadge(AppIcons.fotocamera, size: IconBadge.inMenu),
        title: 'Foto rapida',
        subtitle: 'Scatta e assegna a un cane',
        onTap: () {
          _afterClose(hostContext, () async {
            final pick = await PickDogSheet.show(hostContext);
            final dogId = pick?.dogId;
            if (dogId == null || !hostContext.mounted) {
              return;
            }
            await hostContext.push(AppRoutes.dogFoto(dogId, aggiungi: true));
          });
        },
      ),
    ],
  );
}

void _afterClose(BuildContext hostContext, Future<void> Function() next) {
  Navigator.of(hostContext).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (hostContext.mounted) {
      await next();
    }
  });
}
