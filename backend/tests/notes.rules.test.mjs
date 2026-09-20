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

const volunteer = {
  nome: 'Marco',
  email: 'marco@amiciperlacoda.it',
  ruolo: 'volontario',
  attivo: true,
  coloreAvatar: '#157A3C',
  createdAt: new Date('2026-01-01T08:00:00Z'),
  createdBy: 'presidente',
  updatedAt: new Date('2026-01-01T08:00:00Z'),
  updatedBy: 'presidente',
};

const notaMia = {
  dogId: 'fenice',
  tipo: 'generale',
  testo: 'Mia nota',
  autoreId: 'vol-marco',
  createdAt: new Date('2026-09-01T08:00:00Z'),
};

const notaAltrui = {
  dogId: 'fenice',
  tipo: 'generale',
  testo: 'Nota di Giovanna',
  autoreId: 'presidente',
  createdAt: new Date('2026-09-01T08:00:00Z'),
};

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-notes',
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('volunteers/vol-marco').set(volunteer);
    await db.doc('notes/nota-mia').set(notaMia);
    await db.doc('notes/nota-altrui').set(notaAltrui);
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('un volontario può modificare la propria nota', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertSucceeds(db.doc('notes/nota-mia').update({ testo: 'Aggiornata' }));
});

test('un volontario non può modificare la nota di un altro', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(
    db.doc('notes/nota-altrui').update({ testo: 'Non dovrei' }),
  );
});
