import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_button.dart';

/// Stato vuoto compatto: icona, frase e azione opzionale.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final Widget icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: compact ? EdgeInsets.zero : AppDim.pagePad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(height: compact ? AppDim.gapXs : AppDim.gapM),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: compact ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.body,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDim.gapM),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}
