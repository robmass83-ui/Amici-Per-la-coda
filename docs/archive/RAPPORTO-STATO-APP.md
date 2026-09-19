# Rapporto sullo stato reale dell’app

Letto il 9 settembre 2026 sul codice attuale. Ogni affermazione cita file e riga. Dove il codice non c’è, è scritto **non trovato**.

`flutter analyze`: 0 issue. `flutter test`: 200 test, tutti verdi. Dettaglio in sezione 7.

---

## 1. Stato degli step

| Step | Titolo | Stato | Prove |
|---|---|---|---|
| 1 | Fondamenta del progetto | completo | `lib/main.dart:8-12` avvia Firebase e l’app; `lib/app.dart:41-46` è `MaterialApp.router`; `test/widget_test.dart:6-13` verifica che l’app parta sul login. |
| 2 | Design system e catalogo | completo | `lib/ui/tokens.dart` (costanti); `lib/ui/theme.dart`; catalogo in `lib/features/debug/debug_ui_page.dart:10-47`; rotta `lib/router.dart:94-97`. Componenti esportati in `lib/ui/components.dart:1-22`. |
| 3 | Firebase e autenticazione | parziale | Login reale: `lib/features/auth/login_page.dart:199-221` chiama `signIn`. Guardia: `lib/router.dart:78-87`. Errori IT: `lib/core/auth_errors.dart` (file presente). **Manca:** «Resta collegato» è solo stato locale, mai passato a Auth (`login_page.dart:21` e `113-124`; `signIn` in `lib/data/firestore/firebase_auth_repository.dart:26-34` non ha parametro persistenza). «Password dimenticata?» è un toast (`login_page.dart:143-147`). |
| 4 | Modelli, repository e seed | completo | Interfacce `lib/data/repositories/data_repositories.dart:20-122`; Firestore `lib/data/firestore/firestore_repositories.dart`. Seed: cani CSV + 6 profili `[PROVA]` (`lib/data/seed/seed_data.dart:45-99`, `278-279`). |
| 5 | Shell e navigazione | completo | `lib/features/shell/app_shell.dart:11-42`; bottom nav 4 voci + FAB `lib/ui/components/app_bottom_nav.dart:14-80`; `StatefulShellRoute` `lib/router.dart:142-214`. Test: `test/features/shell/shell_navigation_test.dart`. |
| 6 | Elenco cani | parziale | Lista, ricerca, segmenti, paginazione 20: `lib/features/dogs/dogs_page.dart:39-43`, `88-96`, `198-204`. **Manca:** filtri avanzati = toast (`dogs_page.dart:152-156`). L’elenco **non esclude** `archiviato` (`dog_list_query.dart:62-69`: `tutti => true`). |
| 7 | Scheda cane: intestazione e tab | parziale | 7 tab non scorrevoli `lib/features/dogs/dog_detail_page.dart:572-578`; 7 InfoRow `334-377`; 4 StatTile `499-543`. **Manca rispetto al riferimento/17-bis:** Condividi header = toast (`134-137`); ⋮ ha **una sola** voce «Modifica scheda» (`138-155`), non le otto del 17-bis. Cuore «preferito»: **non trovato** nel modello né in UI (allineato al consiglio della Parte 2 punto 8). |
| 8 | Tab Scheda e Tab Salute | completo | Griglia 2×2 da repository `lib/features/dogs/dog_scheda_tab.dart:41-49`. Scadenze `dog_salute_tab.dart:65`. Grafico da `weights` `62-64`, `147`. Aggiungi trattamento `181-186`. |
| 9 | Tab Adozione, Spese, Documenti, Note, Altro | parziale | Dati reali su spese/note/documenti/richieste. **Manca / segnaposto:** iter a 5 tappe **statico**, non legato alla richiesta (`dog_adozione_tab.dart:103-137`); tab Altro: Box, Referente, PDF, Trasferisci, Archivia = toast (`dog_altro_tab.dart:90-177`); «Carica documento» sulla tab Documenti **non sceglie un file** (`add_document_sheet.dart:81-95`: salva solo nome/tipo, `contenutoB64: null`). |
| 9-bis | Home / Dashboard | parziale | Layout e aggregatori: `home_page.dart:21-80`, `home_providers.dart:63-94`, `home_aggregators.dart`. Scorciatoie navigano (`home_page.dart:419-446`) ma Box e Statistiche aprono un **placeholder** (`router.dart:114-122`). Righe «Da fare oggi» **non hanno** `onTap` (`home_page.dart:489-541`). Banner offline **mai acceso**: `homeOfflineProvider` è `false` fisso (`home_providers.dart:37`). |
| 10 | Foto | parziale | `PhotoRepository` `data_repositories.dart:26-37`; upload/galleria/copertina/elimina/limite 20 in `dog_gallery_page.dart` e `firestore_repositories.dart:59-180`. **Manca:** «Usa per annuncio» = toast (`dog_gallery_page.dart:191-199`). Nessun controllo ruolo in galleria (**non trovato** `canWrite` nel file). Video: **non trovato** (corretto: fuori v1). |
| 11 | Wizard nuovo cane | completo | 3 passi `new_dog_wizard_page.dart:32-87`, `454`. Bozza `salvaBozzaKey` `468-471`. Scanner `mobile_scanner` `microchip_scan_page.dart:1-16`; dipendenza `pubspec.yaml:21`. |
| 12 | Stato del cane e storico | parziale | 7 stati in `enums.dart:71-78`; schermata `change_status_page.dart`; conferma adottato/deceduto `dog_stato.dart:18-20`. Storico in tab Altro `dog_altro_tab.dart:111-144`. **Manca:** stato `trasferito` (**non trovato** in `DogStato`); azione Trasferisci/Archivia = toast (`dog_altro_tab.dart:160-177`); **nessun** gate ruolo sulla pagina cambio stato (**non trovato** `canWrite` in `change_status_page.dart`). |
| 13 | Richieste di adozione | parziale | Elenco+filtri `adoptions_page.dart`; dettaglio+avanza/respingi `adoption_detail_page.dart:149-188`, `387-399`; collegamento cane `adoption_flow.dart` (file presente). Match adottante `new_adoption_page.dart:147-171`, `235-243`. **Manca:** schermata «Famiglie adottanti» (**non trovato**); Chiama/Email copiano negli appunti, non aprono telefono/mail (`adoption_detail_page.dart:91-101`, `315-331`). |
| 14 | Documenti di affido (Parte 3, non l’originale) | parziale | **Versione rivista presente:** niente `signature` in `pubspec.yaml`; template Firestore `ensureDefaults` `firestore_repositories.dart:521-538`; asset `pubspec.yaml:39-41`; «Invia modulo» + `share_plus` `affido_page.dart:290-332`; storico `modulo_inviato` via `recordModuloInviato`; chunk 600 KB / limite 10 MB `document_codec.dart:3-27`; proposta avanzamento preaffido `affido_page.dart:554-605`; Impostazioni «Sostituisci file» presidente `settings_page.dart:46-92`. **Manca dello Step 14:** coda offline dedicata (**non trovato**); Impostazioni sono **solo** moduli, non dati associazione (`settings_page.dart:19-26`, `57-98`); dalla tab Documenti del cane «Carica documento» non carica un file (`add_document_sheet.dart:81-95`). |
| 14-bis | Modifica profilo e voci | parziale | Modifica cane `/animali/:id/modifica` `router.dart:184-190`, `edit_dog_page.dart:31-45`; Salva disabilitato se identico `431-445`; guardia concorrente `289-343`; CRUD trattamenti/pesi/spese/note/documenti (nome)/sponsorship (chiudi) / appuntamenti. Test `test/features/dogs/step14_bis_test.dart`. **Manca / fatto male:** ⋮ scheda incompleto (`dog_detail_page.dart:138-155`); FAB «+» ancora toast per 5 voci su 6 (`new_item_sheet.dart:25-61`); calendario dello step è un **elenco**, non la vista mensile (`calendar_page.dart:16-23`); documento dalla tab cane: modifica solo il nome (`add_document_sheet.dart:78-79`, `113`); appuntamento senza `dogId`/`adoptionId`/`volontariIds` in form (`add_appointment_sheet.dart:118-129`); test 8 delle regole Firestore su note forzate: **non trovato** in `step14_bis_test.dart` (c’è solo `findsNothing` UI riga 416). |
| 15 | Calendario e scadenze | **non iniziato** | La rotta `/calendario` mostra `CalendarPage` elenco 14-bis (`router.dart:199-201`, `calendar_page.dart:16-23`). Griglia mensile a 6 righe, pallini, eventi del giorno, scadenze sanitarie → appuntamenti: **non trovato**. `CalendarPlaceholderPage` esiste ma **nessuna rotta** la usa (`calendar_placeholder_page.dart:5-17`; grep: solo quel file). |
| 16 | Box, settori, volontari e turni | **non iniziato** | Cartelle vuote `lib/features/boxes/.gitkeep`, `lib/features/volunteers/.gitkeep`. Rotta `/box` = placeholder `router.dart:114-117`, `placeholder_feature_page.dart:24-28`. Campo `boxes.tipo` (degenza/isolamento): **non trovato** (`shelter_box.dart:3-20`). UI iscrizione turno: **non trovato**. |
| 17 | Statistiche ed export | **non iniziato** | Rotta `/statistiche` = placeholder `router.dart:119-122`. `package:printing` e export CSV: **non trovato** in `lib/`. `pdf` usato solo per unire foto in PDF firmato (`affido_upload.dart:3-4`, `48-52`). |
| 17-bis | Menu Altro, Notifiche, Ricerca, azioni ⋮ | **non iniziato** | `AltroPage` ha 4 voci (Impostazioni, Aggiornamenti, Catalogo UI, Esci) `altro_page.dart:14-23`, `45-84`. Gruppi Gestione/Archivio/App della spec: **non trovato**. Schermata notifiche: **non trovato**. Ricerca globale: **non trovato**. Sheet 8 azioni: **non trovato** (⋮ ha 1 voce, vedi Step 7). |
| 18 | Ruoli, permessi e impostazioni | parziale | Regole `backend/firestore.rules:1-49` (inclusa iscrizione turno `25-35`). Gate UI parziale: `edit_permissions.dart:5-23`; note altrui nascoste `dog_note_tab.dart:70`; modifica cane bloccata `edit_dog_page.dart:405-416`; sostituisci modulo solo presidente `settings_page.dart:46`, `88-92`. **Buco:** `canWriteRecords(null) == true` (`edit_permissions.dart:6-8`) — se il doc `volunteers/{uid}` manca, i pulsanti di scrittura **compaiono**. Impostazioni associazione/notifiche/backup: **non trovato**. Test regole 3 ruoli completi: c’è solo `test/data/firestore_rules_appointments_test.dart:44-95`. |
| 19 | Offline, notifiche, rifinitura | parziale | Persistenza `enableFirestoreOffline` `firestore_repositories.dart:672-673`, chiamata da `firebase_auth_repository.dart:81`. Banner UI presente ma spento (`home_providers.dart:37`). `flutter_local_notifications`: **non trovato** in `pubspec.yaml`. Coda scritture custom: **non trovato**. |
| 20 | Build di rilascio e consegna | **non iniziato** | Keystore/firma: **non trovato** (`*.jks`/`*.keystore` assenti). README è 11 righe (`README.md:1-11`), niente istruzioni installazione volontari. Versione app `pubspec.yaml:4` = `1.0.5+7`, ma login stampa «Versione 1.0» (`login_page.dart:180-181`). |

### Cosa manca, per gli step parziali (elenco chiuso)

- **3:** checkbox «Resta collegato» inerte rispetto ad Auth; reset password = toast.
- **6:** bottom sheet filtri; esclusione archiviati dall’elenco.
- **7 / 17-bis:** Condividi header; menu ⋮ a 8 voci.
- **9:** iter dinamico; azioni tab Altro; upload file vero dalla tab Documenti.
- **9-bis:** tap sulle scadenze; banner offline vero; scorciatoie Box/Statistiche vere.
- **10:** «Usa per annuncio»; permessi in galleria.
- **12:** `trasferito`; archivia; permessi UI.
- **13:** archivio famiglie; Chiama/Email nativi.
- **14:** coda offline; Impostazioni complete; upload file dalla tab cane.
- **14-bis:** FAB; ⋮; calendario mensile (è dello Step 15); collegamento appuntamento-cane; test regole note.
- **18:** impostazioni associazione; nascondere azioni al volontario in modo coerente (`null` = permesso).
- **19:** rilevazione rete; notifiche locali.

---

## 2. Schermate esistenti

| Schermata | File | Rotta go_router | Raggiungibile dall’app |
|---|---|---|---|
| Login | `lib/features/auth/login_page.dart` | `/login` (`router.dart:91-93`) | sì (redirect se anonimo, `router.dart:78-82`) |
| Home | `lib/features/dashboard/home_page.dart` | `/` (`router.dart:151-154`) | sì (bottom nav) |
| Elenco cani | `lib/features/dogs/dogs_page.dart` | `/animali` (`router.dart:160-161`) | sì |
| Scheda cane | `lib/features/dogs/dog_detail_page.dart` | `/animali/:dogId` (`router.dart:163-168`) | sì (tap card elenco `dogs_page.dart:241`) |
| Galleria foto | `lib/features/dogs/dog_gallery_page.dart` | `/animali/:dogId/foto` (`router.dart:170-176`) | sì (foto copertina `dog_detail_page.dart:442`; tab Altro `dog_altro_tab.dart:75`) |
| Cambio stato | `lib/features/dogs/change_status_page.dart` | `/animali/:dogId/stato` (`router.dart:177-183`) | sì (tab Altro `dog_altro_tab.dart:84`) |
| Modifica cane | `lib/features/dogs/edit_dog_page.dart` | `/animali/:dogId/modifica` (`router.dart:184-190`) | sì (matita `dog_detail_page.dart:131-133`; ⋮ `149-151`) |
| Nuovo cane (wizard) | `lib/features/dogs/new_dog/new_dog_wizard_page.dart` | `/nuovo` (`router.dart:98-101`) | sì (FAB `new_item_sheet.dart:16-21`; scorciatoia home `home_page.dart:424`) |
| Scanner microchip | `lib/features/dogs/new_dog/microchip_scan_page.dart` | **nessuna** rotta go_router | sì, via `Navigator.push` da `microchip_scanner.dart:16` |
| Richieste di adozione | `lib/features/adoptions/adoptions_page.dart` | `/richieste` (`router.dart:123-125`) | sì (home `home_page.dart:375`; tab adozione) |
| Nuova richiesta | `lib/features/adoptions/new_adoption_page.dart` | `/richieste/nuova` (`router.dart:127-132`) | sì (`adoptions_page.dart:144-145`; tab adozione `dog_adozione_tab.dart:76-78`) |
| Dettaglio richiesta | `lib/features/adoptions/adoption_detail_page.dart` | `/richieste/:adoptionId` (`router.dart:133-139`) | sì (card elenco `adoptions_page.dart:203`; home `home_page.dart:732`) |
| Documenti di affido | `lib/features/affido/affido_page.dart` | `/affido` (`router.dart:102-108`) | sì (home `home_page.dart:431`; tab Documenti `dog_documenti_tab.dart:102`; dettaglio richiesta `adoption_detail_page.dart:651-655`) |
| Calendario (elenco) | `lib/features/calendar/calendar_page.dart` | `/calendario` (`router.dart:199-201`) | sì (bottom nav) |
| Calendario placeholder | `lib/features/calendar/calendar_placeholder_page.dart` | **nessuna** | **no** — file morto |
| Menu Altro | `lib/features/settings/altro_page.dart` | `/altro` (`router.dart:207-210`) | sì |
| Impostazioni (solo moduli) | `lib/features/settings/settings_page.dart` | `/impostazioni` (`router.dart:109-112`) | sì (`altro_page.dart:55`) |
| Box e settori (segnaposto) | `lib/features/dashboard/placeholder_feature_page.dart` | `/box` (`router.dart:114-117`) | sì, ma EmptyState «disponibile negli step successivi» (`placeholder_feature_page.dart:27`) |
| Statistiche (segnaposto) | stesso file | `/statistiche` (`router.dart:119-122`) | sì, stesso segnaposto |
| Catalogo UI | `lib/features/debug/debug_ui_page.dart` | `/debug/ui` (`router.dart:94-97`) | sì (`altro_page.dart:77`) — è debug, non una schermata operativa |
| Foglio aggiornamento APK | `lib/features/settings/update_sheet.dart` | nessuna rotta | sì, overlay da `app_update_listener.dart:12-14` |
| Bottom sheet «+» | `lib/features/shell/new_item_sheet.dart` | nessuna | sì, FAB `app_shell.dart:27` |
| Sheet trattamenti/peso/spesa/nota/documento/sponsorship/appuntamento | `lib/features/dogs/add_*.dart`, `lib/features/calendar/add_appointment_sheet.dart` | nessuna | sì, aperti dalle tab / calendario |

**File di feature senza schermata:** `lib/features/boxes/.gitkeep`, `lib/features/volunteers/.gitkeep`, `lib/features/stats/.gitkeep`, `lib/features/documents/.gitkeep`, `lib/features/photos/.gitkeep`.

**Schermate della spec §7 assenti come pagina (non trovato):** Box e settori vera; Volontari e turni; Statistiche; Ricerca globale; Notifiche; Famiglie adottanti; Veterinari e fornitori; Cani archiviati; filtri avanzati elenco; menu ⋮ completo.

---

## 3. Ogni elemento interattivo, schermata per schermata

### Login — `login_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Campo email | valida e manda a `signIn` | `73-81`, `199-221` | FUNZIONANTE |
| Campo password | idem | `83-105`, `199-221` | FUNZIONANTE |
| Icona mostra/nascondi password | toggla `_obscure` | `90-104` | FUNZIONANTE |
| Checkbox «Resta collegato» | cambia solo `_staySignedIn` | `111-124` | INERTE (non arriva ad Auth) |
| «Password dimenticata?» | toast | `143-147` | INERTE |
| «Accedi» | login Firebase | `175-177`, `199-221` | FUNZIONANTE |
| «Accedi con codice associazione» | — | **non trovato** | ASSENTE (scelta Parte 2 punto 14) |

### Home — `home_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Aggiungi il primo cane» (DB vuoto) | `push /nuovo` | `135-136`, `164-165` | FUNZIONANTE |
| «Vedi tutti ›» ultimi arrivi | `go /animali` | `365` | FUNZIONANTE |
| Card ultimo arrivo | `push` scheda cane | `621` | FUNZIONANTE |
| «n nuove ›» richieste | `push /richieste` | `375` | FUNZIONANTE |
| Riga richiesta | `push` dettaglio | `732` | FUNZIONANTE |
| Scorciatoia Nuovo cane | `/nuovo` | `424` | FUNZIONANTE |
| Scorciatoia Modulo affido | `/affido` | `431` | FUNZIONANTE |
| Scorciatoia Box | `/box` placeholder | `438` + `router.dart:114-117` | PARZIALE (naviga a segnaposto) |
| Scorciatoia Statistiche | `/statistiche` placeholder | `445` + `router.dart:119-122` | PARZIALE |
| Righe «Da fare oggi» | nessuna azione | `489-541` nessun `onTap` | INERTE |
| Card contatori | nessuna azione | `228-327` | INERTE (solo display) |

### Elenco cani — `dogs_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Campo ricerca | filtra nome/microchip/box | `104-114`, `dog_list_query.dart:37-48` | FUNZIONANTE |
| Segmenti Tutti/Rifugio/Stallo/Adottab./Cuccioli | cambiano filtro | `120-132` | FUNZIONANTE |
| «Filtri e ordina» | toast | `152-156` | INERTE |
| Card cane | apre scheda | `238-241` | FUNZIONANTE |
| Scroll fine lista | carica altri 20 | `198-204` | FUNZIONANTE |

### Scheda cane — header `dog_detail_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Indietro | pop o `/animali` | `124-129` | FUNZIONANTE |
| Matita | `/modifica` se `canWrite` | `131-133` | FUNZIONANTE (nascosta al volontario se volunteer caricato) |
| Condividi | toast «step successivi» | `134-137` | INERTE (mentre la tab Adozione condivide per davvero) |
| ⋮ | solo «Modifica scheda» | `138-155` | PARZIALE (7 voci spec 17-bis assenti) |
| Foto copertina | apre galleria | `440-442` | FUNZIONANTE |
| 7 tab | cambiano corpo | `262-271`, `572-578` | FUNZIONANTE |
| 4 StatTile | non cliccabili | `499-543` | INERTE |

**ASSENTE header:** cuore preferito (**non trovato**).

### Tab Scheda — `dog_scheda_tab.dart`

Nessun controllo toccabile: solo KeyValueRow. Stato: display da repository `41-49`.

### Tab Salute — `dog_salute_tab.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Aggiungi trattamento» | sheet create | `181-186` | FUNZIONANTE (se `canWrite`) |
| «Registra peso» | sheet create | `188-193` | FUNZIONANTE |
| ⋮ / long-press riga libretto | modifica/elimina con conferma | `322-370`, `268-286` | FUNZIONANTE |
| ⋮ / long-press pesata | modifica/elimina | `393-422`, `288-304` | FUNZIONANTE |
| Righe scadenze | nessuna azione | `200-251` | INERTE |

### Tab Adozione — `dog_adozione_tab.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Registra nuova richiesta» | `/richieste/nuova?dogId=` | `74-78` | FUNZIONANTE |
| Riga richiesta | dettaglio | `217-218` | FUNZIONANTE |
| «Condividi scheda» | clipboard + `Share` | `155-174`, `dog_share.dart:21-52` | FUNZIONANTE |
| Timeline 5 tappe | testo fisso | `103-137` | INERTE (non riflette lo stato reale) |

**ASSENTE:** contatore visualizzazioni (Parte 2 punto 11: da togliere).

### Tab Spese — `dog_spese_tab.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Registra spesa» | sheet | `258-262` | FUNZIONANTE |
| «Adozione a distanza» | sheet create | `265-268` | FUNZIONANTE |
| ⋮ spesa | modifica / elimina con conferma | `348-392`, `456-477` | FUNZIONANTE |
| ⋮ sponsorship | modifica / «Chiudi» (non delete) | `417-449`, `480-507` | FUNZIONANTE (chiude, come da spec 14-bis) |

### Tab Documenti — `dog_documenti_tab.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Invia modulo» | `/affido?dogId=` | `98-103` | FUNZIONANTE (poi serve una richiesta, `affido_page.dart:297-302`) |
| «Carica documento» | sheet nome/tipo **senza file** | `108-114`, `add_document_sheet.dart:81-95` | PARZIALE (crea metadati vuoti) |
| ⋮ documento | rinomina / elimina | `140-187`, `194-213` | PARZIALE (niente Apri/Condividi qui) |
| Tap riga | nessun open file | riga è `GestureDetector` solo `onLongPress` `140-147` | INERTE al tap |

### Tab Note — `dog_note_tab.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Aggiungi nota» | sheet, sempre visibile | `80-85` | FUNZIONANTE (anche volontario) |
| ⋮ nota | modifica/elimina se `canEditNote` | `70`, `112-157` | FUNZIONANTE |

### Tab Altro — `dog_altro_tab.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Galleria | `/foto` | `75` | FUNZIONANTE |
| Cambia stato | `/stato` | `84` | FUNZIONANTE |
| Box e collocazione | toast | `90-93` | INERTE |
| Volontario referente | toast | `102-105` | INERTE |
| Esporta PDF | toast | `155-158` | INERTE |
| Trasferisci | toast | `166-169` | INERTE |
| Archivia | toast | `175-178` | INERTE |

### Galleria — `dog_gallery_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Indietro | pop | `111-117` | FUNZIONANTE |
| Thumb | seleziona | `147` | FUNZIONANTE |
| Tessera aggiungi / area upload | sheet fotocamera/galleria | `149-150`, `240-247` | FUNZIONANTE |
| Elimina su thumb | `PhotoRepository.delete` | `148`, `337` | FUNZIONANTE |
| Imposta copertina | `setCover` | `180-186`, `326-331` | FUNZIONANTE |
| Usa per annuncio | toast | `191-199` | INERTE |

### Cambio stato — `change_status_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| 7 opzioni stato | selezionano `_selected` | contratto `35-37`; `optionKey` `61` | FUNZIONANTE |
| Data, motivazione, volontario | campi + sheet autore | contratto `40-45` | FUNZIONANTE |
| Salva | aggiorna cane + storico | file; toast `167` | FUNZIONANTE |
| Conferma adottato/deceduto | sheet | `dog_stato.dart:18-20` | FUNZIONANTE |

Nessun nascondimento per ruolo: **non trovato**.

### Modifica cane — `edit_dog_page.dart`

Campi anagrafica/identificazione/provenienza/presentazione/carattere/adozione: salvano su `DogRepository.save` `345-348`. Scanner microchip `391-401`. Salva attivo solo se dirty `431-445`. Back con conferma se dirty `365-381`. Box picker da `boxes` `517-524`. **FUNZIONANTE** per i campi del form. Peso non è in questa schermata (spec 14-bis: corretto; va in Salute).

### Wizard nuovo cane — `new_dog_wizard_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Salva bozza | persist draft | `468-471` | FUNZIONANTE |
| Avanti / Indietro / Crea profilo | validazione + submit | `563`, `870`, `929-934` | FUNZIONANTE |
| Scanner microchip | apre camera | step 1 contratto `52` | FUNZIONANTE |
| Test sanitari Leishmania/Filaria/Ehrlichia | lista fissa | `_testSanitari` riga `30` | PARZIALE (etichette hardcode, non da `vendors`) |

### Elenco richieste — `adoptions_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Segmenti filtro | filtrano | `97-107` | FUNZIONANTE |
| Card | dettaglio | `203` | FUNZIONANTE |
| «Registra richiesta» | `/richieste/nuova` | `140-145`, `158-163` | FUNZIONANTE |

### Nuova richiesta — `new_adoption_page.dart`

Campi richiedente + questionario; tap campo cane apre sheet elenco `174-194`; match famiglia `147-171`; Salva crea `adoptions` + `adopters` `197-279`. **FUNZIONANTE**. Archivio famiglie consultabile a parte: **ASSENTE**.

### Dettaglio richiesta — `adoption_detail_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Chiama | copia telefono | `315-321` | PARZIALE (non `tel:`) |
| Email | copia email | `327-331` | PARZIALE (non `mailto:`) |
| Card cane | apre scheda | `511` | FUNZIONANTE |
| «Modifica ›» questionario | sheet + save | `356-357`, `233-248` | FUNZIONANTE |
| Invia modulo | `/affido` | `646-655` | FUNZIONANTE |
| Documento ricevuto | stesso `/affido` | `668-683` | FUNZIONANTE (non apre il file in situ) |
| Respingi / Avanza | aggiorna adozione+cane | `387-399`, `149-188` | FUNZIONANTE |

### Documenti di affido — `affido_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Indietro | pop | `87-92` | FUNZIONANTE |
| Invia preaffido/adozione | share PDF + storico | `136-144`, `290-332` | FUNZIONANTE (se c’è richiesta) |
| Tap documento ricevuto | Apri / Condividi / Elimina | `184-186`, `335-372` | FUNZIONANTE |
| «Carica documento compilato» | picker + chunk + proposta preaffido | `193-201`, `554-605` | FUNZIONANTE |

### Calendario — `calendar_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| «Nuovo appuntamento» | sheet | `65-70` | FUNZIONANTE (CRUD elenco) |
| ⋮ / long-press | modifica/elimina | `96-144`, `152-165` | FUNZIONANTE |
| Griglia mese / giorno / scadenze auto | — | **non trovato** | ASSENTE (Step 15) |

### Altro — `altro_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Impostazioni | `/impostazioni` | `55` | FUNZIONANTE (pagina moduli) |
| Aggiornamenti | check GitHub | `64-68` | FUNZIONANTE (extra rispetto alla spec) |
| Catalogo UI | `/debug/ui` | `77` | FUNZIONANTE (debug) |
| Esci | `signOut` | `83` | FUNZIONANTE |
| Anagrafe, Richieste, Box, Volontari, Calendario, Documenti, Famiglie, Veterinari, Archiviati, Statistiche, Notifiche | — | **non trovato** | ASSENTE |

### Impostazioni — `settings_page.dart`

| Elemento | Cosa fa | Prova | Stato |
|---|---|---|---|
| Riga modulo (presidente) | sostituisce PDF, versione+1 | `88-91`, `103-132` | FUNZIONANTE |
| Riga modulo (altri ruoli) | `onTap: () {}` | `92` | INERTE |
| Dati associazione, notifiche, aspetto, backup, permessi | — | **non trovato** | ASSENTE |

### Placeholder Box / Statistiche — `placeholder_feature_page.dart`

Solo back `17-22` e EmptyState `25-28`. **INERTE** (segnaposto dichiarato).

### Catalogo UI — `debug_ui_page.dart`

Tutti i tap sono toast di demo (`45-46`, `190`, `260-269`). Non è prodotto. Dati finti nel catalogo es. `'B7 — settore B'` riga `80`.

### FAB «+» — `new_item_sheet.dart`

| Voce | Azione | Stato |
|---|---|---|
| Nuovo cane | `/nuovo` `16-21` | FUNZIONANTE |
| Richiesta / Trattamento / Spesa / Appuntamento / Foto rapida | `_soon` toast `25-61` | INERTE |

Le stesse azioni esistono altrove (richiesta da elenco, trattamento da tab, appuntamento da calendario): il FAB è rimasto allo Step 5.

### Bottom nav — `app_bottom_nav.dart`

Home / Animali / FAB / Calendario / Altro: `49-80` + `app_shell.dart:21-27`. **FUNZIONANTE**.

### Foglio aggiornamento — `update_sheet.dart`

Dopo / Installa: download APK GitHub. Extra-spec. **FUNZIONANTE** sul canale aggiornamenti.

---

## 4. Dati finti ancora nel codice

**TODO / FIXME in `lib/` e `test/`:** **non trovato** (grep `TODO|FIXME|XXX|HACK` a vuoto).

### Valori scritti a mano nelle schermate (dovrebbero venire dai dati)

| File:riga | Cosa mostra |
|---|---|
| `dog_adozione_tab.dart:112-133` | Cinque tappe dell’iter con testi fissi («Modulo online o in sede», ecc.), indipendenti da `adoptions` |
| `new_dog_wizard_page.dart:30` | `const _testSanitari = ['Leishmania', 'Filaria', 'Ehrlichia']` |
| `login_page.dart:180-181` | «Versione 1.0» fisso (pubspec è `1.0.5+7`) |
| `home_providers.dart:37` | `homeOfflineProvider = false` — il banner non può mai accendersi dai dati rete |
| `debug_ui_page.dart:80` e seguenti | Esempi di design system (atteso per `/debug/ui`) |
| `new_item_sheet.dart:61` e tutti i toast «disponibile negli step successivi» | Segnaposto, non dati di anagrafe |

Il grafico peso **non** ha serie finta: legge `weights` (`dog_salute_tab.dart:62-64`, `147`).

### Seed `[PROVA]`

Presente. Prefisso nome `lib/data/seed/seed_ids.dart:5` `'[PROVA] '`; applicato in `seed_data.dart:278-279`. Slogan/note «DATI DI PROVA» `299-308`. Id `seed_*` `seed_ids.dart:2`, `seed_data.dart:278`.

**Come si rimuovono:** `deleteSeedData` in `seed_data.dart:102-118` cancella da `dogs`, `adoptions`, `adopters`, `volunteers` i documenti il cui id inizia con `seed_`. I 6 cani di collaudo sono `seed_fenice` ecc. (`278`). I cani veri del CSV non hanno quel prefisso. In UI il prefisso viene strippato solo con `dogDisplayName` (`dog_labels.dart:97-99`); l’elenco cani mostra `dog.nome` grezzo (`dog_list_tile.dart:61-63`), quindi **`[PROVA] Fenice` resta visibile in lista**.

Nessuna voce di menu dell’app chiama `deleteSeedData` (**non trovato** in `lib/features`).

---

## 5. Modello dati: cosa si usa davvero

| Collezione | Lettura UI/repo | Scrittura | Prove |
|---|---|---|---|
| `dogs` | sì | sì (save, no delete) | `firestore_repositories.dart:37-56`; wizard/edit/stato/adozione |
| `photos` + `photos/*/full` | sì | sì (upload, setCover, delete) | `64-180` |
| `health` | sì | sì + delete | `197-223`; tab Salute |
| `weights` | sì | sì + delete (aggiorna `dogs.pesoKg`) | `234-277` |
| `expenses` | sì | sì + delete | `317-334`; tab Spese |
| `sponsorships` | sì | sì (save; **niente delete** nell’interfaccia repo) | `data_repositories.dart:52-55`; `firestore_repositories.dart:285-308`; UI chiude `dog_spese_tab.dart:500-506` |
| `adopters` | sì (nuova richiesta) | sì in creazione richiesta | `338-361`; `new_adoption_page.dart:209-279`. Nessuna schermata elenco. |
| `adoptions` | sì | sì (no delete repo) | `371-388` |
| `templates` | sì | sì (seed + sostituisci) | `494-538`; `settings_page.dart:121-128` |
| `documents` + `chunks` | sì | sì + delete | `396-484`; affido e tab cane |
| `notes` | sì | sì + delete | `557-573` |
| `appointments` | sì (home aggregatore + calendario elenco) | sì + delete | `583-600`; `calendar_page.dart`; home `home_providers.dart:21-26` |
| `volunteers` | sì (nome, referente, ruoli) | sì nel repo, **solo seed in pratica** | `610-627`; UI salvataggio volontario: **non trovato** |
| `boxes` | sì (occupazione home, picker wizard/edit) | sì nel repo, **solo seed** | `637-646`; `home_providers.dart:13-18`. Schermata box: placeholder. |
| `settings/association` | repo `getAssociation` `658-664` | seed `seed_data.dart:81-90` | **Nessuna schermata legge** `settingsRepositoryProvider` in `lib/features` (**non trovato** uso UI) |
| `dogDrafts/{uid}` | wizard bozza | sì | `new_dog_draft_store.dart:34`; rules `firestore.rules:43-45` |
| `vendors` | — | — | **non trovato** (Parte 2 punto 5 non fatto) |

### Campi spec che nessuna schermata di consultazione mostra

(il wizard/modifica li **scrivono**, la scheda **non li espone**)

| Campo | Nel modello | In scheda/elenco |
|---|---|---|
| `mantello` | `dog.dart:84` | solo form (`edit_dog_page.dart:485`) — **non trovato** in `dog_detail_page` / tab Scheda |
| `iscrittoAnagrafe` | `86` | solo form |
| `modalitaIngresso` | `88` | solo form / picker |
| `dataSterilizzazione` | `96` | wizard `698`; in scheda c’è solo sì/no sterilizzato (`dog_detail_page.dart:517-520`) |
| `settore`+`box` | `90-91` | tab Altro come sottotitolo `56-61`, non in hero |
| `nascitaPresunta` | `80` | entra nell’età (`dogAgeDetailLabel`), non come riga propria |
| `archiviato` | `109` | **non trovato** in UI; elenco non filtra (`dog_list_query.dart:64`) |
| `audit` cane | `111` | solo fondo modifica `edit_dog_page.dart` `ultimaModificaKey` |
| `health.lotto` | tab Salute subtitle `dog_salute_tab.dart:260` | visibile se valorizzato |
| `adopters.affidabilita`, `dataNascita`, `note` | modello | **non trovato** in UI (solo snapshot `richiedente`) |
| `appointments.dogId`, `adoptionId`, `volontariIds`, `stato`, `tuttoIlGiorno`, `fine` | modello; create a `null`/vuoto/`previsto` `add_appointment_sheet.dart:123-130` | **non mostrati** nell’elenco (`calendar_page.dart:92-95` solo titolo/data/luogo) |
| `settings.*` | modello | **non mostrati** |
| `boxes.note`, `inManutenzione` | modello | usati negli aggregatori home, non in una griglia |
| `stato` `trasferito` / `storicoStati.strutturaDestinazione` | **non trovato** | — |
| `boxes.tipo` | **non trovato** | — |
| `vendors.*` | **non trovato** | — |
| `volunteers.preferitiIds` | **non trovato** | — |

---

## 6. Creare, leggere, modificare, eliminare

Verifica Step 14-bis. «Sì» solo se c’è codice di UI o repository **chiamato dalla UI**.

| Entità | Creare? | Vedere? | Modificare? | Eliminare? |
|---|---|---|---|---|
| Cane | **Sì** wizard `new_dog_submit.dart` + rotta `/nuovo` | **Sì** elenco e scheda | **Sì** `EditDogPage` `345-348` | **No** — `DogRepository` non ha `delete` (`data_repositories.dart:20-24`); Archivia = toast `dog_altro_tab.dart:175-178` |
| Trattamento sanitario | **Sì** `AddTreatmentSheet` `dog_salute_tab.dart:185` | **Sì** libretto/scadenze | **Sì** sheet `existing:` `129-132` | **Sì** con conferma `268-286` |
| Pesata | **Sì** `AddWeightSheet` `192` | **Sì** grafico + lista `147-174` | **Sì** `168-171` | **Sì** `288-304` |
| Spesa | **Sì** `AddExpenseSheet` `262` | **Sì** tab Spese | **Sì** `185-188` | **Sì** `456-477`. Spesa generale `dogId == null`: repo la supporta `firestore_repositories.dart:316-320`, UI **non trovato** |
| Nota | **Sì** `AddNoteSheet` `84` | **Sì** | **Sì** se autore o presidente/referente `canEditNote` `edit_permissions.dart:14-22` | **Sì** stesse regole `178-194` |
| Documento | **Parziale** affido carica file `affido_page.dart:193-201`; tab cane crea **solo metadati** `add_document_sheet.dart:81-95` | **Sì** tab + affido + scheda richiesta | **Solo nome** dalla tab cane `78-79`; affido non rinomina | **Sì** tab `194-213` e affido `414-446` con conferma |
| Foto | **Sì** galleria upload | **Sì** thumb/full | copertina **Sì** `setCover`; contenuto foto **No** (si elimina e si ricarica) | **Sì** `dog_gallery_page.dart:337` |
| Richiesta di adozione | **Sì** `NewAdoptionPage` | **Sì** elenco/dettaglio | questionario **Sì**; iter avanza/respingi **Sì**; anagrafica richiedente dopo il salvataggio: **non trovato** form di modifica | **No** — `AdoptionRepository` senza `delete` (`data_repositories.dart:69-73`) |
| Adozione a distanza | **Sì** `AddSponsorshipSheet` | **Sì** tab Spese | **Sì** `243-246` | **No** (si chiude) `480-507`; repo senza `delete` `data_repositories.dart:52-55` |
| Appuntamento | **Sì** calendario `65-70` | **Sì** elenco (non mese) | **Sì** sheet | **Sì** `152-165`. Iscrizione turno volontario: rules sì `firestore.rules:25-35`, UI **non trovato** |
| Box | **No** in app (solo seed `seed_data.dart:72-73`) | **Parziale** numeri home + picker testo in form; pagina = placeholder | save repo esiste `645-646`, UI **non trovato** | **No** (niente `delete` su `BoxRepository` `114-117`) |
| Volontario | **No** in app (seed `66-68`) | **Parziale** nome in home/referente/cambio stato | save repo `627`, UI **non trovato** | **No** |

**Permessi 14-bis.3:** presidente/referente vedono i ⋮ su salute/spese/documenti/calendario (`canWriteRecords`). Volontario: note proprie sì, resto dei ⋮ no. Se `currentVolunteerProvider` è `null` (uid non in `volunteers`), `canWriteRecords` torna **true** (`edit_permissions.dart:6-8`) e i pulsanti **compaiono**. Galleria e cambio stato **non** usano quel gate.

---

## 7. Test

**Esecuzione di questo rapporto**

- `flutter analyze`: `No issues found! (ran in 14.0s)`
- `flutter test`: `All tests passed!` — **200** test (contatore finale `+200`)

**File `*_test.dart` (esclusi helper)**

| Area | File |
|---|---|
| Smoke | `test/widget_test.dart` |
| Auth | `test/features/auth/login_page_test.dart`, `test/data/auth_session_test.dart`, `test/data/auth_errors_test.dart` |
| UI overflow | `test/ui/debug_ui_overflow_test.dart`, `login_overflow_test.dart`, `components_tokens_test.dart`, `app_sheet_inset_test.dart` |
| Shell | `test/features/shell/shell_navigation_test.dart`, `test/core/app_navigation_test.dart` |
| Cani | `dogs_page_test`, `dog_list_query_test`, `dog_detail_page_test`, `dog_scheda_salute_test`, `dog_rest_tabs_test`, `dog_gallery_page_test`, `new_dog_wizard_test`, `new_dog_validation_test`, `change_status_page_test`, `dog_stato_test`, `dog_labels_test`, `scadenze_test`, `peso_chart_test`, `spese_math_test`, `step14_bis_test` |
| Home | `home_page_test`, `home_aggregators_test` |
| Adozioni | `adoptions_page_test`, `adoption_filters_test`, `adoption_flow_test` |
| Affido Step 14 | `test/features/affido/step14_test.dart` |
| Dati | `models_roundtrip_test`, `repositories_seed_test`, `photo_codec_test`, `lru_bytes_cache_test`, `firestore_rules_appointments_test` |
| Aggiornamenti | `github_release_test` |
| Golden | `test/golden/home_golden_test.dart`, `dogs_list_golden_test.dart`, `dog_detail_golden_test.dart` |

Helper (non sono test): `test/helpers/*`.

**Step senza file di test dedicato**

| Step | Copertura |
|---|---|
| 15, 16, 17, 17-bis, 19, 20 | **non trovato** file di test |
| 18 | solo regole appointments, non i 3 ruoli completi |
| 14 test 9 (offline coda) | **non trovato** in `step14_test.dart` |
| 14-bis test 8 parte regole Firestore note | **non trovato** |

Screenshot PNG in `test/screenshots/` (`modifica_cane_360.png`, `affido_360.png`, ecc.) **non** sono test eseguibili (nessun `*_test.dart` in quella cartella).

### Golden

| File | PNG | Bloccato? |
|---|---|---|
| `test/golden/home_golden_test.dart:9-16` | `test/golden/goldens/home_360.png` | **Sì** — `skipUntilPng` è falso se il PNG esiste (`golden_support.dart:17-24`); il test **è stato eseguito** nel run (riga output «Home — aspetto bloccato») |
| `dogs_list_golden_test.dart` | `dogs_list_360.png` | **Sì** (stessa logica). Cartella `test/golden/failures/` con diff elenco: residuo di un confronto precedente, non uno skip |
| `dog_detail_golden_test.dart` | `dog_detail_360.png` | **Sì** |

Commento nel supporto: i PNG si creano solo con `--update-goldens` dopo ok visivo (`golden_support.dart:16`).

---

## 8. Le dieci cose più importanti da sistemare

In ordine di gravità. Categoria: **manca uno step** / **fatto male o a metà** / **non era previsto**.

1. **FAB «+» e tab Altro sono ancora toast, mentre le stesse azioni esistono già altrove** — *fatto male o a metà.* Il volontario che preme + per una spesa o un appuntamento riceve «step successivi» (`new_item_sheet.dart:25-61`) anche se tab Spese e calendario li fanno. Tab Altro promette PDF, box, archivia e mente (`dog_altro_tab.dart:90-177`). È il tipo di bug che fa credere che l’app sia rotta.

2. **Step 15-17 e 17-bis non iniziati, ma le scorciatoie e la voce Calendario ci sono già** — *manca uno step.* Home manda a Box/Statistiche placeholder (`router.dart:114-122`). Calendario è un elenco CRUD spacciato da shell (`calendar_page.dart:16-23`), non la griglia mensile né le scadenze come eventi. Menu Altro non è il menu 25 (`altro_page.dart:14-23`).

3. **«Carica documento» sulla scheda cane non carica un documento** — *fatto male o a metà.* Crea un record con `mime: application/pdf` e `contenutoB64: null` (`add_document_sheet.dart:81-95`). L’upload vero è solo su Affido. Si riempie Firestore di finti PDF.

4. **I permessi UI si autodistruggono se manca il documento volontario** — *non era previsto* come buco, ed è più grave dello Step 18 incompleto. `canWriteRecords(null) => true` (`edit_permissions.dart:6-8`). Galleria e cambio stato non controllano il ruolo. Un account Auth senza riga in `volunteers` vede matita, ⋮, elimina — poi Firestore rifiuta in silenzio o, in emulatore/test, scrive.

5. **Condividi nell’header è un toast; Condividi in tab Adozione funziona** — *fatto male o a metà.* `dog_detail_page.dart:134-137` vs `dog_adozione_tab.dart:155-174`. Due pulsanti, due verità.

6. **Elenco cani mescola vivi e archiviati; Archivia non fa nulla** — *non era previsto* dal piano originale (archivio è 17-bis) **e** è già contraddetto dai dati: il CSV marca adottati/deceduti `archiviato: true` (`cani_csv_parser.dart:155`) ma `filterDogs` non lo guarda (`dog_list_query.dart:64`). L’anagrafe vera è sporca il giorno uno.

7. **Offline della Home è un falso** — *fatto male o a metà.* Il banner c’è (`home_page.dart:107-127`) ma `homeOfflineProvider` è `false` costante (`home_providers.dart:37`). Step 14 test 9 (coda caricamenti) **non trovato**. Persistenza Firestore è accesa (`firestore_repositories.dart:672-673`) e basta.

8. **Seed `[PROVA]` ancora nell’anagrafe e visibile in lista** — *fatto male o a metà* rispetto all’uso reale. Rimozione solo via `deleteSeedData` (`seed_data.dart:102-118`), **non trovato** pulsante in app. L’elenco non usa `dogDisplayName` (`dog_list_tile.dart:61-63`).

9. **Impostazioni e dati associazione non esistono come prodotto** — *manca uno step* (18) con un pezzo dello 14 già innestato. Solo «Moduli» (`settings_page.dart:57-98`). `settings/association` si scrive nello seed e **nessuna schermata lo legge**. Backup, export, report PDF, CSV: **non trovato**.

10. **Collezioni e schermate che la Parte 2 ha già deciso e nessuno ha ancora toccato** — *non era previsto dal piano a 20 step, ma è già debito vincolante.* `vendors` **non trovato**; `trasferito` **non trovato**; `boxes.tipo` **non trovato**; famiglie adottanti senza pagina; Chiama/Email non chiamano; iter adozione disegnato a mano; appuntamenti senza cane e senza iscrizione turno in UI nonostante le rules. Sono i buchi che ricompariranno come «manca un pezzo» a ogni step futuro.

---

Fine del rapporto. Nessuna modifica al codice è stata fatta.
