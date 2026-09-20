import 'package:flutter/material.dart';

import '../tokens.dart';

// ── CONTRATTO DI LAYOUT · FormRow2 ─────────────────────────────────────────
// Row  crossAxisAlignment=start  gap 8
// ├ Expanded(flex)  child
// └ Expanded(flex)  child
// ───────────────────────────────────────────────────────────────────────────

class FormRow2 extends StatelessWidget {
  const FormRow2({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: AppDim.formRowGap),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}
