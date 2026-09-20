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

function blob(bytes) {
  return 'x'.repeat(bytes);
}

function photoMeta(thumb) {
  const data = {
    dogId: 'fenice',
    isCover: true,
    w: 200,
    h: 200,
    mime: 'image/webp',
    bytesFull: 1000,
    createdAt: new Date('2026-09-12T08:00:00Z'),
    createdBy: 'vol-referente',
  };
  if (thumb != null) {
    data.thumb = thumb;
  }
  return data;
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-photos',
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('volunteers/vol-presidente').set(volunteer('presidente'));
    await db.doc('volunteers/vol-referente').set(volunteer('referente'));
    await db.doc('volunteers/vol-volontario').set(volunteer('volontario'));
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('referente scrive thumb e full nei limiti', async () => {
  const db = testEnv.authenticatedContext('vol-referente').firestore();
  await assertSucceeds(
    db.doc('photos/ok').set(photoMeta(blob(12 * 1024))),
  );
  await assertSucceeds(
    db.doc('photos/ok/full/data').set({ dati: blob(450 * 1024) }),
  );
  await assertSucceeds(db.doc('photos/ok').get());
  await assertSucceeds(db.doc('photos/ok/full/data').get());
});

test('una foto da 800 KB nel full viene rifiutata', async () => {
  const db = testEnv.authenticatedContext('vol-referente').firestore();
  await assertSucceeds(db.doc('photos/huge').set(photoMeta(blob(8))));
  await assertFails(
    db.doc('photos/huge/full/data').set({
      dati: blob(800 * 1024),
    }),
  );
});

test('thumb da 25 KB e oltre viene rifiutata', async () => {
  const db = testEnv.authenticatedContext('vol-referente').firestore();
  await assertFails(
    db.doc('photos/thumb-big').set(photoMeta(blob(25000))),
  );
  await assertSucceeds(
    db.doc('photos/thumb-ok').set(photoMeta(blob(24999))),
  );
});

test('volontario legge le foto e non le scrive', async () => {
  const refDb = testEnv.authenticatedContext('vol-referente').firestore();
  await assertSucceeds(
    refDb.doc('photos/letta').set(photoMeta(blob(16))),
  );
  const db = testEnv.authenticatedContext('vol-volontario').firestore();
  await assertSucceeds(db.doc('photos/letta').get());
  await assertFails(
    db.doc('photos/letta').set(photoMeta(blob(16))),
  );
  await assertFails(
    db.doc('photos/letta/full/data').set({ dati: blob(8) }),
  );
});
