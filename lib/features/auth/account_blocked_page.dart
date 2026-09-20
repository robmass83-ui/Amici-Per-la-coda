import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../auth/auth_providers.dart';

// ── CONTRATTO DI LAYOUT · Account bloccato ─────────────────────────────────
// Scaffold sfondo AppColor.bg  NESSUNA bottom nav  NESSUN FAB
// └ Center Column
//    ├ EmptyState  icona AppIcons.attenzione  messaggio 12sp  maxLines=3
//    ├ SizedBox 12
//    └ AppButton ghost "Esci"  larghezza contenuta
// ───────────────────────────────────────────────────────────────────────────

class AccountBlockedPage extends ConsumerWidget {
  const AccountBlockedPage({
    super.key,
    required this.message,
    this.messageKey,
  });

  final String message;
  final Key? messageKey;

  static const esciKey = Key('account-blocked-esci');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        child: Padding(
          padding: AppDim.pagePad,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyState(
                  key: messageKey,
                  icon: const IconBadge(AppIcons.attenzione),
                  message: message,
                ),
                const SizedBox(height: AppDim.gapL),
                AppButton(
                  key: esciKey,
                  label: 'Esci',
                  variant: AppButtonVariant.ghost,
                  expand: false,
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    onSignedOut(ref);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
