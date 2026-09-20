import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/data_repositories.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

Future<void> touchDogAudit({
  required DogRepository? dogs,
  required String dogId,
  required String uid,
  DateTime? now,
}) async {
  if (dogs == null) {
    return;
  }
  final dog = await dogs.getById(dogId);
  if (dog == null) {
    return;
  }
  await dogs.save(
    dog.copyWith(audit: dog.audit.touched(uid, now ?? DateTime.now())),
  );
}

// ── CONTRATTO DI LAYOUT · Conferma azione ──────────────────────────────────
// AppSheet
// ├ titolo 13sp w700
// ├ Text messaggio 12sp  maxLines=6
// ├ SizedBox 12
// └ Row gap=9  Annulla grey | Conferma  h=40
// ───────────────────────────────────────────────────────────────────────────

class ConfirmActionKeys {
  static const cancel = Key('confirm-action-cancel');
  static const confirm = Key('confirm-action-ok');
  static const ricarica = Key('edit-dog-ricarica');
  static const overwrite = Key('edit-dog-overwrite');
  static const discardStay = Key('edit-dog-discard-stay');
  static const discardLeave = Key('edit-dog-discard-leave');
}

Future<bool> confirmAction({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Elimina',
  Key? confirmKey,
  Key? cancelKey,
}) async {
  final result = await AppSheet.present<bool>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: title,
        children: [
          Text(
            message,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.body,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: cancelKey ?? ConfirmActionKeys.cancel,
                  label: 'Annulla',
                  variant: AppButtonVariant.grey,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(false),
                ),
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: AppButton(
                  key: confirmKey ?? ConfirmActionKeys.confirm,
                  label: confirmLabel,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(true),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<bool> confirmDeleteNamed(BuildContext context, String namedThing) {
  return confirmAction(
    context: context,
    title: 'Conferma eliminazione',
    message: 'Eliminare $namedThing?',
    confirmLabel: 'Elimina',
  );
}

enum ConcurrentEditChoice { ricarica, overwrite }

Future<ConcurrentEditChoice?> showConcurrentEditSheet({
  required BuildContext context,
  required String message,
}) {
  return AppSheet.present<ConcurrentEditChoice>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: 'Scheda modificata',
        children: [
          Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.body,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapL),
          AppButton(
            key: ConfirmActionKeys.ricarica,
            label: 'Ricarica',
            variant: AppButtonVariant.grey,
            onPressed: () => Navigator.of(
              context,
              rootNavigator: true,
            ).pop(ConcurrentEditChoice.ricarica),
          ),
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: ConfirmActionKeys.overwrite,
            label: 'Sovrascrivi comunque',
            onPressed: () => Navigator.of(
              context,
              rootNavigator: true,
            ).pop(ConcurrentEditChoice.overwrite),
          ),
        ],
      );
    },
  );
}

Key recordMenuKey(String id) => Key('record-menu-$id');

/// ⋮ 40×40. Se [canEdit] è falso non si disegna.
class RecordMenuButton extends StatelessWidget {
  const RecordMenuButton({
    super.key,
    required this.id,
    required this.canEdit,
    required this.onEdit,
    this.onDelete,
    this.deleteLabel = 'Elimina',
    this.editLabel = 'Modifica',
  });

  final String id;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final String deleteLabel;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    if (!canEdit) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      key: recordMenuKey(id),
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(unawaitedOpen(context)),
      child: const SizedBox(
        width: AppDim.minTouch,
        height: AppDim.minTouch,
        child: Center(child: IconBadge(AppIcons.menu, size: IconBadge.inTitle)),
      ),
    );
  }

  Future<void> unawaitedOpen(BuildContext context) {
    return openRecordActions(
      context,
      onEdit: onEdit,
      onDelete: onDelete,
      deleteLabel: deleteLabel,
      editLabel: editLabel,
    );
  }
}

Future<void> openRecordActions(
  BuildContext context, {
  required VoidCallback onEdit,
  VoidCallback? onDelete,
  String editLabel = 'Modifica',
  String deleteLabel = 'Elimina',
}) {
  return AppSheet.show<void>(
    context: context,
    title: 'Azioni',
    children: [
      OptionRow(
        key: const Key('record-action-edit'),
        icon: const IconBadge(AppIcons.modifica, size: IconBadge.inMenu),
        title: editLabel,
        onTap: () {
          Navigator.of(context, rootNavigator: true).pop();
          onEdit();
        },
      ),
      if (onDelete != null)
        OptionRow(
          key: const Key('record-action-delete'),
          icon: const IconBadge(AppIcons.elimina, size: IconBadge.inMenu),
          title: deleteLabel,
          titleColor: AppColor.red,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            onDelete();
          },
        ),
    ],
  );
}
