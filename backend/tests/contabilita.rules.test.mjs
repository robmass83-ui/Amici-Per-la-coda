import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';

const dir = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(join(dir, '..', 'firestore.rules'), 'utf8');
const createdAt = new Date('2026-03-12T00:00:00Z');

const volunteer = {
  nome: 'Marco',
  email: 'marco@amiciperlacoda.it',
  ruolo: 'volontario',
  attivo: true,
  coloreAvatar: '#157A3C',
  createdAt,
  createdBy: 'presidente',
  updatedAt: createdAt,
  updatedBy: 'presidente',
};

const president = {
  ...volunteer,
  nome: 'Presidente',
  email: 'presidente@amiciperlacoda.it',
  ruolo: 'presidente',
};

const annoOk = {
  anno: 2026,
  createdAt,
  createdBy: 'vol-marco',
  updatedAt: createdAt,
  updatedBy: 'vol-marco',
};

const contabileOk = {
  anno: 2026,
  nome: 'Fattura',
  data: createdAt,
  tipologia: 'fattura',
  descrizione: '',
  mime: 'application/pdf',
  nomeFile: 'f.pdf',
  dimensione: 4,
  chunkCount: 1,
  generation: 1,
  createdAt,
  createdBy: 'vol-marco',
  updatedAt: createdAt,
  updatedBy: 'vol-marco',
};

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-contabilita',
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('volunteers/vol-marco').set(volunteer);
    await db.doc('volunteers/presidente').set(president);
    await db.doc('anniContabili/2027').set({ ...annoOk, anno: 2027 });
    await db.doc('anniContabili/2028').set({ ...annoOk, anno: 2028 });
    await db.doc('contabilita/c-vol').set(contabileOk);
    await db.doc('contabilita/c-vol/g/1/chunks/0').set({
      index: 0,
      b64: 'YQ==',
    });
    await db.doc('contabilita/c-pres').set(contabileOk);
    await db.doc('contabilita/c-pres/g/1/chunks/0').set({
      index: 0,
      b64: 'YQ==',
    });
    await db.doc('contabilita/c-b64-update').set(contabileOk);
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('un anonimo non legge anni o documenti contabili', async () => {
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(db.doc('anniContabili/2026').get());
  await assertFails(db.doc('contabilita/c1').get());
});

test('un volontario crea un anno valido', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertSucceeds(db.doc('anniContabili/2026').set(annoOk));
});

test('l id dell anno deve coincidere con il campo anno', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(db.doc('anniContabili/2024').set(annoOk));
});

test('gli anni fuori dal 1990-2100 sono rifiutati', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(
    db.doc('anniContabili/1989').set({ ...annoOk, anno: 1989 }),
  );
  await assertFails(
    db.doc('anniContabili/2101').set({ ...annoOk, anno: 2101 }),
  );
});

test('un anno non può essere modificato o eliminato', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(db.doc('anniContabili/2027').update({ updatedBy: 'x' }));
  await assertFails(db.doc('anniContabili/2027').delete());
});

test('neanche il presidente può eliminare un anno', async () => {
  const db = testEnv.authenticatedContext('presidente').firestore();
  await assertFails(db.doc('anniContabili/2028').delete());
});

test('un volontario crea un documento e un chunk validi', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertSucceeds(db.doc('contabilita/c1').set(contabileOk));
  await assertSucceeds(
    db.doc('contabilita/c1/g/1/chunks/0').set({ index: 0, b64: 'YQ==' }),
  );
});

test('un volontario non modifica o elimina documenti e chunk', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(db.doc('contabilita/c-vol').update({ nome: 'Nuovo' }));
  await assertFails(db.doc('contabilita/c-vol/g/1/chunks/0').delete());
  await assertFails(db.doc('contabilita/c-vol').delete());
});

test('il presidente modifica ed elimina documenti e chunk', async () => {
  const db = testEnv.authenticatedContext('presidente').firestore();
  await assertSucceeds(
    db.doc('contabilita/c-pres').update({ nome: 'Nuovo nome' }),
  );
  await assertSucceeds(db.doc('contabilita/c-pres/g/1/chunks/0').delete());
  await assertSucceeds(db.doc('contabilita/c-pres').delete());
});

test('il padre non può contenere contenutoB64', async () => {
  const db = testEnv.authenticatedContext('presidente').firestore();
  await assertFails(
    db.doc('contabilita/c-b64-create').set({
      ...contabileOk,
      contenutoB64: 'YQ==',
    }),
  );
  await assertFails(
    db.doc('contabilita/c-b64-update').update({ contenutoB64: 'YQ==' }),
  );
});

test('un chunk contiene solo index e b64 ed è sotto 900000 caratteri', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(
    db.doc('contabilita/c1/g/1/chunks/1').set({
      index: 1,
      b64: 'YQ==',
      extra: true,
    }),
  );
  await assertFails(
    db.doc('contabilita/c1/g/1/chunks/2').set({
      index: 2,
      b64: 'A'.repeat(900000),
    }),
  );
});
