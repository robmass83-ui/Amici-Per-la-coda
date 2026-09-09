import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../ui/components.dart';

class PlaceholderFeaturePage extends StatelessWidget {
  const PlaceholderFeaturePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      body: Center(
        child: EmptyState(
          icon: const IconBadge(AppIcons.altro),
          message: '$title: disponibile negli step successivi.',
        ),
      ),
    );
  }
}
