import '../../data/models/enums.dart';

const templateVisibilitaLabels = ['Home', 'Scheda', 'Entrambi', 'Nessuna'];

String templateVisibilitaLabel(TemplateVisibilita value) {
  return switch (value) {
    TemplateVisibilita.home => 'Home',
    TemplateVisibilita.scheda => 'Scheda',
    TemplateVisibilita.entrambi => 'Entrambi',
    TemplateVisibilita.nessuna => 'Nessuna',
  };
}

String templateVisibilitaDescrizione(TemplateVisibilita value) {
  return switch (value) {
    TemplateVisibilita.home => 'Visibile in home',
    TemplateVisibilita.scheda => 'Visibile nella scheda cane',
    TemplateVisibilita.entrambi => 'Home e scheda cane',
    TemplateVisibilita.nessuna => 'Non visibile',
  };
}
