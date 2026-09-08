import 'package:flutter/material.dart';

import '../tokens.dart';

enum AppLogoVariant { header, hero }

/// Marchio ufficiale: PNG originali (illustrazione + scritta).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.variant = AppLogoVariant.header});

  final AppLogoVariant variant;

  static const loginAsset = 'assets/branding/logo_login.png';
  static const headerAsset = 'assets/branding/logo_header.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Amici per la Coda',
      image: true,
      child: variant == AppLogoVariant.hero
          ? const _HeroLogo()
          : const _HeaderLogo(),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Image.asset(
        AppLogo.headerAsset,
        height: AppDim.logoHeaderH,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppLogo.loginAsset,
      width: AppDim.logoLoginW,
      height: AppDim.logoLoginH,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}
