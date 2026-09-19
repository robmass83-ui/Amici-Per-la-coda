import 'package:flutter/material.dart';

import '../core/format_it.dart';
import '../features/vendors/vendor_logic.dart';
import 'components.dart';
import 'tokens.dart';

const formDateSuffixKey = Key('form-date-suffix');

Future<void> pickAppDate(
  BuildContext context,
  TextEditingController controller, {
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? initialDate,
}) async {
  final now = DateTime.now();
  final parsed = parseItalianDate(controller.text);
  final first = firstDate ?? DateTime(now.year - 25);
  final last = lastDate ?? DateTime(now.year + 10, 12, 31);
  var initial = initialDate ?? parsed ?? now;
  if (initial.isBefore(first)) {
    initial = first;
  }
  if (initial.isAfter(last)) {
    initial = last;
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked == null) {
    return;
  }
  controller.text = formatItalianDate(picked);
}

Future<void> pickAppTime(
  BuildContext context,
  TextEditingController controller,
) async {
  final parts = controller.text.trim().split(':');
  var hour = TimeOfDay.now().hour;
  var minute = TimeOfDay.now().minute;
  if (parts.length >= 2) {
    hour = int.tryParse(parts[0]) ?? hour;
    minute = int.tryParse(parts[1]) ?? minute;
  }
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: hour, minute: minute),
  );
  if (picked == null) {
    return;
  }
  final at = DateTime(2000, 1, 1, picked.hour, picked.minute);
  controller.text = formatItalianTime(at);
}

Widget dateFieldSuffix({Key? key, VoidCallback? onTap}) {
  final boxed = SizedBox(
    key: key ?? formDateSuffixKey,
    width: AppDim.minTouch,
    height: AppDim.minTouch,
    child: const Center(
      child: IconBadge(AppIcons.data, size: IconBadge.inNotice),
    ),
  );
  if (onTap == null) {
    return boxed;
  }
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: boxed,
  );
}

Future<void> pickDogFormDate(
  BuildContext context,
  TextEditingController controller,
  VoidCallback? onChanged, {
  bool allowFuture = false,
}) async {
  final parsed = parseItalianDate(controller.text);
  final now = DateTime.now();
  final first = DateTime(now.year - 25);
  final last = allowFuture ? DateTime(now.year + 10, 12, 31) : now;
  var initial = parsed ?? DateTime(now.year - 2, now.month, now.day);
  if (initial.isBefore(first)) {
    initial = first;
  }
  if (initial.isAfter(last)) {
    initial = last;
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked == null) {
    return;
  }
  controller.text = formatItalianDate(picked);
  onChanged?.call();
}

Future<void> pickVendorName({
  required BuildContext context,
  required TextEditingController controller,
  required List<VendorEntry> vendors,
  required String title,
}) async {
  final chosen = await AppSheet.present<String>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: title,
        children: [
          OptionRow(
            icon: const IconBadge(AppIcons.fornitori, size: IconBadge.inMenu),
            title: '+ nuovo',
            subtitle: 'Testo libero',
            onTap: () => Navigator.of(context, rootNavigator: true).pop(''),
          ),
          for (final vendor in vendors)
            OptionRow(
              icon: const IconBadge(AppIcons.fornitori, size: IconBadge.inMenu),
              title: vendor.nome,
              subtitle: vendor.origine,
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).pop(vendor.nome),
            ),
        ],
      );
    },
  );
  if (chosen == null) {
    return;
  }
  if (chosen.isEmpty) {
    return;
  }
  controller.text = chosen;
}

