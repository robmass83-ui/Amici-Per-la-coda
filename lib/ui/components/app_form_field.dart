import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

// ── CONTRATTO DI LAYOUT · FormField (AppFormField) ─────────────────────────
// etichetta 10sp w600 maiuscoletto muted
// SizedBox 3
// campo h=34 (singola riga)  radius 9  testo 12sp
// multilinea: min h=34, cresce fino a maxLines
// ───────────────────────────────────────────────────────────────────────────

/// Scatola del valore (34 dp se riga singola). Usata dai test 14-ter.7.
class FormInputBox extends StatelessWidget {
  const FormInputBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Campo della grammatica form 14-ter.7. Si chiama AppFormField per non
/// collidere con `FormField` di Flutter.
class AppFormField extends StatefulWidget {
  const AppFormField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.suffix,
    this.child,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final int minLines;
  final Widget? suffix;
  final Widget? child;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onText);
  }

  @override
  void didUpdateWidget(AppFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onText);
      widget.controller?.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    if (widget.maxLines > 1) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: AppText.caption,
            fontWeight: FontWeight.w600,
            color: AppColor.muted,
            height: AppDim.formLabelLineH,
          ),
        ),
        const SizedBox(height: AppDim.formLabelGap),
        if (widget.child != null)
          widget.child!
        else if (widget.maxLines == 1)
          SizedBox(
            height: AppDim.formFieldH,
            child: FormInputBox(child: _input()),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: _multilineHeight(constraints.maxWidth),
                child: FormInputBox(child: _input()),
              );
            },
          ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppDim.gapXs),
          Text(
            widget.errorText!,
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
      ],
    );
  }

  double _multilineHeight(double width) {
    const style = TextStyle(
      fontFamily: 'Roboto',
      fontSize: AppText.body,
      height: AppDim.lineH,
    );
    final raw = widget.controller?.text ?? '';
    final painter = TextPainter(
      text: TextSpan(text: raw.isEmpty ? ' ' : raw, style: style),
      textDirection: TextDirection.ltr,
      maxLines: widget.maxLines,
    )..layout(
      maxWidth: (width - AppDim.formInputPad.horizontal).clamp(1, width),
    );
    final lines = painter.computeLineMetrics().length.clamp(
      widget.minLines,
      widget.maxLines,
    );
    final content =
        AppDim.formInputPad.vertical + AppText.body * AppDim.lineH * lines;
    return content < AppDim.formFieldH ? AppDim.formFieldH : content;
  }

  Widget _input() {
    final dropdown =
        widget.onTap != null &&
        widget.controller == null &&
        widget.suffix == null;
    final field = dropdown ? _tapValue() : _textField();
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(AppDim.formRad),
        border: Border.all(color: AppColor.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.enabled && widget.controller == null
              ? widget.onTap
              : null,
          borderRadius: BorderRadius.circular(AppDim.formRad),
          child: Padding(
            padding: AppDim.formInputPad,
            child: widget.maxLines == 1
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: field),
                      if (widget.suffix != null) ...[
                        const SizedBox(width: AppDim.gapXs),
                        widget.suffix!,
                      ] else if (dropdown)
                        const Text(
                          '▾',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: AppText.body,
                            color: AppColor.muted,
                            height: AppDim.lineH,
                          ),
                        ),
                    ],
                  )
                : field,
          ),
        ),
      ),
    ),
    );
  }

  Widget _tapValue() {
    return Text(
      widget.hint ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.body,
        color: AppColor.ink,
        height: AppDim.lineH,
      ),
    );
  }

  Widget _textField() {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      enableSuggestions: !widget.obscureText,
      autocorrect: !widget.obscureText,
      maxLines: widget.obscureText ? 1 : (widget.maxLines == 1 ? 1 : widget.maxLines),
      minLines: widget.obscureText ? 1 : widget.minLines,
      expands: false,
      inputFormatters: widget.inputFormatters,
      textAlignVertical: widget.maxLines == 1
          ? TextAlignVertical.center
          : TextAlignVertical.top,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.body,
        color: AppColor.ink,
        height: AppDim.lineH,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
