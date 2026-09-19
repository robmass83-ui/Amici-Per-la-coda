# Icone e precisione del layout — come togliere a Cursor la libertà di improvvisare

## Perché succede

Cursor non vede il riferimento HTML renderizzato: ne legge il **codice**, come testo.
Quando trova `🏠` o `💉` dentro un `<span>` non capisce «qui va un badge quadrato verde
28×28 con l'icona della casa»: capisce «qui c'è un simbolo». Quindi improvvisa — e le
improvvisazioni cambiano ogni volta.

Vale lo stesso per le posizioni. «Come nel riferimento» non è un'istruzione eseguibile.
`Row(children: [badge 27, gap 9, Column(...)])` sì.

La soluzione è la stessa per entrambi i problemi: **togliergli le decisioni**.
Tre livelli, dal più importante:

1. **Un catalogo di icone con nomi propri.** Non sceglie più: scrive `AppIcons.sterilizzato`.
2. **Un contratto di layout per ogni schermata.** L'albero dei widget scritto prima di
   programmare, con le misure. Non interpreta: trascrive.
3. **I golden test.** Una volta che una schermata ti piace, si fotografa. Se un giorno la
   sposta di 4 pixel, il test diventa rosso da solo.

E un trucco che vale da solo metà del lavoro: **incolla lo screenshot nella chat di Cursor**.
Apri `design/reference.html` nel browser, fai lo screenshot della schermata che sta
costruendo e trascinalo nella chat insieme al prompt. Il modello le immagini le vede, e
confronta molto meglio di quanto non ricostruisca da una descrizione.

---

# 1 · Catalogo icone — `lib/ui/icons.dart`

Crea questo file esattamente così. Da qui in poi **nessuna icona può essere scelta a mano**:
se serve un concetto che non è in elenco, si aggiunge qui prima di usarlo.

```dart
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Un'icona del progetto: simbolo + colore di sfondo + colore del simbolo.
/// Non usare MAI Icons.* direttamente nelle schermate: passa sempre da AppIcons.
@immutable
class AppIconSpec {
  const AppIconSpec(this.icon, this.bg, this.fg);
  final IconData icon;
  final Color bg;
  final Color fg;
}

abstract final class AppIcons {
  // colori del simbolo, derivati dalla palette
  static const _green  = Color(0xFF136135);
  static const _blue   = Color(0xFF1D5F9E);
  static const _red    = Color(0xFFB0303B);
  static const _purple = Color(0xFF5C33A0);
  static const _orange = Color(0xFF9D6212);
  static const _pink   = Color(0xFFC2185B);
  static const _grey   = Color(0xFF5F6B62);

  // ---------- anagrafica del cane ----------
  static const sessoF        = AppIconSpec(Icons.female_rounded,          AppColor.pinkSoft,    _pink);
  static const sessoM        = AppIconSpec(Icons.male_rounded,            AppColor.blueSoft,    _blue);
  static const dataNascita   = AppIconSpec(Icons.cake_rounded,            AppColor.blueSoft,    _blue);
  static const data          = AppIconSpec(Icons.calendar_month_rounded,  AppColor.blueSoft,    _blue);
  static const razza         = AppIconSpec(Icons.pets_rounded,            AppColor.neutralSoft, _grey);
  static const peso          = AppIconSpec(Icons.monitor_weight_rounded,  AppColor.neutralSoft, _grey);
  static const microchip     = AppIconSpec(Icons.qr_code_2_rounded,       AppColor.neutralSoft, _grey);
  static const provenienza   = AppIconSpec(Icons.place_rounded,           AppColor.redSoft,     _red);
  static const anagrafe      = AppIconSpec(Icons.badge_rounded,           AppColor.purpleSoft,  _purple);
  static const carattere     = AppIconSpec(Icons.pets_rounded,            AppColor.greenSoft,   _green);

  // ---------- stati del cane ----------
  static const inRifugio     = AppIconSpec(Icons.home_rounded,            AppColor.greenSoft,   _green);
  static const inStallo      = AppIconSpec(Icons.hotel_rounded,           AppColor.purpleSoft,  _purple);
  static const preaffido     = AppIconSpec(Icons.handshake_rounded,       AppColor.orangeSoft,  _orange);
  static const adottato      = AppIconSpec(Icons.favorite_rounded,        AppColor.redSoft,     _red);
  static const inCura        = AppIconSpec(Icons.local_hospital_rounded,  AppColor.blueSoft,    _blue);
  static const restituito    = AppIconSpec(Icons.keyboard_return_rounded, AppColor.neutralSoft, _grey);
  static const deceduto      = AppIconSpec(Icons.local_florist_rounded,   AppColor.neutralSoft, _grey);

  // ---------- sanitario ----------
  static const vaccino       = AppIconSpec(Icons.vaccines_rounded,        AppColor.blueSoft,    _blue);
  static const sterilizzato  = AppIconSpec(Icons.vaccines_rounded,        AppColor.blueSoft,    _blue);
  static const farmaco       = AppIconSpec(Icons.medication_rounded,      AppColor.orangeSoft,  _orange);
  static const antiparass    = AppIconSpec(Icons.shield_rounded,          AppColor.blueSoft,    _blue);
  static const visita        = AppIconSpec(Icons.medical_services_rounded,AppColor.blueSoft,    _blue);
  static const esame         = AppIconSpec(Icons.biotech_rounded,         AppColor.purpleSoft,  _purple);
  static const scadenza      = AppIconSpec(Icons.schedule_rounded,        AppColor.redSoft,     _red);
  static const terapia       = AppIconSpec(Icons.healing_rounded,         AppColor.blueSoft,    _blue);

  // ---------- adozione ----------
  static const adottabile    = AppIconSpec(Icons.favorite_rounded,        AppColor.redSoft,     _red);
  static const richieste     = AppIconSpec(Icons.groups_rounded,          AppColor.purpleSoft,  _purple);
  static const iter          = AppIconSpec(Icons.explore_rounded,         AppColor.purpleSoft,  _purple);
  static const annuncio      = AppIconSpec(Icons.campaign_rounded,        AppColor.orangeSoft,  _orange);
  static const aDistanza     = AppIconSpec(Icons.volunteer_activism_rounded, AppColor.greenSoft, _green);
  static const telefono      = AppIconSpec(Icons.call_rounded,            AppColor.greenSoft,   _green);
  static const email         = AppIconSpec(Icons.mail_outline_rounded,    AppColor.blueSoft,    _blue);

  // ---------- spese ----------
  static const spese         = AppIconSpec(Icons.savings_rounded,         AppColor.orangeSoft,  _orange);
  static const movimento     = AppIconSpec(Icons.receipt_long_rounded,    AppColor.blueSoft,    _blue);
  static const ripartizione  = AppIconSpec(Icons.pie_chart_rounded,       AppColor.orangeSoft,  _orange);

  // ---------- documenti e note ----------
  static const documenti     = AppIconSpec(Icons.description_rounded,     AppColor.purpleSoft,  _purple);
  static const libretto      = AppIconSpec(Icons.menu_book_rounded,       AppColor.neutralSoft, _grey);
  static const modulo        = AppIconSpec(Icons.assignment_rounded,      AppColor.greenSoft,   _green);
  static const firma         = AppIconSpec(Icons.draw_rounded,            AppColor.greenSoft,   _green);
  static const allegato      = AppIconSpec(Icons.attach_file_rounded,     AppColor.neutralSoft, _grey);
  static const note          = AppIconSpec(Icons.edit_note_rounded,       AppColor.neutralSoft, _grey);
  static const comportamento = AppIconSpec(Icons.psychology_rounded,      AppColor.redSoft,     _red);
  static const alimentazione = AppIconSpec(Icons.restaurant_rounded,      AppColor.blueSoft,    _blue);

  // ---------- foto ----------
  static const galleria      = AppIconSpec(Icons.photo_library_rounded,   AppColor.blueSoft,    _blue);
  static const fotocamera    = AppIconSpec(Icons.photo_camera_rounded,    AppColor.greenSoft,   _green);
  static const video         = AppIconSpec(Icons.videocam_rounded,        AppColor.purpleSoft,  _purple);

  // ---------- rifugio ----------
  static const box           = AppIconSpec(Icons.meeting_room_rounded,    AppColor.orangeSoft,  _orange);
  static const infermeria    = AppIconSpec(Icons.medical_information_rounded, AppColor.blueSoft, _blue);
  static const isolamento    = AppIconSpec(Icons.coronavirus_rounded,     AppColor.redSoft,     _red);
  static const manutenzione  = AppIconSpec(Icons.build_rounded,           AppColor.neutralSoft, _grey);
  static const volontari     = AppIconSpec(Icons.groups_rounded,          AppColor.purpleSoft,  _purple);
  static const turnoMattina  = AppIconSpec(Icons.wb_twilight_rounded,     AppColor.orangeSoft,  _orange);
  static const turnoSera     = AppIconSpec(Icons.nights_stay_rounded,     AppColor.purpleSoft,  _purple);
  static const passeggiata   = AppIconSpec(Icons.directions_walk_rounded, AppColor.greenSoft,   _green);
  static const trasferimento = AppIconSpec(Icons.local_shipping_rounded,  AppColor.neutralSoft, _grey);

  // ---------- sistema ----------
  static const statistiche   = AppIconSpec(Icons.insights_rounded,        AppColor.greenSoft,   _green);
  static const notifiche     = AppIconSpec(Icons.notifications_rounded,   AppColor.orangeSoft,  _orange);
  static const impostazioni  = AppIconSpec(Icons.settings_rounded,        AppColor.neutralSoft, _grey);
  static const backup        = AppIconSpec(Icons.cloud_done_rounded,      AppColor.blueSoft,    _blue);
  static const esporta       = AppIconSpec(Icons.ios_share_rounded,       AppColor.neutralSoft, _grey);
  static const archivia      = AppIconSpec(Icons.inventory_2_rounded,     AppColor.redSoft,     _red);
  static const duplica       = AppIconSpec(Icons.content_copy_rounded,    AppColor.neutralSoft, _grey);
  static const link          = AppIconSpec(Icons.link_rounded,            AppColor.neutralSoft, _grey);
  static const cambiaStato   = AppIconSpec(Icons.swap_horiz_rounded,      AppColor.greenSoft,   _green);
  static const esci          = AppIconSpec(Icons.logout_rounded,          AppColor.redSoft,     _red);
  static const offline       = AppIconSpec(Icons.wifi_off_rounded,        AppColor.neutralSoft, _grey);
  static const lingua        = AppIconSpec(Icons.language_rounded,        AppColor.neutralSoft, _grey);
  static const tema          = AppIconSpec(Icons.brightness_6_rounded,    AppColor.neutralSoft, _grey);

  /// Icone di stato, per costruire pill e badge dal valore del modello.
  static AppIconSpec perStato(String stato) => switch (stato) {
    'in_rifugio' => inRifugio,
    'in_stallo'  => inStallo,
    'preaffido'  => preaffido,
    'adottato'   => adottato,
    'in_cura'    => inCura,
    'restituito' => restituito,
    'deceduto'   => deceduto,
    _            => inRifugio,
  };

  /// Icone sanitarie, dal campo `tipo` di health.
  static AppIconSpec perTrattamento(String tipo) => switch (tipo) {
    'vaccino'          => vaccino,
    'sterilizzazione'  => sterilizzato,
    'sverminazione'    => farmaco,
    'antiparassitario' => antiparass,
    'visita'           => visita,
    'esame'            => esame,
    'terapia'          => terapia,
    _                  => visita,
  };
}
```

## Il widget che le disegna — `lib/ui/components/icon_badge.dart`

Nel riferimento HTML ogni icona sta dentro un quadratino colorato con angoli arrotondati.
Questo è quel quadratino. Nelle schermate si usa solo questo, mai un `Icon` nudo.

```dart
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../icons.dart';

/// Quadratino colorato con l'icona dentro — l'elemento visivo ricorrente
/// dell'app (righe informative, menu, liste, stat card).
class IconBadge extends StatelessWidget {
  const IconBadge(this.spec, {super.key, this.size = AppDim.iconBox});

  final AppIconSpec spec;
  final double size;

  /// Misure ammesse: 20 (dentro i titoli), 27 (righe informative),
  /// 30 (stat card), 32 (righe di menu), 34 (avatar dei volontari).
  static const inTitle = 20.0;
  static const inRow   = 27.0;
  static const inStat  = 30.0;
  static const inMenu  = 32.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(spec.icon, size: size * 0.52, color: spec.fg),
    );
  }
}
```

---

# 2 · Contratto di layout — come si scrive una schermata

Prima di programmare una schermata, Cursor deve **scriverne il contratto** in cima al file,
come commento, e poi limitarsi a trascriverlo in codice. Questo è il formato, con un esempio
vero. La regola: ogni riga dice widget, misure e distanze. Niente aggettivi.

```dart
// ── CONTRATTO DI LAYOUT · Card di un cane nell'elenco ──────────────────────
// Container  h=auto  padding=8  radius=11  bordo AppColor.line  fondo bianco
// └ Row  crossAxisAlignment=center
//   ├ foto/avatar  44×44  radius=9                      (flex: none)
//   ├ SizedBox w=9
//   ├ Expanded
//   │  └ Column  crossAxisAlignment=start  mainAxisSize=min
//   │     ├ Text nome            12.5sp w700  AppColor.ink   maxLines=1 ellipsis
//   │     ├ SizedBox h=1
//   │     ├ Text sottotitolo     10sp   w400  AppColor.muted maxLines=1 ellipsis
//   │     ├ SizedBox h=4
//   │     └ Wrap spacing=4 runSpacing=4
//   │        └ MiniBadge ×n      9sp w700  padding 2/6  radius 20
//   └ Icon chevron_right  size=16  AppColor.faint
// Distanza fra due card: 8
// ───────────────────────────────────────────────────────────────────────────
```

Tre cose rendono il contratto vincolante e non decorativo:

- **`Expanded` e `maxLines` sono parte del contratto**, non dettagli. Sono ciò che impedisce
  a un nome lungo di rompere la riga.
- **Ogni distanza è un `SizedBox` con un numero**, mai un `Padding` messo a occhio.
- **`flex: none` va scritto** dove un elemento non deve stringersi.

Il contratto va **lasciato nel file**. Quando fra tre settimane Cursor tornerà su quella
schermata, lo rileggerà e non reinventerà niente.

---

# 3 · Golden test — la schermata si fotografa e non si muove più

Quando una schermata ti piace, si blocca con una fotografia di riferimento. Da quel momento
qualunque spostamento fa fallire il test.

```dart
// test/golden/dogs_list_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Elenco cani — aspetto bloccato a 360×640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TestApp(child: DogsListScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DogsListScreen),
      matchesGoldenFile('goldens/dogs_list_360.png'),
    );
  });
}
```

Come si usa, in pratica:

1. Cursor costruisce la schermata.
2. **Tu la guardi.** Finché non ti piace, non si blocca niente.
3. Quando ti piace: `flutter test --update-goldens`. Nasce il PNG di riferimento.
4. Da lì in poi `flutter test` fallisce se la schermata cambia di un pixel. Se il cambiamento
   era voluto, si rigenera il golden; se non lo era, hai trovato una regressione che a occhio
   non avresti mai visto.

Metti i golden sotto git: sono la memoria visiva del progetto.

---

# 4 · Prompt da incollare in Cursor

```
Le icone e le posizioni non corrispondono al riferimento perché finora hai
dovuto sceglierle tu. Adesso non le scegli più: sono decise. Fai queste tre
cose, in ordine, poi fermati.

## A · Catalogo icone

Crea `lib/ui/icons.dart` con la classe `AppIconSpec` e la classe `AppIcons`
esattamente come te le do qui sotto [INCOLLA IL CODICE DELLA SEZIONE 1].
Crea poi `lib/ui/components/icon_badge.dart` con il widget `IconBadge`
[INCOLLA IL CODICE].

Poi passa su TUTTE le schermate già fatte e sostituisci ogni icona esistente
con `IconBadge(AppIcons.qualcosa)`. Da adesso in poi vale questa regola:
è VIETATO scrivere `Icon(Icons.…)` dentro una schermata. Le uniche eccezioni
sono le icone di sistema (freccia indietro, chevron delle liste, lente della
ricerca, icone della bottom nav), che restano `Icon` nudi.
Se ti serve un concetto che non è nel catalogo, aggiungilo prima ad AppIcons
e poi usalo: non improvvisare nel punto in cui ti serve.

## B · Contratto di layout

D'ora in avanti, PRIMA di scrivere il codice di una schermata o di un
componente, scrivi in cima al file il contratto di layout come commento, nel
formato che ti mostro qui [INCOLLA L'ESEMPIO DELLA SEZIONE 2]: albero dei
widget, dimensioni, distanze, allineamenti, maxLines. Poi trascrivi il
contratto in codice senza discostartene.

Il contratto resta nel file. Se in futuro modifichi la schermata, aggiorni
prima il contratto e poi il codice.

Scrivi adesso il contratto per le schermate già fatte: elenco cani, scheda
cane, home. Se il codice attuale non corrisponde al contratto che hai appena
scritto, allinea il codice, non il contratto.

## C · Golden test

Aggiungi `test/golden/` con un golden test per elenco cani, scheda cane e home
a 360×640 dp, come nell'esempio [INCOLLA IL CODICE DELLA SEZIONE 3].
NON generare i golden adesso: prima devo guardare le schermate io. Quando ti
dirò «blocca i golden» eseguirai `flutter test --update-goldens`.

Al termine: `flutter analyze`, `flutter test`, screenshot a 360 dp di elenco
cani e scheda cane, riepilogo di 5 righe, poi fermati.
```

---

# 5 · Regole da aggiungere al file `.cursor/rules/amici-per-la-coda.mdc`

Aggiungile in fondo alla sezione delle regole:

```
12. È vietato scrivere Icon(Icons.…) dentro una schermata. Le icone si prendono da
    AppIcons e si disegnano con IconBadge. Fanno eccezione solo le icone di sistema:
    freccia indietro, chevron delle liste, lente della ricerca, icone della bottom nav.
    Se serve un concetto non presente, si aggiunge prima ad AppIcons.
13. Prima di programmare una schermata o un componente si scrive in cima al file il
    contratto di layout come commento: albero dei widget con dimensioni, distanze,
    allineamenti e maxLines. Il codice trascrive il contratto. Il contratto resta nel
    file e si aggiorna prima del codice.
14. Le distanze si esprimono sempre con SizedBox espliciti presi da AppDim, mai con
    Padding messi a occhio o con Spacer dove serve una misura precisa.
15. Ogni testo dentro una Row che può eccedere ha Expanded, maxLines e
    TextOverflow.ellipsis. Non è un dettaglio: è ciò che impedisce gli overflow.
16. Le schermate approvate sono coperte da golden test. Un golden non si rigenera per
    far passare il test: si rigenera solo quando la modifica visiva era voluta.
```

---

## In sintesi

| Problema | Causa | Rimedio |
|---|---|---|
| Icone diverse dal riferimento | doveva sceglierle lui | `AppIcons` + `IconBadge`, divieto di `Icon()` nelle schermate |
| Posizioni approssimative | «come nel riferimento» non è eseguibile | contratto di layout scritto prima del codice |
| Le cose si spostano fra uno step e l'altro | niente le teneva ferme | golden test sotto git |
| Cursor non vede com'è fatto | legge il codice HTML, non l'immagine | incolla lo screenshot nella chat |
