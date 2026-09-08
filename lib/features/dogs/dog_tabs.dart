import '../../ui/icons.dart';

enum DogSheetTab {
  scheda('Scheda', AppIcons.modulo),
  salute('Salute', AppIcons.vaccino),
  adozione('Adozione', AppIcons.adottabile),
  spese('Spese', AppIcons.spese),
  documenti('Documenti', AppIcons.documenti),
  note('Note', AppIcons.note),
  altro('Altro', AppIcons.altro);

  const DogSheetTab(this.label, this.icon);

  final String label;
  final AppIconSpec icon;

  static const labels = [
    'Scheda',
    'Salute',
    'Adozione',
    'Spese',
    'Documenti',
    'Note',
    'Altro',
  ];
}
