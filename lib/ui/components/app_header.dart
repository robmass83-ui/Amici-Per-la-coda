import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_logo.dart';

/// Header compatto: logo o titolo al centro, pulsanti rotondi 34 dp.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title,
    this.showLogo = false,
    this.onBack,
    this.onEdit,
    this.onShare,
    this.onMore,
    this.actions,
  });

  final String? title;
  final bool showLogo;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColor.card,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColor.line2, width: AppDim.lineH),
          ),
        ),
        child: SizedBox(
          height: showLogo ? AppDim.logoBarH : AppDim.appBarH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDim.gapL),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDim.headerBtn + AppDim.gapS,
                    ),
                    child: _Title(title: title, showLogo: showLogo),
                  ),
                ),
                Row(
                  children: [
                    if (onBack != null)
                      _RoundHeaderButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Indietro',
                        onTap: onBack,
                      )
                    else
                      const SizedBox(width: AppDim.headerBtn),
                    const Spacer(),
                    ...?actions,
                    if (onEdit != null)
                      _RoundHeaderButton(
                        icon: Icons.edit_rounded,
                        tooltip: 'Modifica',
                        onTap: onEdit,
                      ),
                    if (onShare != null) ...[
                      const SizedBox(width: AppDim.gapXs),
                      _RoundHeaderButton(
                        icon: Icons.ios_share_rounded,
                        tooltip: 'Condividi',
                        onTap: onShare,
                      ),
                    ],
                    if (onMore != null) ...[
                      const SizedBox(width: AppDim.gapXs),
                      _RoundHeaderButton(
                        icon: Icons.more_vert_rounded,
                        tooltip: 'Altre azioni',
                        onTap: onMore,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title, required this.showLogo});

  final String? title;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    if (showLogo) {
      return const Center(child: AppLogo());
    }

    return Text(
      title ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.title,
        fontWeight: FontWeight.w700,
        color: AppColor.ink,
        height: AppDim.lineH,
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColor.neutralSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: AppDim.headerBtn,
            height: AppDim.headerBtn,
            child: Icon(icon, size: AppDim.iconNav, color: AppColor.ink),
          ),
        ),
      ),
    );
  }
}
