import 'package:flutter/material.dart';

import '../../ui/components.dart';

/// Calendario reale allo Step 15.
class CalendarPlaceholderPage extends StatelessWidget {
  const CalendarPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: IconBadge(AppIcons.data),
        message: 'Il calendario arriva negli step successivi.',
      ),
    );
  }
}
