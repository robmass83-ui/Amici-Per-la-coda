import '../../core/format_it.dart';
import '../../data/models/adoption.dart';
import '../../data/models/dog.dart';
import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../dashboard/home_aggregators.dart';
import '../dogs/dog_labels.dart';
import 'adoption_flow.dart';

MiniBadgeVariant adoptionStatoBadge(AdoptionStato stato) {
  return switch (stato) {
    AdoptionStato.ricevuta => MiniBadgeVariant.orange,
    AdoptionStato.colloquio => MiniBadgeVariant.blue,
    AdoptionStato.visita => MiniBadgeVariant.purple,
    AdoptionStato.preaffido => MiniBadgeVariant.green,
    AdoptionStato.adottato => MiniBadgeVariant.green,
    AdoptionStato.respinta => MiniBadgeVariant.neutral,
    AdoptionStato.ritirata => MiniBadgeVariant.neutral,
  };
}

String adoptionListBadgeLabel(AdoptionStato stato) {
  return switch (stato) {
    AdoptionStato.ricevuta => 'Da valutare',
    AdoptionStato.colloquio => 'Colloquio',
    AdoptionStato.visita => 'Visita ok',
    AdoptionStato.preaffido => 'Preaffido',
    AdoptionStato.adottato => 'Adottato',
    AdoptionStato.respinta => 'Respinta',
    AdoptionStato.ritirata => 'Ritirata',
  };
}

String adoptionAdvanceLabel(AdoptionStato stato) {
  final next = nextAdoptionStato(stato);
  if (next == null) {
    return 'Avanza';
  }
  return switch (next) {
    AdoptionStato.colloquio => 'Avanza a colloquio',
    AdoptionStato.visita => 'Avanza a visita',
    AdoptionStato.preaffido => 'Avanza a preaffido',
    AdoptionStato.adottato => 'Avanza ad adozione',
    _ => 'Avanza',
  };
}

String adoptionDogLine(Dog? dog, DateTime now) {
  if (dog == null) {
    return 'Cane non trovato';
  }
  final parts = <String>[
    dogDisplayName(dog.nome),
    if (dog.razza.isNotEmpty) dog.razza,
    ?dogAgeShortLabel(dog, now),
  ];
  return parts.join(' · ');
}

String adoptionMetaLine(Adoption adoption, DateTime now) {
  if (adoption.stato == AdoptionStato.preaffido) {
    final dal = adoption.preaffidoDal;
    final al = adoption.preaffidoAl;
    if (dal != null && al != null) {
      final left = DateTime(
        al.year,
        al.month,
        al.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
      if (left < 0) {
        return 'Preaffido dal ${formatItalianDate(dal)} · scaduto';
      }
      if (left == 0) {
        return 'Preaffido dal ${formatItalianDate(dal)} · scade oggi';
      }
      return 'Preaffido dal ${formatItalianDate(dal)} · scade tra $left gg';
    }
  }
  if (adoption.stato == AdoptionStato.respinta) {
    return 'Richiesta non idonea';
  }
  return richiestaStatoDescrittivo(adoption, now);
}

String giardinoValue(Questionario q) {
  if (!q.giardinoRecintato) {
    return 'No';
  }
  if (q.altezzaRecinzione.trim().isEmpty) {
    return 'Sì';
  }
  return 'Sì · ${q.altezzaRecinzione}';
}

class IterTappaView {
  const IterTappaView({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.current,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool current;
}

List<IterTappaView> iterTappeDi(Adoption adoption) {
  final currentIndex = iterTappe.indexOf(adoption.stato);
  const titles = [
    'Richiesta ricevuta',
    'Colloquio conoscitivo',
    'Visita pre-affido',
    'Preaffido 30 giorni',
    'Adozione definitiva',
  ];
  const subtitles = [
    'Modulo online o in sede',
    'Con il volontario referente',
    'Controllo casa e recinzione',
    'Modulo firmato + documento identità',
    'Passaggio microchip in anagrafe canina',
  ];
  return [
    for (var i = 0; i < iterTappe.length; i++)
      IterTappaView(
        title: titles[i],
        subtitle: _iterSubtitle(adoption, i, currentIndex, subtitles[i]),
        done: currentIndex > i ||
            (adoption.stato == AdoptionStato.adottato && i == currentIndex),
        current: currentIndex == i &&
            adoption.stato != AdoptionStato.adottato &&
            canAdvanceAdoption(adoption.stato),
      ),
  ];
}

String _iterSubtitle(
  Adoption adoption,
  int index,
  int currentIndex,
  String fallback,
) {
  if (currentIndex < 0) {
    if (adoption.stato == AdoptionStato.respinta && index == 0) {
      return 'Respinta';
    }
    return fallback;
  }
  if (index < currentIndex) {
    final match = adoption.storicoStati.where(
      (voce) => !voce.isModuloInviato && voce.stato == iterTappe[index],
    );
    if (match.isNotEmpty) {
      return '${formatItalianDate(match.last.data)} · completato';
    }
    return 'Completato';
  }
  if (index == currentIndex) {
    return 'In corso';
  }
  return fallback;
}

List<TimelineItem> iterTimelineItems(Adoption adoption) {
  return [
    for (final tappa in iterTappeDi(adoption))
      TimelineItem(
        title: tappa.title,
        subtitle: tappa.subtitle,
        color: tappa.done
            ? AppColor.green
            : tappa.current
            ? AppColor.orange
            : AppColor.faint,
      ),
  ];
}
