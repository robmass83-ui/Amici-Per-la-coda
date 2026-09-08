import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

/// Campo compatto: label opzionale sopra, altezza [fieldHeight] (40 di default).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.textInputAction,
    this.inputFormatters,
    this.suffix,
    this.fieldHeight = AppDim.minTouch,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final double fieldHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.label,
              color: AppColor.muted,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapXs),
        ],
        SizedBox(
          height: fieldHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            maxLines: maxLines,
            minLines: maxLines == 1 ? null : maxLines,
            textAlignVertical: maxLines == 1 ? null : TextAlignVertical.top,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.body,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              isCollapsed: true,
              contentPadding: AppDim.inputPad,
              errorText: null,
              suffixIcon: suffix == null
                  ? null
                  : SizedBox(
                      width: AppDim.headerBtn,
                      height: fieldHeight,
                      child: Center(child: suffix),
                    ),
              suffixIconConstraints: BoxConstraints(
                minWidth: AppDim.headerBtn,
                minHeight: fieldHeight,
                maxWidth: AppDim.headerBtn,
                maxHeight: fieldHeight,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppDim.gapXs),
          Text(
            errorText!,
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
}
