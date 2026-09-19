import { readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const PROJECT_ID = 'amici-per-la-coda';
const CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const nowIso = () => new Date().toISOString();

const scriptDir = dirname(fileURLToPath(import.meta.url));
const csvPath = join(scriptDir, 'cani.csv');

function loadAdc() {
  const toolsPath = join(
    process.env.USERPROFILE || process.env.HOME,
    '.config',
    'configstore',
    'firebase-tools.json',
  );
  const tools = JSON.parse(readFileSync(toolsPath, 'utf8'));
  const refreshToken = tools?.tokens?.refresh_token;
  if (!refreshToken) {
    throw new Error('Nessun refresh token Firebase CLI. Esegui firebase login.');
  }
  const adcPath = join(tmpdir(), `amici-adc-${process.pid}.json`);
  writeFileSync(
    adcPath,
    JSON.stringify({
      type: 'authorized_user',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refreshToken,
    }),
  );
  return adcPath;
}

function parseCsv(raw) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  const endField = () => {
    row.push(field);
    field = '';
  };
  const endRow = () => {
    endField();
    if (row.some((cell) => cell.trim() !== '')) {
      rows.push(row);
    }
    row = [];
  };
  for (let i = 0; i < raw.length; i++) {
    const char = raw[i];
    if (inQuotes) {
      if (char === '"') {
        if (i + 1 < raw.length && raw[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += char;
      }
    } else if (char === '"') {
      inQuotes = true;
    } else if (char === ',') {
      endField();
    } else if (char === '\n') {
      endRow();
    } else if (char !== '\r') {
      field += char;
    }
  }
  if (field !== '' || row.length > 0) {
    endRow();
  }
  return rows;
}

function slugDogId(nome) {
  const map = {
    à: 'a',
    á: 'a',
    è: 'e',
    é: 'e',
    ì: 'i',
    í: 'i',
    ò: 'o',
    ó: 'o',
    ù: 'u',
    ú: 'u',
    ä: 'a',
    ö: 'o',
    ü: 'u',
    ç: 'c',
    ñ: 'n',
  };
  let out = '';
  for (const char of nome.toLowerCase()) {
    out += map[char] ?? char;
  }
  return out.replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

function parseDate(raw) {
  if (!raw) {
    return null;
  }
  const parts = raw.split('/');
  if (parts.length !== 3) {
    return null;
  }
  const day = Number(parts[0]);
  const month = Number(parts[1]);
  const year = Number(parts[2]);
  if (!Number.isInteger(day) || !Number.isInteger(month) || !Number.isInteger(year)) {
    return null;
  }
  return new Date(Date.UTC(year, month - 1, day));
}

function parseSiNo(raw) {
  switch (raw.toUpperCase()) {
    case 'SI':
    case 'SÌ':
    case 'YES':
    case 'TRUE':
      return true;
    case 'NO':
    case 'FALSE':
      return false;
    default:
      return null;
  }
}

function parseDouble(raw) {
  if (!raw) {
    return null;
  }
  const value = Number(raw.replace(',', '.'));
  return Number.isFinite(value) ? value : null;
}

function ts(date) {
  return date ? Timestamp.fromDate(date) : null;
}

function dogsFromCsv(auditAt) {
  const rows = parseCsv(readFileSync(csvPath, 'utf8'));
  if (rows.length < 2) {
    throw new Error('cani.csv vuoto o senza righe dati.');
  }
  const header = rows[0];
  const dogs = [];
  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    const cell = (name) => {
      const index = header.indexOf(name);
      if (index < 0 || index >= row.length) {
        return '';
      }
      return row[index].trim();
    };
    const nome = cell('nome');
    if (!nome) {
      continue;
    }
    const sessoRaw = cell('sesso');
    const dataNascita = parseDate(cell('dataNascita'));
    const nascitaPresuntaRaw = cell('nascitaPresunta');
    const sterilizzato = parseSiNo(cell('sterilizzato')) ?? false;
    const provenienza = cell('provenienza');
    const noteCsv = cell('note');
    const noteCarattereCsv = cell('noteCarattere');
    const fromStigliano = provenienza.toLowerCase().includes('stigliano');
    const nascitaPresunta =
      dataNascita == null ? true : nascitaPresuntaRaw.toUpperCase() === 'SI';
    const dataIngresso =
      parseDate(cell('dataIngresso')) ?? dataNascita ?? new Date(Date.UTC(2020, 0, 1));
    const stato = cell('stato') || 'in_rifugio';
    const pubblicato = parseSiNo(cell('pubblicato')) ?? false;
    const noteParts = [
      noteCarattereCsv,
      noteCsv,
      sessoRaw ? '' : 'Sesso da rilevare.',
      dataNascita ? '' : 'Data di nascita da rilevare.',
      cell('dataIngresso') ? '' : 'Data di ingresso da rilevare.',
    ].filter(Boolean);
    const taglia = cell('taglia') || 'media';
    const iscrittoAnagrafe = cell('iscrittoAnagrafe') || 'da_verificare';
    const modalitaIngresso = cell('modalitaIngresso')
      ? cell('modalitaIngresso')
      : fromStigliano
        ? 'trasferimento'
        : 'vagante';
    const carattere = cell('carattere')
      .split(/[;|]/)
      .map((item) => item.trim())
      .filter(Boolean);

    dogs.push({
      id: slugDogId(nome),
      data: {
        nome,
        sesso: sessoRaw || 'M',
        dataNascita: ts(dataNascita),
        nascitaPresunta,
        razza: cell('razza') || 'Meticcia',
        taglia,
        pesoKg: parseDouble(cell('pesoKg')),
        mantello: cell('mantello'),
        microchip: cell('microchip'),
        iscrittoAnagrafe,
        provenienza,
        modalitaIngresso,
        dataIngresso: ts(dataIngresso),
        settore: cell('settore'),
        box: cell('box'),
        stato,
        statoDal: ts(parseDate(cell('statoDal')) ?? dataIngresso),
        adottabile: parseSiNo(cell('adottabile')) ?? false,
        sterilizzato,
        dataSterilizzazione: ts(parseDate(cell('dataSterilizzazione'))),
        slogan: cell('slogan'),
        descrizione: cell('descrizione'),
        carattere,
        conPersone: cell('conPersone') || 'selettivo',
        conCani: cell('conCani') || 'da_testare',
        conGatti: cell('conGatti') || 'da_testare',
        conBambini: cell('conBambini') || 'da_testare',
        noteCarattere: noteParts.join(' '),
        fotoCopertinaId: null,
        referenteId: null,
        pubblicato,
        dataPubblicazione: pubblicato ? ts(dataIngresso) : null,
        archiviato: stato === 'adottato' || stato === 'deceduto',
        storicoStati: [
          {
            stato,
            dal: ts(dataIngresso),
            note: 'Anagrafe CSV',
            autoreId: 'csv_import',
            strutturaDestinazione: null,
          },
        ],
        createdAt: ts(auditAt),
        createdBy: 'csv_import',
        updatedAt: ts(auditAt),
        updatedBy: 'csv_import',
      },
    });
  }
  const ids = dogs.map((dog) => dog.id);
  if (new Set(ids).size !== ids.length) {
    throw new Error(`Id duplicati nel CSV: ${ids.join(', ')}`);
  }
  return dogs;
}

async function deleteDocs(col, predicate) {
  const snap = await col.get();
  let deleted = 0;
  for (const doc of snap.docs) {
    if (predicate && !predicate(doc)) {
      continue;
    }
    await col.firestore.recursiveDelete(doc.ref);
    deleted += 1;
  }
  return { scanned: snap.size, deleted };
}

function dogIdOf(doc) {
  const value = doc.get('dogId');
  return typeof value === 'string' ? value : '';
}

async function main() {
  const adcPath = loadAdc();
  process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
  process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;
  initializeApp({
    credential: applicationDefault(),
    projectId: PROJECT_ID,
  });
  const db = getFirestore();

  try {
    const incoming = dogsFromCsv(new Date());
    console.log(`[${nowIso()}] CSV: ${incoming.length} cani da ${csvPath}`);

    const before = await db.collection('dogs').get();
    console.log(`[${nowIso()}] Firestore cani attuali: ${before.size}`);
    for (const doc of before.docs) {
      const nome = doc.get('nome') ?? '';
      const stato = doc.get('stato') ?? '';
      console.log(`  - ${doc.id} | ${nome} | ${stato}`);
    }

    const report = {};
    report.photos = await deleteDocs(db.collection('photos'));
    report.health = await deleteDocs(db.collection('health'));
    report.weights = await deleteDocs(db.collection('weights'));
    report.notes = await deleteDocs(db.collection('notes'));
    report.sponsorships = await deleteDocs(db.collection('sponsorships'));
    report.dogDrafts = await deleteDocs(db.collection('dogDrafts'));
    report.expenses = await deleteDocs(
      db.collection('expenses'),
      (doc) => Boolean(dogIdOf(doc)),
    );
    report.documents = await deleteDocs(
      db.collection('documents'),
      (doc) => Boolean(dogIdOf(doc)),
    );
    report.appointments = await deleteDocs(
      db.collection('appointments'),
      (doc) => Boolean(dogIdOf(doc)),
    );
    report.adoptions = await deleteDocs(db.collection('adoptions'));
    report.adopters = await deleteDocs(
      db.collection('adopters'),
      (doc) => doc.id.startsWith('seed_'),
    );
    report.dogs = await deleteDocs(db.collection('dogs'));

    console.log(`[${nowIso()}] Cancellazioni:`, report);

    const batchSize = 400;
    for (let i = 0; i < incoming.length; i += batchSize) {
      const batch = db.batch();
      const slice = incoming.slice(i, i + batchSize);
      for (const dog of slice) {
        batch.set(db.collection('dogs').doc(dog.id), dog.data);
      }
      await batch.commit();
    }

    const after = await db.collection('dogs').get();
    const names = after.docs
      .map((doc) => `${doc.id}:${doc.get('nome')}`)
      .sort();
    console.log(`[${nowIso()}] Inseriti ${after.size} cani:`);
    for (const line of names) {
      console.log(`  - ${line}`);
    }
    if (after.size !== incoming.length) {
      throw new Error(
        `Attesi ${incoming.length} cani, trovati ${after.size} dopo l'insert.`,
      );
    }
    const leftoverSeed = after.docs.filter((doc) => doc.id.startsWith('seed_'));
    if (leftoverSeed.length > 0) {
      throw new Error(`Sono rimasti cani seed_: ${leftoverSeed.map((d) => d.id).join(', ')}`);
    }
    console.log(`[${nowIso()}] Completato.`);
  } finally {
    try {
      unlinkSync(adcPath);
    } catch {
      // ignore
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
