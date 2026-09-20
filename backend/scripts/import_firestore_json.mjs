import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { fromJsonValue } from './firestore_json_codec.mjs';
import { assertProductionWriteAllowed } from './production_write_guard.mjs';

assertProductionWriteAllowed('import_firestore_json.mjs');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    'import_firestore_json.mjs: FIRESTORE_EMULATOR_HOST obbligatorio. Mai importare il backup su produzione da questo script.',
  );
}

const dir = process.argv[2];
if (!dir) {
  throw new Error('Uso: node scripts/import_firestore_json.mjs <cartella-backup>');
}

initializeApp({
  credential: applicationDefault(),
  projectId: 'demo-amici-web',
});
const db = getFirestore();

function toAdminValue(value) {
  const decoded = fromJsonValue(value);
  if (decoded instanceof Date) {
    return Timestamp.fromDate(decoded);
  }
  if (Array.isArray(decoded)) {
    return decoded.map(toAdminValue);
  }
  if (decoded && typeof decoded === 'object' && !Buffer.isBuffer(decoded)) {
    const out = {};
    for (const [key, child] of Object.entries(decoded)) {
      out[key] = toAdminValue(child);
    }
    return out;
  }
  return decoded;
}

const files = readdirSync(dir).filter((name) => name.endsWith('.json') && name !== 'manifest.json');
for (const file of files) {
  const rows = JSON.parse(readFileSync(join(dir, file), 'utf8'));
  if (!Array.isArray(rows)) {
    continue;
  }
  for (const row of rows) {
    if (!row.path) {
      continue;
    }
    await db.doc(row.path).set(toAdminValue(row.data));
  }
}
console.log(`Import emulatore da ${dir} completato.`);
