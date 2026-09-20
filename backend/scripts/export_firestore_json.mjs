import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { KNOWN_ROOT_COLLECTIONS, toJsonValue } from './firestore_json_codec.mjs';

const PROJECT_ID = 'amici-per-la-coda';
const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(scriptDir, '..', '..');

if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(
    'Rifiuto: FIRESTORE_EMULATOR_HOST è impostato. Questo script deve leggere la produzione, non l\'emulatore.',
  );
  process.exit(2);
}

initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});

const db = getFirestore();

async function dumpCollection(colRef) {
  const snap = await colRef.get();
  const docs = [];
  for (const doc of snap.docs) {
    docs.push({
      id: doc.id,
      path: doc.ref.path,
      data: toJsonValue(doc.data()),
    });
  }
  return docs;
}

async function dumpSubcollections(parentPath, docs) {
  const extras = {};
  for (const doc of docs) {
    const parent = db.doc(doc.path);
    const children = await parent.listCollections();
    for (const child of children) {
      const key = `${parentPath}__${child.id}`;
      extras[key] ??= [];
      extras[key].push(
        ...(await dumpCollection(child)).map((row) => ({
          ...row,
          parentId: doc.id,
        })),
      );
    }
  }
  return extras;
}

const stamp = new Date().toISOString().replaceAll(':', '').replaceAll('.', '-');
const outDir = join(repoRoot, 'backups', `firestore-${stamp}`);
mkdirSync(outDir, { recursive: true });

const listed = await db.listCollections();
const names = new Set(KNOWN_ROOT_COLLECTIONS);
for (const col of listed) {
  names.add(col.id);
}

const counts = {};
for (const name of [...names].sort()) {
  const docs = await dumpCollection(db.collection(name));
  writeFileSync(join(outDir, `${name}.json`), `${JSON.stringify(docs, null, 2)}\n`);
  counts[name] = docs.length;
  const extras = await dumpSubcollections(name, docs);
  for (const [key, rows] of Object.entries(extras)) {
    writeFileSync(join(outDir, `${key}.json`), `${JSON.stringify(rows, null, 2)}\n`);
    counts[key] = rows.length;
  }
}

const manifest = {
  exportedAt: new Date().toISOString(),
  projectId: PROJECT_ID,
  warning:
    'Contiene dati personali e authTokens. Non committare. Non inviare. Cartella backups/ è gitignored.',
  counts,
};
writeFileSync(join(outDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(`Backup scritto in ${outDir}`);
console.log(JSON.stringify(counts, null, 2));
