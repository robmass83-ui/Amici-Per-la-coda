import 'package:flutter/material.dart';

import '../tokens.dart';

class TimelineItem {
  const TimelineItem({
    required this.title,
    required this.subtitle,
    this.color = AppColor.green,
  });

  final String title;
  final String subtitle;
  final Color color;
}

/// Lista verticale con linea e pallini (storico, iter).
class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.items});

  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(item: items[i], isLast: i == items.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final TimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppDim.iconBox,
            child: Column(
              children: [
                Container(
                  width: AppDim.gapM,
                  height: AppDim.gapM,
                  decoration: BoxDecoration(
                    color: AppColor.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: item.color, width: AppDim.lineH),
                  ),
                ),
                if (!isLast)
                  const Expanded(
                    child: ColoredBox(
                      color: AppColor.line,
                      child: SizedBox(width: AppDim.lineH),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDim.gapS),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDim.gapM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w600,
                      color: AppColor.ink,
                      height: AppDim.lineH,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: AppText.caption,
                      color: AppColor.muted,
                      height: AppDim.lineH,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
