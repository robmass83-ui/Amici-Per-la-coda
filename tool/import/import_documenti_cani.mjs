#!/usr/bin/env node
import { existsSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  DOCUMENTI_AUTHOR,
  EXPECTED_DOCUMENTS,
  buildDocumentiPlan,
  documentChunkCount,
  documentiZipOf,
  splitDocumentBytes,
  withExtractedZipAsync,
} from './documenti_cani.mjs';
import { assertProductionWriteAllowed } from '../../backend/scripts/production_write_guard.mjs';

assertProductionWriteAllowed('import_documenti_cani.mjs');

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
    if (arg === '--zip' || arg === '--dir') {
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        throw new Error(`${arg} richiede un percorso`);
      }
      values[arg.slice(2)] = next;
      i += 1;
    } else if (arg.startsWith('--')) {
      flags.add(arg.slice(2));
    }
  }
  return { flags, values };
}

function usage() {
  return `Uso:
  node import_documenti_cani.mjs --dry-run
  node import_documenti_cani.mjs

Idempotente sull'id anagrafe_<microchip>. Non crea doppioni.
Collega ogni PDF al cane con lo stesso microchip.
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

function documentPayload(plan, dogId, bytes, Timestamp, now, existing) {
  const count = documentChunkCount(bytes.length);
  const caricatoIl = ts(Timestamp, plan.dataDocumento) || ts(Timestamp, now);
  return {
    dogId,
    adoptionId: null,
    adopterId: '',
    tipo: plan.tipo,
    nome: plan.nome,
    mime: plan.mime,
    chunkCount: count,
    contenutoB64: count === 0 ? bytes.toString('base64') : null,
    caricatoIl,
    caricatoDa: DOCUMENTI_AUTHOR,
    createdAt: existing?.createdAt || ts(Timestamp, now),
    createdBy: existing?.createdBy || DOCUMENTI_AUTHOR,
    updatedAt: ts(Timestamp, now),
    updatedBy: DOCUMENTI_AUTHOR,
  };
}

async function loadDogsByChip(db) {
  const snap = await db.collection('dogs').get();
  const byChip = new Map();
  for (const doc of snap.docs) {
    const data = doc.data();
    const chip = typeof data.microchip === 'string' ? data.microchip.trim() : '';
    if (chip) {
      byChip.set(chip, { id: doc.id, nome: data.nome || doc.id });
    }
  }
  return byChip;
}

function matchPlan(plan, byChip) {
  const matched = [];
  const missing = [];
  for (const doc of plan.docs) {
    const dog = byChip.get(doc.microchip);
    if (!dog) {
      missing.push(`${doc.cane} (${doc.microchip})`);
      continue;
    }
    matched.push({ plan: doc, dog });
  }
  return { matched, missing };
}

async function writeDocument(db, Timestamp, now, item, existingSnap) {
  const bytes = readFileSync(item.plan.path);
  const existing = existingSnap.exists ? existingSnap.data() : null;
  const payload = documentPayload(
    item.plan,
    item.dog.id,
    bytes,
    Timestamp,
    now,
    existing,
  );
  const ref = db.collection('documents').doc(item.plan.id);
  const chunks = splitDocumentBytes(bytes);
  if (chunks.length === 0) {
    await ref.set(payload);
    return;
  }
  const batch = db.batch();
  batch.set(ref, payload);
  for (let i = 0; i < chunks.length; i++) {
    batch.set(ref.collection('chunks').doc(String(i)), {
      b64: chunks[i].toString('base64'),
      index: i,
    });
  }
  await batch.commit();
}

async function importFromDir(dir, { dryRun }) {
  const plan = buildDocumentiPlan(dir);
  if (plan.errors.length > 0) {
    for (const error of plan.errors) {
      console.error(error);
    }
    console.error('Nessuna scrittura: il pacchetto documenti non è completo.');
    process.exitCode = 1;
    return;
  }

  console.log(`Fonte: ${plan.fonte || 'documenti-cani.zip'}`);
  console.log(`Letti ${plan.docs.length} PDF (${plan.generato || 'data sconosciuta'})`);

  const { db, Timestamp, adcPath } = await initFirestore();
  let created = 0;
  let updated = 0;
  try {
    const byChip = await loadDogsByChip(db);
    const { matched, missing } = matchPlan(plan, byChip);
    if (missing.length > 0) {
      console.error('Cani non trovati per microchip:');
      for (const row of missing) {
        console.error(`  ${row}`);
      }
      console.error('Nessuna scrittura.');
      process.exitCode = 1;
      return;
    }
    if (matched.length !== EXPECTED_DOCUMENTS) {
      console.error(
        `Abbinati ${matched.length} documenti, attesi ${EXPECTED_DOCUMENTS}.`,
      );
      process.exitCode = 1;
      return;
    }

    if (dryRun) {
      console.log('\nDry-run: nessuna scrittura su Firestore.');
      console.log(`Documenti da creare o aggiornare: ${matched.length}`);
      for (const item of matched) {
        console.log(
          `  ${item.plan.cane} → ${item.dog.id}  ${item.plan.nome}  ${item.plan.size} byte`,
        );
      }
      return;
    }

    const now = new Date();
    for (const item of matched) {
      const ref = db.collection('documents').doc(item.plan.id);
      const snap = await ref.get();
      if (snap.exists) {
        updated += 1;
      } else {
        created += 1;
      }
      await writeDocument(db, Timestamp, now, item, snap);
    }

    console.log(`\nDocumenti creati: ${created}`);
    console.log(`Documenti aggiornati: ${updated}`);
    if (created + updated !== EXPECTED_DOCUMENTS) {
      throw new Error(
        `Scritti ${created + updated} documenti, attesi ${EXPECTED_DOCUMENTS}.`,
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
  if (parsed.values.dir) {
    await importFromDir(parsed.values.dir, { dryRun });
    return;
  }
  const zipPath = documentiZipOf(parsed.values.zip);
  await withExtractedZipAsync(zipPath, (dir) => importFromDir(dir, { dryRun }));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
