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
  static const attenzione    = AppIconSpec(Icons.warning_amber_rounded,   AppColor.orangeSoft,  _orange);
  static const questionario  = AppIconSpec(Icons.assignment_rounded,    AppColor.purpleSoft,  _purple);
  static const respingi     = AppIconSpec(Icons.close_rounded,            AppColor.redSoft,     _red);

  // ---------- foto ----------
  static const galleria      = AppIconSpec(Icons.photo_library_rounded,   AppColor.blueSoft,    _blue);
  static const fotocamera    = AppIconSpec(Icons.photo_camera_rounded,    AppColor.greenSoft,   _green);
  static const video         = AppIconSpec(Icons.videocam_rounded,        AppColor.purpleSoft,  _purple);
  static const elimina       = AppIconSpec(Icons.close_rounded,           AppColor.redSoft,     _red);
  static const copertina     = AppIconSpec(Icons.star_rounded,            AppColor.orangeSoft,  _orange);

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
  static const condividi     = AppIconSpec(Icons.ios_share_rounded,       AppColor.greenSoft,   _green);
  static const apri          = AppIconSpec(Icons.open_in_new_rounded,      AppColor.blueSoft,    _blue);
  static const carica        = AppIconSpec(Icons.upload_file_rounded,     AppColor.greenSoft,   _green);

  // ---------- concetti usati dalle schermate, assenti nel catalogo originale ----------
  static const catalogo        = AppIconSpec(Icons.palette_rounded,          AppColor.greenSoft,   _green);
  static const modifica        = AppIconSpec(Icons.edit_rounded,             AppColor.greenSoft,   _green);
  static const foto            = AppIconSpec(Icons.photo_rounded,            AppColor.blueSoft,    _blue);
  static const cerca           = AppIconSpec(Icons.search_rounded,           AppColor.blueSoft,    _blue);
  static const altro           = AppIconSpec(Icons.more_horiz_rounded,       AppColor.neutralSoft, _grey);
  static const mostraPassword  = AppIconSpec(Icons.visibility_outlined,      AppColor.neutralSoft, _grey);
  static const nascondiPassword = AppIconSpec(Icons.visibility_off_outlined, AppColor.neutralSoft, _grey);
  static const errore          = AppIconSpec(Icons.pets_rounded,             AppColor.redSoft,     _red);
  static const regolazioni     = AppIconSpec(Icons.tune_rounded,             AppColor.neutralSoft, _grey);
  static const aggiorna        = AppIconSpec(Icons.system_update_alt_rounded, AppColor.greenSoft,   _green);

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
    'altro'            => altro,
    _                  => visita,
  };

  static AppIconSpec perSpesa(String categoria) => switch (categoria) {
    'visita' => visita,
    'sterilizzazione' => sterilizzato,
    'farmaci' => farmaco,
    'esami' => esame,
    'cibo' => alimentazione,
    _ => spese,
  };

  static AppIconSpec perDocumento(String tipo) => switch (tipo) {
    'libretto' => libretto,
    'anagrafe' => anagrafe,
    'verbale' => documenti,
    'preaffido' => modulo,
    'adozione' => modulo,
    'microchip' => microchip,
    'preaffido_firmato' => modulo,
    'adozione_firmato' => modulo,
    'documento_identita' => anagrafe,
    _ => allegato,
  };

  static AppIconSpec perAppuntamento(String tipo) => switch (tipo) {
    'visita' => visita,
    'colloquio' => richieste,
    'turno' => volontari,
    'verifica_preaffido' => preaffido,
    'scadenza' => scadenza,
    _ => altro,
  };

  static AppIconSpec perNota(String tipo) => switch (tipo) {
    'comportamento' => comportamento,
    'alimentazione' => alimentazione,
    'attenzione' => attenzione,
    _ => note,
  };
}
