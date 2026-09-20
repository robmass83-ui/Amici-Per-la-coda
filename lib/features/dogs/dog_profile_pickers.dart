import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/shelter_box.dart';
import '../../data/models/volunteer.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../volunteers/volunteer_labels.dart';
import 'dog_labels.dart';

Future<ModalitaIngresso?> pickModalitaIngresso(BuildContext context) {
  return AppSheet.present<ModalitaIngresso>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: 'Modalità di ingresso',
        children: [
          for (final value in ModalitaIngresso.values)
            OptionRow(
              icon: const IconBadge(AppIcons.provenienza, size: IconBadge.inMenu),
              title: modalitaIngressoLabel(value),
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      );
    },
  );
}

Future<({String settore, String box})?> pickBoxAssegnato(
  BuildContext context,
  List<ShelterBox> boxes,
) {
  final available = boxes.where((item) => !item.inManutenzione).toList();
  return AppSheet.present<({String settore, String box})>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: 'Box assegnato',
        children: [
          OptionRow(
            icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
            title: 'Nessun box',
            onTap: () => Navigator.of(context).pop((settore: '', box: '')),
          ),
          for (final box in available)
            OptionRow(
              key: Key('pick-box-${box.id}'),
              icon: const IconBadge(AppIcons.box, size: IconBadge.inMenu),
              title: boxAssegnatoLabel(box.settore, box.numero),
              subtitle: 'Capienza ${box.capienza}',
              onTap: () => Navigator.of(context).pop(
                (settore: box.settore, box: box.numero),
              ),
            ),
        ],
      );
    },
  );
}

Future<String?> pickReferente(
  BuildContext context,
  List<Volunteer> volunteers,
) {
  final attivi = volunteers.where((item) => item.attivo).toList();
  return AppSheet.present<String?>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: 'Volontario referente',
        children: [
          OptionRow(
            icon: const IconBadge(AppIcons.volontari, size: IconBadge.inMenu),
            title: 'Nessun referente',
            onTap: () => Navigator.of(context).pop(''),
          ),
          for (final volunteer in attivi)
            OptionRow(
              icon: const IconBadge(AppIcons.volontari, size: IconBadge.inMenu),
              title: volunteerDisplayName(volunteer),
              subtitle: volunteer.email,
              onTap: () => Navigator.of(context).pop(volunteer.id),
            ),
        ],
      );
    },
  );
}

Future<String?> pickCustomTrait(BuildContext context) async {
  final controller = TextEditingController();
  final added = await AppSheet.present<String>(
    context: context,
    builder: (context) {
      return Padding(
        padding: AppDim.pagePad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Altro tratto',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.h2,
                fontWeight: FontWeight.w700,
                color: AppColor.ink,
                height: AppDim.lineH,
              ),
            ),
            const SizedBox(height: AppDim.gapM),
            AppTextField(
              label: 'Carattere',
              hint: 'Es. giocherellona',
              controller: controller,
            ),
            const SizedBox(height: AppDim.gapM),
            AppButton(
              label: 'Aggiungi',
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            ),
          ],
        ),
      );
    },
  );
  controller.dispose();
  if (added == null || added.isEmpty) {
    return null;
  }
  return added;
}
