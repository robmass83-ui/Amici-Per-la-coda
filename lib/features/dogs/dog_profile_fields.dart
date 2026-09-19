import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/enums.dart';
import '../../ui/components.dart';
import '../../ui/form_pickers.dart';
import '../../ui/tokens.dart';
import 'new_dog/new_dog_draft.dart';
import 'new_dog/new_dog_validation.dart';

// ── CONTRATTO DI LAYOUT · Campi profilo cane (FormCard 14-ter.7) ───────────
// FormCard padding=10  titolo 12.5  gap interni 8
// AppFormField h=34  etichetta 10sp maiuscoletto
// FormRow2 gap=8  CompatRow h=30  AppSegmented 32/28
// Chip carattere h=26
// Chip e anagrafe: pelo 4 segmenti a riga piena · purezza 2
// Situazione sanitaria: Sì/No/Programmata + Data intervento se non No
// ───────────────────────────────────────────────────────────────────────────

const dogFormLabelStyle = TextStyle(
  fontFamily: 'Roboto',
  fontSize: AppText.caption,
  fontWeight: FontWeight.w600,
  color: AppColor.muted,
  height: AppDim.lineH,
);

const caratterePreset = [
  'Dolce',
  'Socievole',
  'Equilibrata',
  'Timida',
  'Vivace',
  'Protettiva',
];

class DogAnagraficaFields extends StatelessWidget {
  const DogAnagraficaFields({
    super.key,
    required this.nome,
    required this.dataNascita,
    required this.razza,
    required this.mantello,
    required this.sesso,
    required this.nascitaPresunta,
    required this.taglia,
    required this.onSesso,
    required this.onNascitaPresunta,
    required this.onTaglia,
    this.nomeError,
    this.nascitaError,
    this.nomeKey,
    this.tagliaKey,
    this.peso,
    this.showPeso = false,
    this.onChanged,
  });

  final TextEditingController nome;
  final TextEditingController dataNascita;
  final TextEditingController razza;
  final TextEditingController mantello;
  final TextEditingController? peso;
  final bool showPeso;
  final DogSex? sesso;
  final bool nascitaPresunta;
  final Taglia taglia;
  final String? nomeError;
  final String? nascitaError;
  final Key? nomeKey;
  final Key? tagliaKey;
  final ValueChanged<DogSex> onSesso;
  final ValueChanged<bool> onNascitaPresunta;
  final ValueChanged<Taglia> onTaglia;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Anagrafica',
      icon: AppIcons.carattere,
      children: [
        AppFormField(
          key: nomeKey,
          label: 'Nome *',
          hint: 'Es. Fenice',
          controller: nome,
          errorText: nomeError,
          onChanged: (_) => onChanged?.call(),
        ),
        FormRow2(
          left: AppFormField(
            label: 'Sesso',
            child: AppSegmented(
              values: const ['♀ F', '♂ M'],
              tooltips: const ['Femmina', 'Maschio'],
              selectedIndex: sesso == DogSex.F
                  ? 0
                  : sesso == DogSex.M
                  ? 1
                  : -1,
              onChanged: (i) {
                onSesso(i == 0 ? DogSex.F : DogSex.M);
                onChanged?.call();
              },
            ),
          ),
          right: AppFormField(
            label: 'Data di nascita',
            hint: 'gg/mm/aaaa',
            controller: dataNascita,
            keyboardType: TextInputType.datetime,
            errorText: nascitaError,
            suffix: dateFieldSuffix(
              onTap: () => pickDogFormDate(context, dataNascita, onChanged),
            ),
          ),
        ),
        FormRow2(
          left: AppFormField(
            label: 'Precisione',
            child: AppSegmented(
              values: const ['Presunta', 'Certa'],
              selectedIndex: nascitaPresunta ? 0 : 1,
              onChanged: (i) {
                onNascitaPresunta(i == 0);
                onChanged?.call();
              },
            ),
          ),
          right: AppFormField(
            label: 'Taglia',
            child: AppSegmented(
              key: tagliaKey,
              values: const ['P', 'M', 'G'],
              tooltips: const ['Piccola', 'Media', 'Grande'],
              selectedIndex: Taglia.values.indexOf(taglia),
              onChanged: (i) {
                onTaglia(Taglia.values[i]);
                onChanged?.call();
              },
            ),
          ),
        ),
        FormRow2(
          left: AppFormField(
            label: 'Razza / tipo',
            hint: 'Es. Meticcia',
            controller: razza,
            onChanged: (_) => onChanged?.call(),
          ),
          right: AppFormField(
            label: 'Mantello',
            hint: 'Es. fulvo chiaro',
            controller: mantello,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        if (showPeso)
          AppFormField(
            label: 'Peso attuale (kg)',
            hint: 'Es. 22',
            controller: peso,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged?.call(),
          ),
      ],
    );
  }
}

class DogIdentificazioneFields extends StatelessWidget {
  const DogIdentificazioneFields({
    super.key,
    required this.microchip,
    required this.iscrittoAnagrafe,
    required this.onIscritto,
    required this.onScan,
    this.microchipError,
    this.microchipKey,
    this.scanKey,
    this.onChanged,
  });

  final TextEditingController microchip;
  final IscrittoAnagrafe iscrittoAnagrafe;
  final String? microchipError;
  final Key? microchipKey;
  final Key? scanKey;
  final VoidCallback onScan;
  final ValueChanged<IscrittoAnagrafe> onIscritto;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Identificazione',
      icon: AppIcons.microchip,
      children: [
        FormRow2(
          leftFlex: 8,
          rightFlex: 5,
          left: AppFormField(
            key: microchipKey,
            label: 'Microchip',
            hint: '15 cifre',
            controller: microchip,
            errorText: microchipError,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(microchipCifre),
            ],
            onChanged: (_) => onChanged?.call(),
            suffix: GestureDetector(
              key: scanKey,
              behavior: HitTestBehavior.opaque,
              onTap: onScan,
              child: const IconBadge(
                AppIcons.fotocamera,
                size: IconBadge.inTitle,
              ),
            ),
          ),
          right: AppFormField(
            label: 'Anagrafe',
            child: AppSegmented(
              values: const ['Sì', 'No', '?'],
              tooltips: const ['Sì', 'No', 'Da verificare'],
              selectedIndex: IscrittoAnagrafe.values.indexOf(iscrittoAnagrafe),
              onChanged: (i) {
                onIscritto(IscrittoAnagrafe.values[i]);
                onChanged?.call();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DogChipAnagrafeFields extends StatelessWidget {
  const DogChipAnagrafeFields({
    super.key,
    required this.tipoPelo,
    required this.purezza,
    required this.dataApplicazioneChip,
    required this.zonaApplicazioneChip,
    required this.veterinarioApplicatore,
    required this.dataIscrizioneAnagrafe,
    required this.ultimaUbicazione,
    required this.onTipoPelo,
    required this.onPurezza,
    this.onChanged,
    this.chipDateError,
    this.anagrafeDateError,
  });

  final TipoPelo? tipoPelo;
  final Purezza? purezza;
  final TextEditingController dataApplicazioneChip;
  final TextEditingController zonaApplicazioneChip;
  final TextEditingController veterinarioApplicatore;
  final TextEditingController dataIscrizioneAnagrafe;
  final TextEditingController ultimaUbicazione;
  final ValueChanged<TipoPelo> onTipoPelo;
  final ValueChanged<Purezza> onPurezza;
  final VoidCallback? onChanged;
  final String? chipDateError;
  final String? anagrafeDateError;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Chip e anagrafe',
      icon: AppIcons.anagrafe,
      children: [
        AppFormField(
          label: 'Tipo pelo',
          child: AppSegmented(
            values: const ['Corto', 'Medio', 'Lungo', '?'],
            tooltips: const ['Corto', 'Medio', 'Lungo', 'Non indicato'],
            selectedIndex: tipoPelo == null
                ? -1
                : TipoPelo.values.indexOf(tipoPelo!),
            onChanged: (i) {
              onTipoPelo(TipoPelo.values[i]);
              onChanged?.call();
            },
          ),
        ),
        AppFormField(
          label: 'Purezza',
          child: AppSegmented(
            values: const ['Meticcio', 'Purezza'],
            tooltips: const ['Meticcio', 'In purezza'],
            selectedIndex: purezza == null
                ? -1
                : Purezza.values.indexOf(purezza!),
            onChanged: (i) {
              onPurezza(Purezza.values[i]);
              onChanged?.call();
            },
          ),
        ),
        FormRow2(
          left: AppFormField(
            label: 'Chip applicato',
            hint: 'gg/mm/aaaa',
            controller: dataApplicazioneChip,
            keyboardType: TextInputType.datetime,
            errorText: chipDateError,
            suffix: dateFieldSuffix(
              onTap: () =>
                  pickDogFormDate(context, dataApplicazioneChip, onChanged),
            ),
          ),
          right: AppFormField(
            label: 'Zona chip',
            hint: 'Es. collo sx',
            controller: zonaApplicazioneChip,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        AppFormField(
          label: 'Veterinario applicatore',
          hint: 'Nome del veterinario',
          controller: veterinarioApplicatore,
          onChanged: (_) => onChanged?.call(),
        ),
        AppFormField(
          label: 'Iscrizione anagrafe',
          hint: 'gg/mm/aaaa',
          controller: dataIscrizioneAnagrafe,
          keyboardType: TextInputType.datetime,
          errorText: anagrafeDateError,
          suffix: dateFieldSuffix(
            onTap: () =>
                pickDogFormDate(context, dataIscrizioneAnagrafe, onChanged),
          ),
        ),
        AppFormField(
          label: 'Ubicazione in anagrafe',
          hint: 'Indirizzo che risulta in anagrafe',
          controller: ultimaUbicazione,
          maxLines: 2,
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }
}

class DogProvenienzaFields extends StatelessWidget {
  const DogProvenienzaFields({
    super.key,
    required this.provenienza,
    required this.dataIngresso,
    required this.modalitaLabel,
    required this.boxLabel,
    required this.onModalita,
    required this.onBox,
    this.referenteLabel,
    this.onReferente,
    this.ingressoError,
    this.ingressoStimata,
    this.onIngressoStimata,
    this.onChanged,
  });

  static const boxFieldKey = Key('dog-form-box');

  final TextEditingController provenienza;
  final TextEditingController dataIngresso;
  final String modalitaLabel;
  final String boxLabel;
  final String? referenteLabel;
  final String? ingressoError;
  final bool? ingressoStimata;
  final VoidCallback onModalita;
  final VoidCallback onBox;
  final VoidCallback? onReferente;
  final ValueChanged<bool>? onIngressoStimata;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Provenienza e ingresso',
      icon: AppIcons.provenienza,
      children: [
        AppFormField(
          label: 'Luogo di provenienza',
          hint: 'Es. Corleto Perticara (PZ)',
          controller: provenienza,
          onChanged: (_) => onChanged?.call(),
        ),
        FormRow2(
          left: AppFormField(
            label: 'Modalità',
            hint: modalitaLabel,
            readOnly: true,
            onTap: onModalita,
          ),
          right: AppFormField(
            label: 'Ingresso *',
            hint: 'gg/mm/aaaa',
            controller: dataIngresso,
            errorText: ingressoError,
            keyboardType: TextInputType.datetime,
            suffix: dateFieldSuffix(
              onTap: () => pickDogFormDate(context, dataIngresso, onChanged),
            ),
          ),
        ),
        if (onIngressoStimata != null) ...[
          AppFormField(
            label: 'Precisione ingresso',
            child: AppSegmented(
              values: const ['Stimata', 'Certa'],
              selectedIndex: ingressoStimata == true
                  ? 0
                  : ingressoStimata == false
                  ? 1
                  : -1,
              onChanged: (i) {
                onIngressoStimata!(i == 0);
                onChanged?.call();
              },
            ),
          ),
        ],
        FormRow2(
          left: AppFormField(
            key: boxFieldKey,
            label: 'Box',
            hint: boxLabel,
            readOnly: true,
            onTap: onBox,
          ),
          right: onReferente == null
              ? const SizedBox.shrink()
              : AppFormField(
                  label: 'Referente',
                  hint: referenteLabel ?? '—',
                  readOnly: true,
                  onTap: onReferente,
                ),
        ),
      ],
    );
  }
}

class DogPresentazioneFields extends StatelessWidget {
  const DogPresentazioneFields({
    super.key,
    required this.slogan,
    required this.descrizione,
    this.sloganKey,
    this.descrizioneKey,
    this.onChanged,
  });

  final TextEditingController slogan;
  final TextEditingController descrizione;
  final Key? sloganKey;
  final Key? descrizioneKey;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Presentazione',
      icon: AppIcons.annuncio,
      children: [
        AppFormField(
          key: sloganKey,
          label: 'Slogan',
          controller: slogan,
          maxLines: 2,
          onChanged: (_) => onChanged?.call(),
        ),
        AppFormField(
          key: descrizioneKey,
          label: 'Descrizione',
          controller: descrizione,
          maxLines: 4,
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }
}

class DogCarattereFields extends StatelessWidget {
  const DogCarattereFields({
    super.key,
    required this.sesso,
    required this.carattere,
    required this.conPersone,
    required this.conCani,
    required this.conGatti,
    required this.conBambini,
    required this.noteCarattere,
    required this.onToggleTrait,
    required this.onAddCustom,
    required this.onConPersone,
    required this.onConCani,
    required this.onConGatti,
    required this.onConBambini,
    this.onChanged,
  });

  final DogSex? sesso;
  final List<String> carattere;
  final ConPersone? conPersone;
  final ConCani conCani;
  final ConGatti conGatti;
  final ConBambini conBambini;
  final TextEditingController noteCarattere;
  final ValueChanged<String> onToggleTrait;
  final VoidCallback onAddCustom;
  final ValueChanged<ConPersone> onConPersone;
  final ValueChanged<ConCani> onConCani;
  final ValueChanged<ConGatti> onConGatti;
  final ValueChanged<ConBambini> onConBambini;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final selettivo = sesso == DogSex.F ? 'Selettiva' : 'Selettivo';
    return FormCard(
      title: 'Carattere e compatibilità',
      icon: AppIcons.carattere,
      children: [
        Wrap(
          spacing: AppDim.gapXs,
          runSpacing: AppDim.gapXs,
          children: [
            for (final label in [
              ...caratterePreset,
              ...carattere.where((item) => !caratterePreset.contains(item)),
            ])
              AppChip(
                label: label,
                selected: carattere.contains(label),
                height: AppDim.formChipH,
                padding: const EdgeInsets.symmetric(horizontal: AppDim.gapS),
                onSelected: () {
                  onToggleTrait(label);
                  onChanged?.call();
                },
              ),
            AppChip(
              label: '+',
              selected: false,
              height: AppDim.formChipH,
              padding: const EdgeInsets.symmetric(horizontal: AppDim.gapS),
              onSelected: onAddCustom,
            ),
          ],
        ),
        Column(
          children: [
            CompatRow(
              label: 'Con persone',
              values: const ['Socievole', 'Selettivo', 'Diffidente'],
              tooltips: ['Molto socievole', selettivo, 'Diffidente'],
              selectedIndex: conPersone == null
                  ? -1
                  : ConPersone.values.indexOf(conPersone!),
              onChanged: (i) {
                onConPersone(ConPersone.values[i]);
                onChanged?.call();
              },
            ),
            const SizedBox(height: AppDim.gapXs),
            CompatRow(
              label: 'Con cani',
              values: const ['Sì', 'Solo ♀', 'No', '?'],
              tooltips: const ['Sì', 'Solo femmine', 'No', 'Da testare'],
              selectedIndex: conCaniIndex(conCani),
              onChanged: (i) {
                onConCani(conCaniAt(i));
                onChanged?.call();
              },
            ),
            const SizedBox(height: AppDim.gapXs),
            CompatRow(
              label: 'Con gatti',
              values: const ['Sì', '?', 'No'],
              tooltips: const ['Sì', 'Da testare', 'No'],
              selectedIndex: conGattiIndex(conGatti),
              onChanged: (i) {
                onConGatti(conGattiAt(i));
                onChanged?.call();
              },
            ),
            const SizedBox(height: AppDim.gapXs),
            CompatRow(
              label: 'Con bambini',
              values: const ['Sì', 'Grandi', 'No', '?'],
              tooltips: const ['Sì', 'Solo grandi', 'No', 'Da testare'],
              selectedIndex: conBambiniIndex(conBambini),
              onChanged: (i) {
                onConBambini(conBambiniAt(i));
                onChanged?.call();
              },
            ),
          ],
        ),
        AppFormField(
          label: 'Note sul carattere',
          controller: noteCarattere,
          maxLines: 4,
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }
}

class DogSterilizzazioneFields extends StatelessWidget {
  const DogSterilizzazioneFields({
    super.key,
    required this.sesso,
    required this.sterilizzazione,
    required this.dataSterilizzazione,
    required this.onSterilizzazione,
    this.sterilizzazioneKey,
    this.dataKey,
    this.onChanged,
    this.dataError,
  });

  final DogSex? sesso;
  final WizardSterilizzazione? sterilizzazione;
  final TextEditingController dataSterilizzazione;
  final ValueChanged<WizardSterilizzazione> onSterilizzazione;
  final Key? sterilizzazioneKey;
  final Key? dataKey;
  final VoidCallback? onChanged;
  final String? dataError;

  @override
  Widget build(BuildContext context) {
    final showDate = sterilizzazione == WizardSterilizzazione.si ||
        sterilizzazione == WizardSterilizzazione.programmata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormField(
          label: sesso == DogSex.F ? 'Sterilizzata' : 'Castrato',
          child: AppSegmented(
            key: sterilizzazioneKey,
            values: const ['Sì', 'No', 'Programmata'],
            tooltips: const ['Sì', 'No', 'Intervento già programmato'],
            selectedIndex: sterilizzazione == null
                ? -1
                : WizardSterilizzazione.values.indexOf(sterilizzazione!),
            onChanged: (i) {
              onSterilizzazione(WizardSterilizzazione.values[i]);
              onChanged?.call();
            },
          ),
        ),
        if (showDate) ...[
          const SizedBox(height: AppDim.formRowGap),
          AppFormField(
            key: dataKey,
            label: 'Data intervento',
            hint: 'gg/mm/aaaa',
            controller: dataSterilizzazione,
            keyboardType: TextInputType.datetime,
            errorText: dataError,
            suffix: dateFieldSuffix(
              onTap: () => pickDogFormDate(
                context,
                dataSterilizzazione,
                onChanged,
                allowFuture: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class DogAdozioneFields extends StatelessWidget {
  const DogAdozioneFields({
    super.key,
    required this.adottabile,
    required this.pubblicato,
    required this.onAdottabile,
    required this.onPubblicato,
    this.onChanged,
  });

  final WizardAdottabile? adottabile;
  final bool pubblicato;
  final ValueChanged<WizardAdottabile> onAdottabile;
  final ValueChanged<bool> onPubblicato;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Adozione',
      icon: AppIcons.adottabile,
      children: [
        FormRow2(
          leftFlex: 3,
          rightFlex: 2,
          left: AppFormField(
            label: 'Adottabile',
            child: AppSegmented(
              values: const ['Sì', 'Non ancora', 'No'],
              tooltips: const ['Sì', 'Non ancora', 'Non adottabile'],
              selectedIndex: adottabile == null
                  ? -1
                  : WizardAdottabile.values.indexOf(adottabile!),
              onChanged: (i) {
                onAdottabile(WizardAdottabile.values[i]);
                onChanged?.call();
              },
            ),
          ),
          right: AppFormField(
            label: 'Pubblicato',
            child: AppSegmented(
              values: const ['Sì', 'No'],
              tooltips: const ['Sì, subito', 'Solo interno'],
              selectedIndex: pubblicato ? 0 : 1,
              onChanged: (i) {
                onPubblicato(i == 0);
                onChanged?.call();
              },
            ),
          ),
        ),
      ],
    );
  }
}

int conCaniIndex(ConCani value) {
  return switch (value) {
    ConCani.si => 0,
    ConCani.selettivo => 1,
    ConCani.no => 2,
    ConCani.daTestare => 3,
  };
}

ConCani conCaniAt(int index) {
  return switch (index) {
    0 => ConCani.si,
    1 => ConCani.selettivo,
    2 => ConCani.no,
    _ => ConCani.daTestare,
  };
}

int conGattiIndex(ConGatti value) {
  return switch (value) {
    ConGatti.si => 0,
    ConGatti.daTestare => 1,
    ConGatti.no => 2,
  };
}

ConGatti conGattiAt(int index) {
  return switch (index) {
    0 => ConGatti.si,
    2 => ConGatti.no,
    _ => ConGatti.daTestare,
  };
}

int conBambiniIndex(ConBambini value) {
  return switch (value) {
    ConBambini.si => 0,
    ConBambini.soloGrandi => 1,
    ConBambini.no => 2,
    ConBambini.daTestare => 3,
  };
}

ConBambini conBambiniAt(int index) {
  return switch (index) {
    0 => ConBambini.si,
    1 => ConBambini.soloGrandi,
    2 => ConBambini.no,
    _ => ConBambini.daTestare,
  };
}
