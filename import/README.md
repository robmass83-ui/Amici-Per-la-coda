# Cartella `import/` — dati iniziali per l'app

| File | Contenuto | Righe |
|---|---|---|
| `cani_rifugio.csv` | i 49 cani presenti in rifugio (dal PDF di Corleto e Stigliano) | 49 |
| `cani_facebook.csv` | i 106 cani degli album Facebook | 106 |
| `foto_facebook.csv` | ogni foto da importare: file, cane, cane nell'app, copertina, ordine | 267 |

Le foto stanno in `C:\Users\masal\Downloads\Amici per la coda facebook\Foto_cani_Facebook`.
La sottocartella `foto_di_gruppo` **non si importa**: sono foto con più cani.

## Colonna `azione` di `cani_facebook.csv`

- `crea` (98 cani) — nuovo profilo con nome, stato, archiviato, data, descrizione e una nota
  con la provenienza Facebook; poi le sue foto.
- `solo_foto` (8 cani: Aramis, Diana, Duca, Flora, Max, Mirtillo, Molly, Totò) — il cane
  **esiste già** fra i 49 (colonna `caneEsistente`): si aggiungono **solo le foto**, niente
  altro. Nessun nuovo profilo.

Stati già tradotti nei valori dell'app: `adottato` + `archiviato=SI` per gli adottati;
`in_rifugio` per adozioni a distanza e da verificare.
