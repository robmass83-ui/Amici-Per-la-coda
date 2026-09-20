import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_header.dart';

// ── CONTRATTO DI LAYOUT · AppScaffold ──────────────────────────────────────
// Scaffold  sfondo AppColor.bg
// Column
// ├ SafeArea  bottom=false  → AppHeader
// └ Expanded  body
//    se non c'è bottomNavigationBar: padding basso = barra di sistema
//    (View.padding / viewPadding). Con tastiera aperta l'inset è 0:
//    ci pensa resizeToAvoidBottomInset.
// ───────────────────────────────────────────────────────────────────────────

/// Scaffold con sfondo del design system e header opzionale.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.showLogo = false,
    this.onBack,
    this.onEdit,
    this.onShare,
    this.onMore,
    this.headerActions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.compactHeader = false,
  });

  final Widget body;
  final String? title;
  final bool showLogo;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final List<Widget>? headerActions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomNavigationBar == null
        ? systemNavInset(context)
        : 0.0;
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppHeader(
              title: title,
              showLogo: showLogo,
              compact: compactHeader,
              onBack: onBack,
              onEdit: onEdit,
              onShare: onShare,
              onMore: onMore,
              actions: headerActions,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  /// Spazio basso da lasciare libero per la barra di navigazione di sistema.
  ///
  /// Usa [FlutterView] e non [MediaQuery]: nel body dello Scaffold
  /// padding e viewPadding vengono azzerati. Con la tastiera aperta
  /// restituisce 0: lo Scaffold si ridimensiona da solo.
  static double systemNavInset(BuildContext context) {
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final keyboard = view.viewInsets.bottom / dpr;
    if (keyboard > 0) {
      return 0;
    }
    final padding = view.padding.bottom / dpr;
    final viewPadding = view.viewPadding.bottom / dpr;
    return padding > viewPadding ? padding : viewPadding;
  }
}
