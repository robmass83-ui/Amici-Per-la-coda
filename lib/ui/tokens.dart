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

  static const lineH = 1.28; // altezza riga standard
}
