# Anagrafiche complete, tessere cliccabili e date inseribili

Data: 2026-09-19
Progetto: Amici per la Coda
Stato: approvato in brainstorming (approccio 2)

## Problema

Quattro buchi nello stesso giro di uso quotidiano:

1. Nel wizard e in modifica cane le date (nascita, ingresso, iscrizione anagrafe, chip, sterilizzazione) non si aprono e non si possono scrivere.
2. Sulla scheda cane le tessere Stato attuale, sterilizzazione e Adottabile sono solo decorative. La seconda tessera dice «Sterilizzato» anche per i maschi interi.
3. *Altro → Veterinari e fornitori* elenca nomi ricavati da visite e spese; il tap è vuoto e non si può aggiungere nessuno a mano.
4. Registrare una famiglia crea una richiesta di adozione con iter a 5 passi. *Famiglie adottanti* ha il tap vuoto. Serve una rubrica, non un workflow.

## Decisioni bloccate

- Un solo disegno, quattro fette sequentiali (date → tessere → veterinari → famiglie).
- Approccio 2: anagrafiche vere, riuso di `adopters` / `adoptions` / nuova collezione `vendors`. Nessun rifacimento del modulo adozione in Firestore.
- Famiglie: rubrica da *Altro* e collegamento/creazione dalla scheda cane. Una famiglia per cane. Nessun iter e nessuno stato «richiesta» in UI.
- Dopo Registra/Collega: conferma «Segnare il cane come adottato?» (Sì aggiorna stato e adottabile; No lascia solo il legame).
- Maschio: Intero / Castrato. Femmina: Intera / Sterilizzata.
- Date: digitazione `gg/mm/aaaa` e icona calendario.
- Menu a tendina veterinario nei form Salute/Spese: fuori scope.
- *Gestione → Richieste e adozioni*: fuori scope (resta com’è). Il lavoro quotidiano passa da *Famiglie adottanti* e dalla scheda cane.
- Questionario casa/giardino: fuori scope; eventuali note vanno sul campo note dell’adottante.

## Vincoli di progetto (ogni fettina)

- Testi in italiano, date `dd/MM/yyyy`.
- Padding, raggi, font e icone solo da `lib/ui/tokens.dart` e `AppIcons`.
- Nessuno scroll orizzontale; testi in `Row` con `Expanded`, `maxLines`, ellipsis.
- Aree toccabili minime 40×40 dp.
- Contratto di layout in cima a ogni schermata/componente nuovo o modificato in modo visibile.
- Niente librerie extra.
- `flutter analyze` pulito e test della fettina verdi prima di passare alla successiva.
- Golden: si rigenerano solo se la modifica visiva è voluta (tessera Intero/Castrato, + in elenchi, tab Adozione senza iter).
- Permessi: chi non può scrivere vede elenco/scheda/tessere, non + / matita / tap di modifica.

---

## 1. Date nel profilo cane

### Causa

`AppFormField` passa `onTap` all’`InkWell` solo se `controller == null`. I campi data hanno controller e `readOnly: true`, quindi né tastiera né calendario.

### Comportamento

- I campi data del profilo (wizard *Nuovo cane* e *Modifica cane*) sono editabili.
- Si digita `gg/mm/aaaa` con tastierino numerico.
- Icona calendario a destra (40×40, `AppIcons.data`): apre `showDatePicker`.
- Tocco sul testo = focus per scrivere, non apre il calendario.
- Data vuota: ammessa su nascita, anagrafe, chip, sterilizzazione. Ingresso resta obbligatorio.
- Data presente ma non parsabile: errore sotto il campo, il salvataggio è bloccato.
- Intervalli del calendario:
  - nascita, ingresso, anagrafe, chip: da oggi−25 anni a oggi;
  - sterilizzazione *programmata*: lastDate può essere futura (oggi+10 anni, come `pickAppDate`).
- Stesso wiring per tutti i campi che già chiamano `pickDogFormDate`.

### Unità

- `AppFormField`: se ci sono controller e `onTap`, il `TextField` riceve `onTap` solo sull’icona suffix; il campo resta digitabile. L’`InkWell` esterno non deve più ingoiare il tap quando c’è un controller.
- `dog_profile_fields.dart`: `readOnly: false` sui campi data; suffix calendario.
- `pickDogFormDate`: lastDate futura solo se il chiamante lo chiede (sterilizzazione programmata).

### Errori

- `32/13/2026` → errore visibile, non si salva.
- Calendario annullato → il testo non cambia.

### Test

- Widget: icona apre il date picker; testo valido accettato; testo invalido rifiutato.
- Nessun golden se cambia solo il comportamento del tap. Se si aggiunge l’icona calendario, golden del wizard/modifica solo in quel caso.

---

## 2. Tessere sulla scheda cane

Le quattro tessere restano nella griglia 2×2. Chi non può scrivere non ha tap di modifica.

### Stato attuale

- Etichetta e valori invariati (`In rifugio`, `Adottato`, …).
- Tap → pagina esistente `ChangeStatusPage` (`/cani/:id/stato`).

### Situazione (ex tessera sterilizzazione)

- Etichetta: `Situazione`.
- Valore:

| Sesso | Non operato (`sterilizzato == false`) | Operato (`sterilizzato == true`) | Ignoto (`null`) |
|---|---|---|---|
| Maschio o sesso assente | Intero | Castrato | — |
| Femmina | Intera | Sterilizzata | — |

- Tap → `AppSheet` con due segmenti a larghezza piena (Intero\|Castrato oppure Intera\|Sterilizzata). Se si sceglie operato, compare il campo data intervento (digitabile + icona, lastDate = oggi: è la data dell’operazione fatta, non una programmazione). Salva scrive `dogs.sterilizzato` e `dogs.dataSterilizzazione`.
- Non crea un `HealthRecord` in automatico.
- Le stesse quattro parole sostituiscono «Sterilizzato» sul maschio in PDF, card social, testo annuncio e form modifica/wizard.

### Adottabile

- Etichetta invariata, valore Sì/No (o `—` se `null`).
- Tap → `AppSheet` Sì \| No. Salva `dogs.adottabile`.

### Richieste

- Non è cliccabile.
- Il numero è le famiglie collegate a quel cane (0 o 1 in questo disegno), non le richieste in iter.

### Unità

- `StatTile`: `onTap` opzionale, `InkWell`, min 40×40.
- `dog_labels.dart`: `dogSituazioneValue(dog)` (Intero/Castrato/Intera/Sterilizzata/—). Deprecare l’uso di `dogSterilizedLabel` + `yesNo` sulla tessera.
- Fogli: un file dedicato nella cartella dogs (es. `dog_quick_edit_sheets.dart`), non gonfiare `dog_detail_page.dart`.

### Test

- Sola lettura: nessun tap.
- Tap Stato apre la pagina stato.
- Salvare Castrato su un maschio → valore tessera `Castrato`, `sterilizzato == true`.
- Golden scheda cane: si rigenera per il testo della tessera.

---

## 3. Veterinari e fornitori

### Dati

Collezione `vendors/{id}`:

```
nome: string                 // obbligatorio
tipo: veterinario|clinica|farmacia|negozio|toelettatura|altro
telefono, email, indirizzo: string
convenzionato: bool
note: string
audit: come le altre anagrafiche
```

Niente `VendorRepository` finto in UI: stream da Firestore, come `AdopterRepository`.

### Elenco (`VendorsPage`)

- Righe: icona, nome, sottotitolo = etichetta tipo (Veterinario, Clinica, …).
- **+** in header 40×40 → form nuovo.
- Unione in elenco:
  - documenti `vendors`;
  - nomi ancora solo in `health.veterinario` / `expenses.fornitore` che non matchano un vendor (confronto case-insensitive sul nome).
- Tap su vendor salvato → scheda.
- Tap su nome «solo da visita/spesa» → form precompilato col nome; Salva crea `vendors`.
- Vuoto: empty state esistente; si usa il +.

### Scheda

- Titolo = nome.
- Righe: tipo, telefono, email, indirizzo, convenzionato (Sì/No), note. Mancanti: `—`.
- Matita → stesso form.
- Nessuna azione Chiama/Email in questo giro.

### Form

- Nome obbligatorio.
- Tipo: selettore segmentato o sheet (6 valori; se non stanno in 5 segmenti, sheet di scelte, non bottoni a tutta larghezza impilati).
- Convenzionato: Sì/No, default No.
- Tipo precompilato sui nomi orfani: Veterinario se il nome viene da una visita, Altro se viene da una spesa.
- Due schede con lo stesso nome sono ammesse.
- Un nome «solo da visita» si considera agganciato quando esiste un vendor con lo stesso nome case-insensitive.

### Fuori scope

- Tendina veterinario/fornitore in Salute e Spese: restano testo libero. I nuovi nomi continueranno ad apparire in elenco da completare.

### Test

- Tap su vendor con telefono/indirizzo mostra quei campi.
- + crea un veterinario e ricompare in elenco.
- Sola lettura: niente + / matita.
- Golden elenco se il + è visibile.

---

## 4. Famiglie adottanti e tab Adozione

### Modello

- `adopters` resta l’anagrafica (campi già esistenti).
- `adoptions` resta solo come **legame** cane↔famiglia (`dogId` + `adopterId`). In UI non si mostra `AdoptionStato` né la timeline a 5 passi.
- Un cane ha al più un legame attivo. «Attivo» = esiste un `adoptions` per quel `dogId` non cancellato. Se se ne crea un altro, si sostituisce (il documento vecchio si elimina o si considera non più il legame; scelta di implementazione: delete del vecchio legame, l’adottante resta in rubrica).
- `affidabilita` resta nel documento, non in UI.
- Match telefono/email in creazione: si propone la scheda esistente (logica già in `adoption_flow.dart`).

### Profilo adottante

Campi visibili: nome, cognome, telefono, email, città, indirizzo, tipo e numero documento, data di nascita, note, elenco cani collegati (tap → scheda cane).

Matita → form anagrafica. Nessun badge di iter, nessuna affidabilità.

### Elenco *Altro → Famiglie adottanti*

- Tap sulla riga → profilo.
- **+** header → form anagrafica senza cane obbligatorio. Salva solo `adopters`.
- Sottotitolo: città · N cani (`adozioniIds.length`).

### Tab Adozione del cane

Si toglie:

- card Iter / `TimelineList`;
- elenco «Richieste ricevute» con badge di stato;
- pulsante «Registra nuova richiesta».

Si tiene:

- banner adottabile;
- PDF, card social, copia testo annuncio.

Si aggiunge:

- Se nessun legame: **Registra famiglia** (form anagrafica, cane già selezionato) e **Collega famiglia** (sheet elenco adottanti).
- Se c’è legame: card nome, città, telefono; tap → profilo. **Sostituisci** (stesso flusso di Collega: nuova persona o altra scheda, poi di nuovo la conferma stato) e **Scollega**.
- Scollega: toglie il documento `adoptions` (e l’id da `adozioniIds`); non cancella l’adottante; **non** cambia `dogs.stato` né `adottabile`.
- Se il cane è già `adottato` e in conferma si sceglie Sì, non si riscrive lo storico. No lascia stato e adottabile com’erano.

### Conferma stato

Dopo un Registra o Collega andato a buon fine, `AppSheet` o dialogo:

«Segnare [nome cane] come adottato?»

- Sì: `stato = adottato`, `adottabile = false`, `statoDal = oggi`, voce in `storicoStati` come fa già `ChangeStatusPage` (stesso aggiornamento, senza aprire quella pagina).
- No: solo il legame.

### Dati già in Firestore

Una `adoptions` esistente sul cane (es. Roberto / Kratos) è il legame. Si mostra la card famiglia, non l’iter. I dati anagrafici restano.

### Form anagrafica famiglia

Campi: nome*, cognome*, telefono, email, città, indirizzo, documento (tipo + numero), data di nascita, note.

Titoli: «Nuova famiglia» / «Modifica famiglia», non «Nuova richiesta».
Niente card Questionario in questo giro.
Da Altro il cane non è richiesto. Dalla tab cane il cane è implicito.

### Fuori scope

- Pagina *Richieste di adozione* (filtri Da val. / Colloquio / …): invariata.
- Dettaglio richiesta con Avanza/Respingi: non è più raggiungibile dalla tab cane né da Famiglie adottanti.
- Questionario abitazione.

### Test

- + da Altro crea il profilo; tap lo apre con telefono e città.
- Da un cane, Collega + Sì → `stato == adottato`, `adottabile == false`, card famiglia visibile, iter assente.
- Da un cane, Collega + No → famiglia visibile, stato invariato.
- Scollega → card sparisce, adottante ancora in *Famiglie adottanti*.
- Telefono già presente → si propone la scheda, non un doppione.
- Golden tab Adozione: si rigenera (iter rimosso).

---

## Flusso dati (sintesi)

```
Date:        TextField → parseItalianDate → Dog / draft
Tessere:     AppSheet / ChangeStatusPage → DogRepository.save
Vendors:     VendorRepository.watchAll/save → vendors/{id}
             + nomi orfani da health/expenses (solo lettura elenco)
Famiglie:    AdopterRepository.save
Legame:      AdoptionRepository.save (dogId + adopterId)
Conferma Sì: DogRepository.save (stato, adottabile, storicoStati)
```

## Ordine di implementazione

1. Date (`AppFormField` + campi profilo) — sblocca il wizard.
2. Tessere e etichette Intero/Castrato.
3. Collezione vendors, elenco, scheda, form.
4. Profilo/elenco famiglie, tab Adozione, conferma stato.

Ogni fettina ha i suoi test e `flutter analyze` pulito. Non si passa alla successiva con test rossi.

## Fuori scope (riepilogo)

- Tendina vendor in Salute/Spese.
- Azioni Chiama/Email.
- Pagina globale Richieste di adozione e iter Avanza/Respingi.
- Questionario adottante.
- Eliminazione della collezione `adoptions`.
- Campo nuovo `dogs.famigliaId` (si riusa il legame esistente).
