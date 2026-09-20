import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { fromJsonValue } from './firestore_json_codec.mjs';
import { assertProductionWriteAllowed } from './production_write_guard.mjs';

export function toAdminValue(value, TimestampImpl = Timestamp) {
  return convertDecoded(fromJsonValue(value), TimestampImpl);
}

function convertDecoded(decoded, TimestampImpl) {
  if (decoded instanceof Date) {
    return TimestampImpl.fromDate(decoded);
  }
  if (typeof Buffer !== 'undefined' && Buffer.isBuffer(decoded)) {
    return decoded;
  }
  if (Array.isArray(decoded)) {
    return decoded.map((item) => convertDecoded(item, TimestampImpl));
  }
  if (decoded && typeof decoded === 'object') {
    const out = {};
    for (const [key, child] of Object.entries(decoded)) {
      out[key] = convertDecoded(child, TimestampImpl);
    }
    return out;
  }
  return decoded;
}

function isCli() {
  return Boolean(process.argv[1]?.replaceAll('\\', '/').endsWith('import_firestore_json.mjs'));
}

if (isCli()) {
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
    projectId: 'amici-per-la-coda',
  });
  const db = getFirestore();

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
}
