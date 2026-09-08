import 'package:flutter/material.dart';

import '../tokens.dart';

/// Bottom nav a 4 voci + FAB centrale sporgente.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onFab,
  });

  /// 0 Home, 1 Animali, 2 Calendario, 3 Altro.
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: AppDim.bottomNavH + AppDim.gapXl + AppDim.gapS,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppDim.bottomNavH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColor.card,
                  border: Border(
                    top: BorderSide(color: AppColor.line, width: AppDim.lineH),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppDim.bottomNavH,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _NavItem(
                    icon: Icons.pets_rounded,
                    label: 'Animali',
                    selected: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  _NavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendario',
                    selected: currentIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _NavItem(
                    icon: Icons.menu_rounded,
                    label: 'Altro',
                    selected: currentIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: _FabButton(onTap: onFab),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColor.green : AppColor.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppDim.bottomNavH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppDim.iconNav, color: color),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: AppText.micro,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    height: AppDim.lineH,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Nuovo',
      child: Material(
        color: AppColor.green,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: AppDim.fabSize,
            height: AppDim.fabSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColor.bg, width: AppDim.gapXs),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: AppDim.iconBox,
              color: AppColor.card,
            ),
          ),
        ),
      ),
    );
  }
}
