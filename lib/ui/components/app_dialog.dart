import 'package:flutter/material.dart';

import '../icons.dart';
import '../tokens.dart';
import 'app_button.dart';
import 'app_sheet.dart';
import 'icon_badge.dart';

// ── CONTRATTO DI LAYOUT · AppDialog ───────────────────────────────────────
// Overlay centrato  barrier 45%
// AnimatedPadding  bottom = viewInsets.bottom
// Card  larghezza = schermo − 24  maxHeight = 82% sopra la tastiera
//   fondo bianco  radius 14  bordo line  ombra morbida
// ├ Header  h=42  FISSO
// │    IconBadge 20 · titolo 13sp w700 maxLines=1  · × 26  fondo neutralSoft
// ├ Body  SingleChildScrollView  padding 12  gap 8 fra i campi
// │    focus → Scrollable.ensureVisible
// └ Footer  h=46  FISSO  bordo superiore line2  padding 7/12
//     [🗑 32  solo modifica]  [Annulla ghost 50%]  [Salva primario 50%]
//     Salva disabilitato: fondo greenDisabled
// ───────────────────────────────────────────────────────────────────────────

class AppDialog extends StatefulWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.canSave,
    required this.isDirty,
    required this.onSave,
    this.onDelete,
    this.deleteLabel,
    this.saveLabel = 'Salva',
    this.saving = false,
    this.saveKey,
    this.deleteKey,
    this.cancelKey,
    this.closeKey,
  });

  final AppIconSpec icon;
  final String title;
  final Widget body;
  final bool canSave;
  final bool isDirty;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;
  final String? deleteLabel;
  final String saveLabel;
  final bool saving;
  final Key? saveKey;
  final Key? deleteKey;
  final Key? cancelKey;
  final Key? closeKey;

  static const cardKey = Key('app-dialog-card');
  static const footerKey = Key('app-dialog-footer');
  static const defaultCloseKey = Key('app-dialog-close');
  static const defaultCancelKey = Key('app-dialog-cancel');
  static const defaultTrashKey = Key('app-dialog-trash');

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget form,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Chiudi',
      barrierColor: AppColor.ink.withValues(alpha: AppDim.dialogBarrier),
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => form,
    );
  }

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  FocusNode? _lastFocus;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_ensureFocusedVisible);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_ensureFocusedVisible);
    super.dispose();
  }

  void _ensureFocusedVisible() {
    final focus = FocusManager.instance.primaryFocus;
    if (identical(focus, _lastFocus)) {
      return;
    }
    _lastFocus = focus;
    final ctx = focus?.context;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    if (Scrollable.maybeOf(ctx) == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: Duration.zero,
      );
    });
  }

  Future<void> _requestClose() async {
    if (widget.isDirty) {
      final ok = await _confirmDiscard(context);
      if (!ok) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _requestDelete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }
    await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final showTrash = widget.onDelete != null && widget.deleteLabel == null;
    final showAltDelete = widget.onDelete != null && widget.deleteLabel != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _requestClose();
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: AppDim.dialogAnimMs),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboard),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight * AppDim.dialogMaxHFrac;
            final width = constraints.maxWidth - AppDim.dialogInset * 2;
            final bodyMax = (maxH -
                    AppDim.dialogHeaderH -
                    AppDim.dialogFooterH)
                .clamp(AppDim.formFieldH, maxH);
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _requestClose,
                    child: const SizedBox.expand(),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width,
                      maxHeight: maxH,
                    ),
                    child: Material(
                      key: AppDialog.cardKey,
                      color: AppColor.card,
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDim.dialogRad),
                        side: const BorderSide(color: AppColor.line),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDim.dialogRad,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColor.dialogShadow,
                              blurRadius: AppDim.dialogShadowBlur,
                              offset: Offset(0, AppDim.dialogShadowY),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DialogHeader(
                              icon: widget.icon,
                              title: widget.title,
                              closeKey:
                                  widget.closeKey ??
                                  AppDialog.defaultCloseKey,
                              onClose: _requestClose,
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: bodyMax),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(AppDim.gapL),
                                child: widget.body,
                              ),
                            ),
                            _DialogFooter(
                          key: AppDialog.footerKey,
                          canSave: widget.canSave && !widget.saving,
                          saving: widget.saving,
                          saveLabel: widget.saveLabel,
                          saveKey: widget.saveKey,
                          cancelKey:
                              widget.cancelKey ?? AppDialog.defaultCancelKey,
                          deleteKey:
                              widget.deleteKey ?? AppDialog.defaultTrashKey,
                          showTrash: showTrash,
                          altDeleteLabel: showAltDelete
                              ? widget.deleteLabel
                              : null,
                          onCancel: _requestClose,
                          onSave: widget.saving ? null : widget.onSave,
                          onDelete: widget.onDelete == null
                              ? null
                              : _requestDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.onClose,
    required this.closeKey,
  });

  final AppIconSpec icon;
  final String title;
  final VoidCallback onClose;
  final Key closeKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.dialogHeaderH,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDim.gapL,
          right: AppDim.gapS + AppDim.gapXs,
        ),
        child: Row(
          children: [
            IconBadge(icon, size: IconBadge.inTitle),
            const SizedBox(width: AppDim.dialogHeaderGap),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: AppText.h2,
                  fontWeight: FontWeight.w700,
                  color: AppColor.ink,
                  height: AppDim.lineH,
                ),
              ),
            ),
            const SizedBox(width: AppDim.gapS),
            SizedBox(
              width: AppDim.dialogClose,
              height: AppDim.dialogClose,
              child: Material(
                color: AppColor.neutralSoft,
                shape: const CircleBorder(),
                child: InkWell(
                  key: closeKey,
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: const Center(
                    child: Text(
                      '×',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w700,
                        color: AppColor.muted,
                        height: AppDim.formLabelLineH,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    super.key,
    required this.canSave,
    required this.saving,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    required this.showTrash,
    this.onDelete,
    this.altDeleteLabel,
    this.saveKey,
    required this.cancelKey,
    required this.deleteKey,
  });

  final bool canSave;
  final bool saving;
  final String saveLabel;
  final VoidCallback onCancel;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onDelete;
  final bool showTrash;
  final String? altDeleteLabel;
  final Key? saveKey;
  final Key cancelKey;
  final Key deleteKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDim.dialogFooterH,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.line2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDim.gapL,
            vertical: AppDim.dialogFooterPadV,
          ),
          child: Row(
            children: [
              if (showTrash) ...[
                _TrashButton(key: deleteKey, onTap: onDelete),
                const SizedBox(width: AppDim.formRowGap),
              ],
              if (altDeleteLabel != null) ...[
                _FooterButton(
                  key: deleteKey,
                  label: altDeleteLabel!,
                  variant: _FooterVariant.danger,
                  expand: false,
                  onTap: onDelete,
                ),
                const SizedBox(width: AppDim.formRowGap),
              ],
              Expanded(
                child: _FooterButton(
                  key: cancelKey,
                  label: 'Annulla',
                  variant: _FooterVariant.ghost,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: AppDim.formRowGap),
              Expanded(
                child: _FooterButton(
                  key: saveKey,
                  label: saveLabel,
                  variant: _FooterVariant.primary,
                  enabled: canSave,
                  saving: saving,
                  onTap: canSave ? () => onSave?.call() : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FooterVariant { primary, ghost, danger }

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    super.key,
    required this.label,
    required this.variant,
    required this.onTap,
    this.enabled = true,
    this.saving = false,
    this.expand = true,
  });

  final String label;
  final _FooterVariant variant;
  final VoidCallback? onTap;
  final bool enabled;
  final bool saving;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final bg = switch (variant) {
      _FooterVariant.primary =>
        active ? AppColor.green : AppColor.greenDisabled,
      _FooterVariant.ghost => AppColor.card,
      _FooterVariant.danger => AppColor.card,
    };
    final fg = switch (variant) {
      _FooterVariant.primary => AppColor.card,
      _FooterVariant.ghost => AppColor.ink2,
      _FooterVariant.danger => AppColor.red,
    };
    final border = switch (variant) {
      _FooterVariant.primary =>
        active ? AppColor.green : AppColor.greenDisabled,
      _FooterVariant.ghost => AppColor.line,
      _FooterVariant.danger => AppColor.trashBorder,
    };
    final button = SizedBox(
      height: AppDim.dialogFooterBtnH,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.formRad),
          side: BorderSide(color: border, width: AppDim.dialogStroke),
        ),
        child: InkWell(
          onTap: active ? onTap : null,
          borderRadius: BorderRadius.circular(AppDim.formRad),
          child: Center(
            child: saving
                ? const SizedBox(
                    width: AppDim.dialogSpinner,
                    height: AppDim.dialogSpinner,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDim.gapHair * 2,
                      color: AppColor.card,
                    ),
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      height: AppDim.lineH,
                    ),
                  ),
          ),
        ),
      ),
    );
    if (expand) {
      return button;
    }
    return button;
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDim.dialogTrash,
      height: AppDim.dialogTrash,
      child: Material(
        color: AppColor.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.formRad),
          side: const BorderSide(
            color: AppColor.trashBorder,
            width: AppDim.dialogStroke,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDim.formRad),
          child: const Center(
            child: IconBadge(AppIcons.elimina, size: IconBadge.inNotice),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDiscard(BuildContext context) async {
  final result = await AppSheet.present<bool>(
    context: context,
    builder: (context) {
      return AppSheet(
        title: 'Modifiche non salvate',
        children: [
          const Text(
            'Scartare le modifiche?',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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
                  label: 'Annulla',
                  variant: AppButtonVariant.grey,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(false),
                ),
              ),
              const SizedBox(width: AppDim.gapM),
              Expanded(
                child: AppButton(
                  label: 'Scarta',
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

/// Riga di campi con gap 8, da usare nel body di [AppDialog].
class DialogBodyGap extends StatelessWidget {
  const DialogBodyGap({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: AppDim.formRowGap);
}
