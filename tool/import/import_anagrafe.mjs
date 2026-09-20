#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  ANAGRAFE_AUTHOR,
  EXPECTED_DOGS,
  anagrafeDirOf,
  buildAnagrafePlan,
  formatEmptyReport,
  keepIfIncomingEmpty,
  loadAnagrafeBundle,
  parseItalianNoonUtc,
  slugDogId,
} from './anagrafe.mjs';

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'amici-per-la-coda';
const CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function parseArgs(argv) {
  const flags = new Set();
  const values = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--dir') {
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        throw new Error('--dir richiede un percorso');
      }
      values.dir = next;
      i += 1;
    } else if (arg.startsWith('--')) {
      flags.add(arg.slice(2));
    }
  }
  return { flags, values };
}

function usage() {
  return `Uso:
  node import_anagrafe.mjs --dry-run
  node import_anagrafe.mjs

Idempotente sul microchip. Cella vuota = null, non false.
Date a mezzogiorno UTC. Non cancella i cani già in archivio.
`;
}

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

async function initFirestore() {
  const { initializeApp, cert, getApps, applicationDefault } = await import(
    'firebase-admin/app'
  );
  const { getFirestore, Timestamp } = await import('firebase-admin/firestore');
  const saPath = join(SCRIPT_DIR, 'serviceAccount.json');
  let adcPath = null;
  if (existsSync(saPath)) {
    const sa = JSON.parse(readFileSync(saPath, 'utf8'));
    if (getApps().length === 0) {
      initializeApp({ credential: cert(sa) });
    }
  } else {
    adcPath = loadAdc();
    process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
    process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;
    if (getApps().length === 0) {
      initializeApp({
        credential: applicationDefault(),
        projectId: PROJECT_ID,
      });
    }
  }
  return { db: getFirestore(), Timestamp, adcPath };
}

function ts(Timestamp, date) {
  return date ? Timestamp.fromDate(date) : null;
}

function dogPayload(plan, Timestamp, now, existing) {
  const keep = (incoming, field) =>
    keepIfIncomingEmpty(incoming, existing ? existing[field] : incoming);
  const dataIngresso = ts(Timestamp, plan.dataIngresso);
  const statoDal = ts(Timestamp, plan.statoDal);
  const sterilizzato = keep(plan.sterilizzato, 'sterilizzato');
  const adottabile = keep(plan.adottabile, 'adottabile');
  const payload = {
    nome: plan.nome,
    sesso: plan.sesso,
    dataNascita: ts(Timestamp, plan.dataNascita),
    nascitaPresunta: plan.nascitaPresunta,
    razza: plan.razza,
    taglia: plan.taglia,
    pesoKg: keep(plan.pesoKg, 'pesoKg'),
    mantello: plan.mantello,
    microchip: plan.microchip,
    iscrittoAnagrafe: plan.iscrittoAnagrafe,
    provenienza: plan.provenienza,
    modalitaIngresso: keep(plan.modalitaIngresso, 'modalitaIngresso'),
    dataIngresso,
    settore: keep(plan.settore, 'settore') ?? '',
    box: keep(plan.box, 'box') ?? '',
    stato: existing?.stato || plan.stato,
    statoDal: existing?.statoDal || statoDal,
    adottabile,
    sterilizzato,
    dataSterilizzazione: ts(Timestamp, plan.dataSterilizzazione),
    patologie: keep(plan.patologie, 'patologie') ?? '',
    slogan: keep(plan.slogan, 'slogan') ?? '',
    descrizione: keep(plan.descrizione, 'descrizione') ?? '',
    carattere: keep(plan.carattere, 'carattere') ?? [],
    conPersone: keep(plan.conPersone, 'conPersone'),
    conCani: plan.conCani,
    conGatti: plan.conGatti,
    conBambini: plan.conBambini,
    noteCarattere: plan.noteCarattere,
    fotoCopertinaId: existing?.fotoCopertinaId ?? null,
    fotoCount: existing?.fotoCount ?? 0,
    referenteId: existing?.referenteId ?? null,
    pubblicato: existing?.pubblicato === true ? true : plan.pubblicato,
    dataPubblicazione: existing?.dataPubblicazione ?? null,
    archiviato: existing?.archiviato ?? false,
    tipoPelo: plan.tipoPelo,
    purezza: plan.purezza,
    dataApplicazioneChip: ts(Timestamp, plan.dataApplicazioneChip),
    zonaApplicazioneChip: plan.zonaApplicazioneChip,
    veterinarioApplicatore: plan.veterinarioApplicatore,
    dataIscrizioneAnagrafe: ts(Timestamp, plan.dataIscrizioneAnagrafe),
    ultimaUbicazione: plan.ultimaUbicazione,
    dataIngressoStimata: plan.dataIngressoStimata,
    updatedAt: ts(Timestamp, now),
    updatedBy: ANAGRAFE_AUTHOR,
  };
  if (!existing) {
    payload.storicoStati = [
      {
        stato: plan.stato,
        dal: dataIngresso,
        note: 'Importato da anagrafe canina regionale',
        autoreId: ANAGRAFE_AUTHOR,
        strutturaDestinazione: null,
      },
    ];
    payload.createdAt = ts(Timestamp, now);
    payload.createdBy = ANAGRAFE_AUTHOR;
  } else if (Array.isArray(existing.storicoStati)) {
    payload.storicoStati = existing.storicoStati;
    payload.createdAt = existing.createdAt;
    payload.createdBy = existing.createdBy;
  }
  return payload;
}

function healthPayload(plan, dogId, Timestamp, now) {
  const row = plan.salute;
  const data = parseItalianNoonUtc(row.data);
  return {
    id: `chip_${plan.microchip}`,
    data: {
      dogId,
      tipo: row.tipo || 'altro',
      data: ts(Timestamp, data),
      descrizione: row.descrizione || 'Applicazione del microchip',
      veterinario: row.veterinario || '',
      lotto: row.lotto || '',
      prossimaScadenza: null,
      costo: null,
      createdAt: ts(Timestamp, now),
      createdBy: ANAGRAFE_AUTHOR,
      updatedAt: ts(Timestamp, now),
      updatedBy: ANAGRAFE_AUTHOR,
    },
  };
}

async function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (err) {
    console.error(err.message);
    console.error(usage());
    process.exit(1);
  }
  const dryRun = parsed.flags.has('dry-run') || parsed.flags.has('help');
  if (parsed.flags.has('help')) {
    console.log(usage());
    return;
  }
  const dir = anagrafeDirOf(parsed.values.dir);
  const bundle = loadAnagrafeBundle(dir);
  const plan = buildAnagrafePlan(bundle);
  if (plan.errors.length > 0) {
    for (const error of plan.errors) {
      console.error(error);
    }
    console.error('Nessuna scrittura: i cani importati non sono 39 o il file è incompleto.');
    process.exit(1);
  }
  if (plan.fotoRows.length > 0) {
    console.warn(`Foglio foto: ${plan.fotoRows.length} righe (nessuna foto da importare se manca il file).`);
  } else {
    console.log('Foglio foto: solo intestazioni, nessuna fotografia.');
  }

  console.log(`Letti ${plan.dogs.length} cani da ${dir}`);
  console.log(formatEmptyReport(plan.emptyCounts));

  if (dryRun) {
    console.log('\nDry-run: nessuna scrittura su Firestore.');
    console.log(`Cani da creare o aggiornare: ${plan.dogs.length}`);
    console.log(`Righe salute: ${plan.dogs.length}`);
    return;
  }

  const { db, Timestamp, adcPath } = await initFirestore();
  let created = 0;
  let updated = 0;
  const healthIds = [];
  try {
    const snap = await db.collection('dogs').get();
    const byChip = new Map();
    const bySlug = new Map();
    for (const doc of snap.docs) {
      const data = doc.data();
      const chip = typeof data.microchip === 'string' ? data.microchip.trim() : '';
      if (chip) {
        byChip.set(chip, { id: doc.id, ...data });
      }
      const slug = slugDogId(data.nome || doc.id);
      bySlug.set(slug, { id: doc.id, ...data });
      bySlug.set(doc.id, { id: doc.id, ...data });
    }

    const now = new Date();
    const writes = [];
    for (const dog of plan.dogs) {
      const existing =
        byChip.get(dog.microchip) ||
        bySlug.get(dog.slug) ||
        (dog.aliasSlug ? bySlug.get(dog.aliasSlug) : null) ||
        null;
      const id = existing?.id || dog.slug;
      if (existing) {
        updated += 1;
      } else {
        created += 1;
      }
      writes.push({
        ref: db.collection('dogs').doc(id),
        data: dogPayload(dog, Timestamp, now, existing),
      });
      const salute = healthPayload(dog, id, Timestamp, now);
      healthIds.push(salute.id);
      writes.push({
        ref: db.collection('health').doc(salute.id),
        data: salute.data,
      });
    }

    const batchSize = 400;
    for (let i = 0; i < writes.length; i += batchSize) {
      const batch = db.batch();
      for (const item of writes.slice(i, i + batchSize)) {
        batch.set(item.ref, item.data, { merge: true });
      }
      await batch.commit();
    }

    console.log(`\nCani creati: ${created}`);
    console.log(`Cani aggiornati: ${updated}`);
    console.log(`Righe salute create/aggiornate: ${healthIds.length}`);
    if (created + updated !== EXPECTED_DOGS) {
      throw new Error(
        `Scritti ${created + updated} cani, attesi ${EXPECTED_DOGS}.`,
      );
    }
  } finally {
    if (adcPath) {
      try {
        unlinkSync(adcPath);
      } catch {
        // ignore
      }
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
