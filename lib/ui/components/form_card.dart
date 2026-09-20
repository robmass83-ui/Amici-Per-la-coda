import 'package:flutter/material.dart';

import '../icons.dart';
import '../tokens.dart';
import 'app_card.dart';
import 'icon_badge.dart';

// ── CONTRATTO DI LAYOUT · FormCard ─────────────────────────────────────────
// AppCard padding=10
// ├ Row  IconBadge 20  SizedBox 6  titolo 12.5sp w700  maxLines=1
// ├ SizedBox 8
// └ children  gap 8
// ───────────────────────────────────────────────────────────────────────────

class FormCard extends StatelessWidget {
  const FormCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final AppIconSpec icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon, size: IconBadge.inTitle),
              const SizedBox(width: AppDim.gapS),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.formCard,
                    fontWeight: FontWeight.w700,
                    color: AppColor.ink,
                    height: AppDim.lineH,
                  ),
                ),
              ),
            ],
          ),
          for (final child in children) ...[
            const SizedBox(height: AppDim.formRowGap),
            child,
          ],
        ],
      ),
    );
  }
}
