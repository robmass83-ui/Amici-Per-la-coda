# Prompt per Cursor — Ottimizzazione foto e traffico Firestore

> App: **Amici per la Coda** (Flutter + Firestore, piano Spark gratuito, solo Android, tema scuro)
> **Versione 2 — riscritta dopo l'audit dello STEP 1.** Sostituisce la versione precedente.

---

## STATO: STEP 1 COMPLETATO

L'audit ha mostrato che **l'architettura delle foto è già corretta**. Le immagini non sono mai state dentro il documento cane: esistono già `photos/{id}` per metadati + miniatura e `photos/{id}/full/data` per la foto piena. Lo scenario da 40 MB per apertura della lista, su cui era costruita la versione 1 di questo documento, **non si applica**.

I numeri reali misurati nell'audit:

| Scenario | Egress |
|---|---|
| Snapshot `dogs` (199 documenti senza immagini) | ~0,6 MB |
| Lista, primi 20 cani visibili | ~1,0–1,6 MB a freddo |
| Lista, scorrendo tutti i cani | ~6–7 MB (thumb di 284 foto) |
| Apertura galleria, 1 foto piena | 150–300 KB, fino a ~870 KB |

Non è un'emergenza. Ma ci sono **quattro problemi reali**, in ordine di gravità:

1. **199 listener foto aperti insieme.** `photosByDogProvider(dogId)` viene chiamato da ogni `DogListTile`, non è `.autoDispose`, e scarica *tutte* le foto di quel cane, non solo la copertina. I listener restano accesi per tutta la sessione perché `StatefulShellRoute.indexedStack` non smonta i tab.
2. **Rischio di perdita dati sul full.** 700 KB binari in base64 diventano ~933 KB nel documento, contro un limite Firestore di 1 MiB. Un volontario che carica una foto poco comprimibile si vede la scrittura rifiutata.
3. **base64 ovunque**, che gonfia del 33% sia lo spazio occupato sia il traffico.
4. **JPEG invece di WebP**, che a parità di qualità percepita costa il 30-40% in più.

---

## DECISIONI PRESE — NON RIMETTERLE IN DISCUSSIONE

L'audit ha sollevato obiezioni corrette al piano originale. Sono state accettate:

1. **Si resta su `dogs` + `photos/{id}` + `photos/{id}/full/data`.** Nessuna migrazione a `cani/{id}/foto`: la struttura attuale è già "un documento = una foto", ha indici, regole, repository e import funzionanti. Spostarla non ridurrebbe l'egress di un byte.
2. **La miniatura NON va dentro il documento cane.** Con `watchAll()` senza `limit`, una thumb da 20-30 KB su ogni cane renderebbe lo snapshot `dogs` da 0,6 MB a ~5-6 MB *sempre* — peggio di oggi. L'obiezione dell'audit su questo punto è corretta.
3. **`watchAll()` sui cani resta senza `limit`.** I documenti cane pesano ~3 KB: 199 fanno 0,6 MB a freddo e quasi zero a caldo grazie alla persistenza. Introdurre la paginazione server-side romperebbe Home, statistiche, ricerca, `pick_dog_sheet` e backup, che dipendono tutti da `dogsStreamProvider`. Costo alto, beneficio nullo.
4. **Nessun file nuovo.** Si estende `lib/data/photos/photo_codec.dart` e `FirestorePhotoRepository`. Niente `image_service.dart`, niente secondo repository.
5. **Nessuno script di import nuovo.** Si riusa `tool/import/`, allineandolo al codec nuovo.

---

## OBIETTIVI NUMERICI

| Misura | Oggi | Target |
|---|---|---|
| Lista a freddo (cani + copertine) | ~1,0–1,6 MB, fino a 6-7 MB scorrendo | **< 2,5 MB totali, e scorrere non aggiunge nulla** |
| Lista a caldo (seconda apertura) | variabile | **< 50 KB** |
| Listener Firestore attivi sulla lista | ~200 | **2** |
| Galleria, una foto piena | fino a 870 KB | **< 450 KB** |
| Documento più grande | fino a 933 KB | **< 500 KB** |
| Occupazione Firestore | ~60 MB (44,8 MB binari + base64) | **< 45 MB** |
| Consumo mensile stimato | — | **< 1 GiB su 10 disponibili** |

---

## STEP 2 — Un solo listener per le copertine

**Questo è l'intervento che vale più di tutti gli altri messi insieme.** Fallo per primo.

Oggi ogni `DogListTile` apre `photosByDogProvider(dogId)`, che scarica tutte le foto di quel cane. Con 199 cani sono ~200 listener permanenti e ~284 miniature scaricate invece delle ~199 che servono.

Da fare:

- crea **un unico** provider delle copertine — `coverPhotosProvider` — che esegue una sola query:
  `photos.where('isCover', isEqualTo: true).snapshots()`
  e la espone come mappa `dogId → Photo`
- `DogListTile`, `PhotoThumb`, `home_page.dart` ("ultimi arrivi"), `search_page.dart`, `new_adoption_page.dart` e `dog_detail_page.dart` (copertina) leggono **solo** da questa mappa
- `photosByDogProvider` diventa `.autoDispose` e resta usato **solo** da `dog_gallery_page.dart` e dove serve davvero l'elenco completo delle foto di un cane
- `dog_altro_tab.dart` usa `photosByDogProvider` solo per contare le foto: sostituisci con un campo `fotoCount` (int) sul documento `Dog`, aggiornato con `FieldValue.increment` negli stessi `WriteBatch` già presenti in `FirestorePhotoRepository`. Costa 4 byte invece di un listener
- gestisci il caso "cane senza copertina": segnaposto, **mai** una query di fallback sulla sottocollezione
- verifica che `isCover` abbia l'indice a campo singolo (Firestore lo crea in automatico, conferma che la query non venga rifiutata)

**Test:**
1. conta i listener Firestore attivi con la lista aperta — devono essere **2** (`dogs` + copertine), non ~200
2. misura l'egress della lista a freddo: **< 2,5 MB**
3. scorri tutti i 199 cani: l'egress **non deve aumentare** (le copertine sono già tutte arrivate)
4. chiudi e riapri l'app: **< 50 KB**
5. verifica che la galleria continui a mostrare tutte le foto del cane

Riportami i quattro numeri misurati, non una descrizione.

---

## STEP 3 — base64 → Blob

Correzione di sicurezza, prima ancora che ottimizzazione: elimina il rischio di scritture rifiutate.

- in `photo_codec.dart` e `FirestorePhotoRepository`: `thumbB64` (String) → `thumb` (`Blob`), `b64` (String) → `dati` (`Blob`). `cloud_firestore` espone `Blob(Uint8List)` nativamente
- **lettura retrocompatibile**: se il campo vecchio esiste, usalo; scrivi sempre e solo nel campo nuovo. Così l'app funziona durante la migrazione
- abbassa il limite della foto piena da **700 KB a 450 KB binari**. Con `Blob` sono 450 KB nel documento, contro 1 MiB di limite: margine abbondante anche con tutti i metadati
- **guardia pre-scrittura**: se il documento risultante supera 900 KB, blocca e mostra un errore leggibile. Non deve mai partire una scrittura che Firestore rifiuterà
- allinea `tool/import/lib.mjs` (scrittura Blob invece di stringa base64)

**Test:** carica una foto da device reale, verifica in console Firebase che il campo sia di tipo *bytes* e non *string*, e che il documento sia ~25% più leggero di prima a parità di immagine. Verifica che una foto caricata **prima** della modifica si veda ancora.

---

## STEP 4 — JPEG → WebP, e compressione fuori dal main thread

In `lib/data/photos/photo_codec.dart`:

- `CompressFormat.jpeg` → `CompressFormat.webp`
- **foto piena**: 1400 px lato lungo, qualità 80, max **450 KB** (loop di qualità −5, minimo 45; se a 45 non rientra, scendi a 1100 px)
- **miniatura**: 200 px lato lungo, qualità 70, max **12 KB** (WebP a 200px ci sta comodamente, e a 200px la card si vede meglio di oggi a 160px)
- aggiorna il campo `mime` a `image/webp`
- sposta la compressione in `compute()`: oggi gira sul main thread e blocca la UI durante il caricamento
- **fallback**: se WebP non è disponibile sul device, ricadi su JPEG e registralo nel campo `mime`, senza far fallire il caricamento
- allinea `tool/import/lib.mjs`: `sharp` supporta WebP, stessi parametri (1400 px / q80 / 450 KB)

**Test:** `test/data/photo_codec_test.dart` con 3 immagini (foto da fotocamera ~4 MB, immagine già piccola, PNG con trasparenza). Verifica i limiti di byte, le proporzioni mantenute, la qualità visiva. Stampa una tabella prima/dopo e dimmi il risparmio percentuale medio rispetto al JPEG attuale.

---

## STEP 5 — Migrazione dei dati esistenti

199 cani, 284 foto già in Firestore in base64 + JPEG. Da convertire in Blob + WebP.

Script di migrazione una tantum (comando Node in `tool/` o schermata nascosta per il presidente):

1. scorre `photos`, per ogni foto legge il base64, decodifica, ricomprime in WebP secondo lo STEP 4, riscrive come `Blob`
2. fa lo stesso per `photos/{id}/full/data`
3. popola `fotoCount` su ogni `Dog`
4. rimuove i campi vecchi **solo dopo** aver verificato che i nuovi siano leggibili
5. **idempotente**: rieseguirlo salta ciò che è già convertito
6. a blocchi di 20, con log di avanzamento, interrompibile e riprendibile
7. errori su una foto registrati, non bloccanti

**Test:** prima `--dry-run` con il riepilogo di cosa farebbe. Poi 5 foto, verifica in app. Poi tutte. Riportami: foto convertite, MB prima, MB dopo, errori.

---

## STEP 6 — Le query rimanenti

- passa in rassegna tutti i provider Riverpod e metti `.autoDispose` dove il dato non serve globalmente
- `healthAllProvider` è ascoltato dalla lista Animali: verifica quanto pesa davvero e se serve lì o solo nella scheda
- `GetOptions(source: Source.cache)` con fallback server per i dati che cambiano di rado (razze, tipi di trattamento, impostazioni)
- indicatore "dati non aggiornati" basato su `snapshot.metadata.isFromCache`, non solo sulla connettività come fa oggi `homeOfflineProvider`
- verifica che i listener a lunga vita (`dogs`, copertine) **non** vengano ricreati al cambio di tab: con `indexedStack` restano montati, il che è un vantaggio per l'egress — la sincronizzazione diventa incrementale

**Test:** modalità aereo, naviga tra lista, schede e galleria: tutto ciò che è già stato visto resta consultabile, con l'indicatore visibile.

---

## STEP 7 — Guardrail permanenti

In `backend/firestore.rules`:

```
match /photos/{photoId} {
  allow create, update: if request.auth != null
    && (!('thumb' in request.resource.data)
        || request.resource.data.thumb.size() < 25000);
}
match /photos/{photoId}/full/{docId} {
  allow create, update: if request.auth != null
    && request.resource.data.dati.size() < 600000;
}
```

Più:

- un test che **fallisce** se `dog_list_tile.dart` importa o usa `photosByDogProvider`
- un commento in testa a `photo_codec.dart` e a `Photo` che spiega perché i limiti sono quelli e cosa succede se si alzano

**Test:** prova a scrivere a mano una foto da 800 KB e verifica che le regole la rifiutino.

---

## STEP 8 — Misura finale

Simula una giornata reale con 4 volontari: 20 aperture della lista, 40 aperture di schede, 15 aperture di galleria, 10 foto caricate, 5 modifiche di dati.

Misura il traffico totale e proiettalo su base mensile. **Criterio finale: sotto 1 GiB al mese**, cioè un decimo della quota.

Riportami il calcolo, non una stima a occhio.

---

## COSA NON FARE

- Non introdurre Firebase Storage, Supabase, Cloudinary o servizi esterni
- Non spostare le foto dentro il documento cane, per nessun motivo
- Non introdurre la paginazione server-side sui cani
- Non creare strutture, repository o script paralleli a quelli esistenti
- Non toccare tema scuro e vincoli UI (compatto, tutte le tab visibili, nessuno scroll orizzontale)
- Non dichiarare completato uno step senza i numeri misurati

Inizia dallo **STEP 2** e fermati lì.
