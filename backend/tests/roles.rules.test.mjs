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

function volunteer(ruolo, extra = {}) {
  return {
    nome: ruolo,
    cognome: 'Test',
    email: `${ruolo}@amiciperlacoda.it`,
    ruolo,
    attivo: true,
    coloreAvatar: '#157A3C',
    mustChangePassword: false,
    createdAt: new Date('2026-01-01T08:00:00Z'),
    createdBy: 'vol-presidente',
    updatedAt: new Date('2026-01-01T08:00:00Z'),
    updatedBy: 'vol-presidente',
    ...extra,
  };
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-roles',
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('volunteers/vol-presidente').set(volunteer('presidente'));
    await db.doc('volunteers/vol-referente').set(volunteer('referente'));
    await db.doc('volunteers/vol-volontario').set(volunteer('volontario'));
    await db.doc('volunteers/vol-inattivo').set(
      volunteer('volontario', { attivo: false }),
    );
    await db.doc('dogs/fenice').set({ nome: 'Fenice' });
    await db.doc('notes/nota-1').set({
      dogId: 'fenice',
      testo: 'Ciao',
      autoreId: 'vol-volontario',
    });
    await db.doc('settings/association').set({
      denominazione: 'Amici per la Coda ODV',
      capienzaAutorizzata: 54,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('anonimo non legge i cani', async () => {
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(db.doc('dogs/fenice').get());
});

test('volontario inattivo non legge i cani', async () => {
  const db = testEnv.authenticatedContext('vol-inattivo').firestore();
  await assertFails(db.doc('dogs/fenice').get());
});

test('volontario legge ma non modifica i cani', async () => {
  const db = testEnv.authenticatedContext('vol-volontario').firestore();
  await assertSucceeds(db.doc('dogs/fenice').get());
  await assertFails(db.doc('dogs/fenice').update({ nome: 'Altro' }));
  await assertFails(
    db.doc('dogs/nuovo').set({ nome: 'Nuovo' }),
  );
});

test('volontario può creare una nota e non tocca le impostazioni', async () => {
  const db = testEnv.authenticatedContext('vol-volontario').firestore();
  await assertSucceeds(
    db.doc('notes/nota-mia').set({
      dogId: 'fenice',
      testo: 'Mia',
      autoreId: 'vol-volontario',
    }),
  );
  await assertFails(
    db.doc('settings/association').update({ denominazione: 'No' }),
  );
});

test('referente scrive sui cani e non su settings né volunteers', async () => {
  const db = testEnv.authenticatedContext('vol-referente').firestore();
  await assertSucceeds(db.doc('dogs/fenice').update({ nome: 'Fenice 2' }));
  await assertFails(
    db.doc('settings/association').update({ capienzaAutorizzata: 10 }),
  );
  await assertFails(
    db.doc('volunteers/vol-volontario').update({ attivo: false }),
  );
});

test('presidente scrive settings e volunteers', async () => {
  const db = testEnv.authenticatedContext('vol-presidente').firestore();
  await assertSucceeds(
    db.doc('settings/association').update({
      denominazione: 'Amici per la Coda ODV',
    }),
  );
  await assertSucceeds(
    db.doc('volunteers/vol-volontario').update({ attivo: false }),
  );
});

test('mustChangePassword true non blocca le letture se attivo', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('volunteers/vol-must').set(
      volunteer('volontario', { mustChangePassword: true }),
    );
  });
  const db = testEnv.authenticatedContext('vol-must').firestore();
  await assertSucceeds(db.doc('dogs/fenice').get());
});
