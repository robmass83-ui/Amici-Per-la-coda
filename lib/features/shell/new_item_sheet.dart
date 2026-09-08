import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../ui/components.dart';

Future<void> showNewItemSheet(BuildContext hostContext) {
  return AppSheet.show(
    context: hostContext,
    title: 'Cosa vuoi creare?',
    children: [
      OptionRow(
        icon: const IconBadge(AppIcons.carattere, size: IconBadge.inMenu),
        title: 'Nuovo cane',
        subtitle: 'Profilo completo in 3 passaggi',
        onTap: () {
          Navigator.of(hostContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (hostContext.mounted) {
              hostContext.push(AppRoutes.nuovo);
            }
          });
        },
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.adottabile, size: IconBadge.inMenu),
        title: 'Richiesta di adozione',
        subtitle: 'Registra un potenziale adottante',
        onTap: () => _soon(hostContext, 'Richiesta di adozione'),
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.vaccino, size: IconBadge.inMenu),
        title: 'Trattamento sanitario',
        subtitle: 'Vaccino, farmaco, visita',
        onTap: () => _soon(hostContext, 'Trattamento sanitario'),
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.spese, size: IconBadge.inMenu),
        title: 'Spesa',
        subtitle: 'Veterinario, cibo, farmaci',
        onTap: () => _soon(hostContext, 'Spesa'),
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.data, size: IconBadge.inMenu),
        title: 'Appuntamento',
        subtitle: 'Visita, colloquio, turno',
        onTap: () => _soon(hostContext, 'Appuntamento'),
      ),
      OptionRow(
        icon: const IconBadge(AppIcons.fotocamera, size: IconBadge.inMenu),
        title: 'Foto rapida',
        subtitle: 'Scatta e assegna a un cane',
        onTap: () => _soon(hostContext, 'Foto rapida'),
      ),
    ],
  );
}

void _soon(BuildContext hostContext, String label) {
  Navigator.of(hostContext).pop();
  AppToast.show(hostContext, '$label: disponibile negli step successivi.');
}
