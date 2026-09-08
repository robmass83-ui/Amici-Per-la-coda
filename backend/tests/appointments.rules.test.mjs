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

const appointment = {
  tipo: 'turno',
  titolo: 'Pulizia settore B',
  dogId: null,
  adoptionId: null,
  inizio: new Date('2026-09-08T08:00:00Z'),
  fine: null,
  tuttoIlGiorno: false,
  luogo: 'Settore B',
  volontariIds: [],
  stato: 'previsto',
  createdAt: new Date('2026-09-01T08:00:00Z'),
  createdBy: 'presidente',
  updatedAt: new Date('2026-09-01T08:00:00Z'),
  updatedBy: 'presidente',
};

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

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-per-la-coda',
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('volunteers/vol-marco').set(volunteer);
    await db.doc('appointments/turno1').set(appointment);
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('un volontario attivo può aggiungere il proprio uid a volontariIds', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertSucceeds(
    db.doc('appointments/turno1').update({ volontariIds: ['vol-marco'] }),
  );
});

test('lo stesso volontario non può cambiare un altro campo dell\'appuntamento', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(
    db.doc('appointments/turno1').update({ titolo: 'Turno modificato' }),
  );
});
