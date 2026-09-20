import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';

// ── CONTRATTO DI LAYOUT · Rinomina settore ─────────────────────────────────
// maniglia · titolo · campo settore h=34 · errore · Salva h=40
// ───────────────────────────────────────────────────────────────────────────

class RenameSettoreSheet extends ConsumerStatefulWidget {
  const RenameSettoreSheet({super.key, required this.da});

  static const nomeKey = Key('settore-nome');
  static const saveKey = Key('settore-save');

  final String da;

  static Future<void> open(BuildContext context, {required String da}) {
    return AppSheet.present<void>(
      context: context,
      builder: (context) => RenameSettoreSheet(da: da),
    );
  }

  @override
  ConsumerState<RenameSettoreSheet> createState() => _RenameSettoreSheetState();
}

class _RenameSettoreSheetState extends ConsumerState<RenameSettoreSheet> {
  late final TextEditingController _nome;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.da);
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = _nome.text.trim();
    if (a.isEmpty) {
      setState(() => _error = 'Inserisci il nome del settore.');
      return;
    }
    if (a == widget.da) {
      Navigator.of(context).pop();
      return;
    }
    final boxesRepo = ref.read(boxRepositoryProvider);
    final dogsRepo = ref.read(dogRepositoryProvider);
    if (boxesRepo == null || dogsRepo == null) {
      setState(() => _error = 'Archivio non disponibile.');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final now = DateTime.now();
    final boxes = await boxesRepo.watchAll().first;
    for (final box in boxes) {
      if (box.settore.trim() != widget.da) {
        continue;
      }
      await boxesRepo.save(
        box.copyWith(
          settore: a,
          audit: box.audit.touched(userId, now),
        ),
      );
    }
    final dogs = await dogsRepo.watchAll().first;
    for (final dog in dogs) {
      if (dog.settore.trim() != widget.da) {
        continue;
      }
      await dogsRepo.save(
        dog.copyWith(
          settore: a,
          audit: dog.audit.touched(userId, now),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppDim.pagePad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppDim.gapXl * 2,
              height: AppDim.gapXs,
              decoration: BoxDecoration(
                color: AppColor.line,
                borderRadius: BorderRadius.circular(AppDim.radChip),
              ),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          const Text(
            'Rinomina settore',
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
          AppFormField(
            key: RenameSettoreSheet.nomeKey,
            label: 'Settore',
            controller: _nome,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDim.gapS),
            Text(
              _error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppText.caption,
                color: AppColor.red,
                height: AppDim.lineH,
              ),
            ),
          ],
          const SizedBox(height: AppDim.gapM),
          AppButton(
            key: RenameSettoreSheet.saveKey,
            label: 'Salva',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
