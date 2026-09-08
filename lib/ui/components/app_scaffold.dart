import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_header.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppHeader(
              title: title,
              showLogo: showLogo,
              onBack: onBack,
              onEdit: onEdit,
              onShare: onShare,
              onMore: onMore,
              actions: headerActions,
            ),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
