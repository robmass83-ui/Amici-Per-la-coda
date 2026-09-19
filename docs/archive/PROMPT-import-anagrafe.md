# Prompt per Cursor — import dei 39 cani e campi da aggiungere al profilo

Il file `Cani_Amici_per_la_Coda_IMPORT.xlsx` segue il tracciato richiesto: i fogli
`cani`, `salute` e `foto` hanno le intestazioni e i valori esattamente come specificati,
date in gg/mm/aaaa, SI/NO in maiuscolo, valori degli elenchi copiati tali e quali.

Ci sono però **quattro fogli in più**, ed è la parte da leggere con attenzione.

## Perché ci sono fogli in più

Le schede dell'anagrafe canina contengono informazioni che il tracciato del profilo cane non
prevede, e che buttare via sarebbe un peccato — una in particolare non è un dettaglio.

**Ogni cane ha un proprietario legale, e non è l'associazione.** Ventotto dei trentanove cani
sono intestati alla volontaria Donata De Rosa, cinque a Donatella De Rosa, tre a Isabella
Miriam Maddaloni, due a Maria Giuseppina Maddaloni, uno a Giovanni Maddaloni. Ventuno sono
arrivati con un passaggio di proprietà vero, registrato all'ASP di Potenza il 15/07/2024: un
privato che cede il cane alla volontaria.

Questo conta perché quando una famiglia adotta serve lo stesso passaggio al contrario. Se
l'app non lo gestisce, in anagrafe il cane resta intestato alla volontaria: se si perde, se
morde qualcuno, se espatria, la responsabilità è ancora sua. È la classica cosa di cui nessuno
si accorge finché non succede.

Il modello completo (collezioni `intestatari` e `passaggiProprieta`, passaggio automatico
all'adozione, scadenza per la registrazione all'ASP, esclusioni dall'export pubblico) è scritto
in `SPEC-anagrafe-e-passaggi.md`. Qui basta sapere che i dati per popolarlo ci sono già.

| Foglio | Righe | Cosa contiene |
|---|---|---|
| `anagrafe_extra` | 39 | tipo di pelo, purezza, data e zona di applicazione del chip, veterinario, data di iscrizione, ubicazione in anagrafe, intestatario, detentore |
| `intestatari` | 11 | le persone registrate: volontarie e precedenti proprietari, con codice fiscale e recapiti |
| `passaggi_proprieta` | 39 | 18 prime iscrizioni e 21 cessioni registrate |
| `istruzioni` | — | cosa è dedotto, cosa manca, cosa verificare |

## Cosa è stato dedotto, e come disfarlo

Tre cose non sono nei documenti e sono state ricostruite. Sono tutte reversibili e segnalate.

**`dataIngresso`** — l'anagrafe non ha la data di ingresso in rifugio. È stata usata la data in
cui il cane è passato alla volontaria: 11/07/2024 per ventuno cani, la prima iscrizione a suo
nome per gli altri. In `anagrafe_extra` la colonna `dataIngressoStimata` vale SI per tutti e 39.

**`modalitaIngresso`** — `rinuncia` solo per i ventuno con l'attestato di cessione da un
privato, perché è quello che il documento prova. Vuoto per gli altri diciotto.

**`razza`** — le schede dicono «METICCIO (RAZZA NON IDENTIFICABILE)»: scritto `Meticcio` per
trentotto cani. Wolf è l'unico di razza, Pastore Tedesco in purezza.

## Cosa manca e va compilato a mano

`settore`, `box`, `pesoKg`, `adottabile`, `carattere`, `slogan`, `descrizione`, `referente`,
`patologie` e le foto non esistono nell'anagrafe. `adottabile` in particolare è lasciato vuoto
di proposito: è una decisione di Giovanna, non un dato. `conCani`, `conGatti` e `conBambini`
valgono `da_testare`, che nell'elenco dei valori significa esattamente «non lo sappiamo».
`sterilizzato` vale NO sui venticinque cani dove il documento lo dichiara, ed è vuoto sugli
altri quattordici: vuoto **non** vuol dire «non sterilizzato».

---

# Prompt da incollare

```
Ti passo @Cani_Amici_per_la_Coda_IMPORT.xlsx con i 39 cani del rifugio, presi dalle
schede dell'anagrafe canina regionale. I fogli cani, salute e foto sono nel tracciato
che mi avevi chiesto: intestazioni identiche, date gg/mm/aaaa, SI/NO, valori degli
elenchi copiati tali e quali.

Ci sono quattro fogli in più (anagrafe_extra, intestatari, passaggi_proprieta,
istruzioni) perché l'anagrafe contiene dati che il profilo cane oggi non prevede.
Leggi il foglio istruzioni prima di partire: dice cosa è dedotto e cosa manca.

PARTE 1 — IMPORT

Importa i fogli cani, salute e foto.

- Idempotente sul microchip: rieseguirlo non crea doppioni, aggiorna e basta.
  I 39 microchip sono tutti distinti, l'ho verificato.
- Cella vuota = "il documento non lo dice". Mai false, mai zero, mai una stringa
  vuota al posto di null. In particolare sterilizzato vuoto NON è "non sterilizzato".
- Le date sono gg/mm/aaaa. Convertile a mezzogiorno UTC, così nessun fuso le sposta
  al giorno prima.
- Il foglio salute contiene una riga per cane: l'applicazione del microchip, con data
  e veterinario. È l'unico atto sanitario che l'anagrafe riporta.
- Il foglio foto ha solo le intestazioni: fotografie non ce ne sono ancora.
- Al termine stampami: cani creati, cani aggiornati, righe salute create, e l'elenco
  dei campi rimasti vuoti con quanti cani li hanno vuoti. Se i cani importati non
  sono 39, fermati senza scrivere niente.

PARTE 2 — CAMPI NUOVI SUL PROFILO CANE

Il foglio anagrafe_extra ha dati che oggi non hanno un posto dove stare. Aggiungili
a dogs, importali, e mostrali nella scheda del cane:

  tipoPelo                  corto | medio | lungo | non_indicato
  purezza                   meticcio | in_purezza
  dataApplicazioneChip      data
  zonaApplicazioneChip      testo, es. "collo sx"
  veterinarioApplicatore    testo (collegalo a vendors se quella collezione esiste già)
  dataIscrizioneAnagrafe    data
  ultimaUbicazione          l'indirizzo che risulta in anagrafe
  dataIngressoStimata       bool, come nascitaPresunta

dataIngressoStimata serve a dire la verità: le date di ingresso sono ricostruite, non
lette da un documento. Dove è true, la scheda mostra la data con accanto "(stimata)",
come già si fa per la data di nascita presunta.

PARTE 3 — PROPRIETÀ E PASSAGGI

Questa è la parte che manca davvero, ed è scritta per intero in
@SPEC-anagrafe-e-passaggi.md. In sintesi: collezione intestatari (le 11 persone del
foglio omonimo), collezione passaggiProprieta (i 39 del foglio), dogs.intestatarioId
come copia dell'ultimo passaggio REGISTRATO, e soprattutto il passaggio automatico
quando un'adozione arriva a "adottato": dalla volontaria alla famiglia, in stato
da_registrare, con la scadenza per andare all'ASP. Finché non è registrato
l'intestatario NON cambia: in anagrafe il cane è ancora della volontaria e l'app deve
dirlo.

I passaggi del file si importano con statoRegistrazione = registrato e la loro data:
sono fatti già avvenuti, non devono generare scadenze.

Privacy: i fogli intestatari, passaggi_proprieta e anagrafe_extra contengono codici
fiscali, indirizzi di casa e cellulari di privati che con l'associazione non hanno più
niente a che fare. Intestatario, codice fiscale, detentore, passaggi e protocollo vanno
nell'elenco degli esclusi dall'export pubblico, e il test che lo verifica lo scrivi
PRIMA del codice dell'export.

Esegui la Parte 1 e la Parte 2 adesso. Per la Parte 3 leggi la spec e dimmi come
pensi di procedere prima di scrivere codice.

Al termine: flutter analyze, flutter test, l'import su database vuoto con il riepilogo
che stampa, screenshot della scheda di un cane a 360 dp, riepilogo di 5 righe, e fermati.
```
