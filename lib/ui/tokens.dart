import 'package:flutter/material.dart';

/// Colori — identici al riferimento HTML.
abstract final class AppColor {
  static const green = Color(0xFF157A3C); // primario
  static const greenDark = Color(0xFF0F5C2C);
  static const greenSoft = Color(0xFFE7F4EB); // sfondo chip/icona
  static const greenTint = Color(0xFFF2FAF4); // sfondo box citazione

  static const ink = Color(0xFF16211B); // testo principale
  static const ink2 = Color(0xFF2C3A32);
  static const muted = Color(0xFF6E7B72); // etichette
  static const faint = Color(0xFF9AA69E); // placeholder

  static const bg = Color(0xFFF5F7F3); // sfondo schermata
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE9EBE4); // bordo card
  static const line2 = Color(0xFFF1F3EC); // separatori

  static const blue = Color(0xFF2E7FD6);
  static const blueSoft = Color(0xFFE7F1FC);
  static const red = Color(0xFFE04552);
  static const redSoft = Color(0xFFFDECEE);
  static const purple = Color(0xFF7B4CC0);
  static const purpleSoft = Color(0xFFF2EAFC);
  static const orange = Color(0xFFDE8A22);
  static const orangeSoft = Color(0xFFFDF1DF);
  static const pinkSoft = Color(0xFFFCE9F1);
  static const neutralSoft = Color(0xFFEFF1ED);
  static const barTrack = Color(0xFFEDF0EB);

  /// Ombra tenue delle card, ~8% di [ink].
  static const shadow = Color(0x1416211B);

  /// Cuore del marchio ufficiale.
  static const logoHeart = Color(0xFFED1B24);
}

/// Dimensioni testo, in sp. NON inventarne altre.
abstract final class AppText {
  static const display = 26.0; // nome del cane nella scheda
  static const title = 15.0; // titolo di schermata / cifre grandi
  static const h2 = 13.0; // titolo di sezione
  static const body = 12.0; // testo corrente
  static const value = 11.5; // valori nelle righe chiave/valore
  static const label = 10.5; // etichette, sottotitoli
  static const caption = 10.0; // date, note secondarie
  static const micro = 9.0; // badge, label delle tab
  static const hello = 17.0; // saluto home
  static const todo = 10.8; // voce "da fare oggi"
  static const todoTrail = 10.2; // trailing della voce
  static const statNote = 9.5; // note sotto le stat home
}

/// Spaziature, raggi, misure fisse.
abstract final class AppDim {
  static const gapXs = 4.0;
  static const gapS = 6.0;
  static const gapM = 9.0; // distanza standard fra card
  static const gapL = 12.0; // padding di pagina
  static const gapXl = 16.0;

  static const pagePad = EdgeInsets.all(12);
  static const cardPad = EdgeInsets.all(10);
  static const inputPad = EdgeInsets.symmetric(horizontal: 11, vertical: 10);

  static const radCard = 12.0;
  static const radInput = 10.0;
  static const radChip = 20.0;
  static const radSheet = 20.0;
  static const radIconBox = 8.0;

  static const iconInline = 14.0;
  static const iconTab = 16.0;
  static const iconNav = 18.0;
  static const iconBox = 27.0; // quadratino colorato dietro l'icona

  static const tabBarH = 46.0;
  static const bottomNavH = 58.0;
  static const fabSize = 52.0;
  static const appBarH = 44.0;
  static const minTouch = 40.0;
  static const searchH = 38.0;
  static const listAvatar = 44.0;
  static const gapHair = 1.0;

  /// Misure della §3.2, mancanti nel blocco originale.
  static const headerBtn = 34.0;
  static const chipH = 28.0;
  static const segmentedH = 34.0;
  static const logoLoginW = 248.0;
  static const logoLoginH = 180.0;
  static const logoHeaderH = 32.0;
  static const logoBarH = 52.0;

  /// Foto copertina nella scheda cane (riferimento HTML 158×212, ridotta per 320 dp).
  static const photoW = 120.0;
  static const photoH = 168.0;

  /// Altezza del grafico peso nella tab Salute (riferimento HTML).
  static const chartH = 72.0;

  /// Hero della galleria foto (riferimento HTML 300).
  static const galleryHeroH = 300.0;

  static const lineH = 1.28; // altezza riga standard

  /// Home / dashboard (Step 9-bis).
  static const helloGap = 2.0;
  static const helloTracking = -0.3;
  static const displayTracking = -1.0;
  static const statBarH = 7.0;
  static const statBarR = 6.0;
  static const statBarGap = 8.0;
  static const todoPadV = 3.5;
  static const todoGap = 7.0;
  static const arriviPad = 7.0;
  static const arriviRadius = 9.0;
  static const emptyTodoH = 56.0;
  static const offlineBannerH = 22.0;
  static const homeAvatar = 34.0;
  static const shortcutAspect = 2.05;

  /// Wizard nuovo cane (Step 11).
  static const dashW = 1.5;
  static const descFieldH = 80.0;
  static const coverBadgePad = 2.0;

  /// Campo note del cambio stato (riferimento HTML 64).
  static const statoNoteH = 64.0;
}
