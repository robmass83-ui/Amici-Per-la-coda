import 'package:flutter/material.dart';

import '../tokens.dart';

// ── CONTRATTO DI LAYOUT · Bottom sheet ─────────────────────────────────────
// Padding 12 + inset basso (tastiera o barra di sistema)
// Column  mainAxisSize=min
// ├ maniglia  32×4  centrata
// ├ SizedBox 9
// ├ titolo 13sp w700  maxLines=1
// ├ SizedBox 9
// └ children
// ───────────────────────────────────────────────────────────────────────────

/// Bottom sheet con maniglia, titolo e contenuto.
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  /// Spazio basso da lasciare libero: tastiera se aperta, altrimenti
  /// la barra di navigazione di sistema (gesture o tre pulsanti).
  ///
  /// Usa [FlutterView] e non [MediaQuery]: nel body dello Scaffold
  /// padding e viewPadding vengono azzerati, e il foglio modale
  /// arriva comunque fino al bordo fisico dello schermo.
  static double bottomInset(BuildContext context) {
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final keyboard = view.viewInsets.bottom / dpr;
    if (keyboard > 0) {
      return keyboard;
    }
    final padding = view.padding.bottom / dpr;
    final viewPadding = view.viewPadding.bottom / dpr;
    return padding > viewPadding ? padding : viewPadding;
  }

  /// Solleva un foglio sopra tastiera o barra di sistema.
  static Widget lift(Widget child) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset(context)),
          child: child,
        );
      },
    );
  }

  /// Apre un foglio modale a tutto schermo, sopra la barra di sistema.
  static Future<T?> present<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: AppColor.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDim.radSheet),
        ),
      ),
      builder: (sheetContext) => lift(builder(sheetContext)),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return present<T>(
      context: context,
      builder: (context) => AppSheet(title: title, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppDim.pagePad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDim.gapXl * 2,
            height: AppDim.gapXs,
            decoration: BoxDecoration(
              color: AppColor.line,
              borderRadius: BorderRadius.circular(AppDim.radChip),
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: AppText.h2,
              fontWeight: FontWeight.w700,
              color: AppColor.ink,
              height: AppDim.lineH,
            ),
          ),
          const SizedBox(height: AppDim.gapM),
          ...children,
        ],
      ),
    );
  }
}
