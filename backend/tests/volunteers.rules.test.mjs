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

const president = {
  nome: 'Giovanna',
  cognome: 'Rossi',
  email: 'giovanna@amiciperlacoda.it',
  ruolo: 'presidente',
  attivo: true,
  coloreAvatar: '#157A3C',
  mustChangePassword: false,
  createdAt: new Date('2026-01-01T08:00:00Z'),
  createdBy: 'vol-giovanna',
  updatedAt: new Date('2026-01-01T08:00:00Z'),
  updatedBy: 'vol-giovanna',
};

const referente = {
  nome: 'Marco',
  cognome: 'P.',
  email: 'marco@amiciperlacoda.it',
  ruolo: 'referente',
  attivo: true,
  coloreAvatar: '#7B4CC0',
  mustChangePassword: false,
  createdAt: new Date('2026-01-01T08:00:00Z'),
  createdBy: 'vol-giovanna',
  updatedAt: new Date('2026-01-01T08:00:00Z'),
  updatedBy: 'vol-giovanna',
};

const volontario = {
  nome: 'Luca',
  cognome: 'Neri',
  email: 'luca@amiciperlacoda.it',
  ruolo: 'volontario',
  attivo: true,
  coloreAvatar: '#2E7FD6',
  mustChangePassword: true,
  createdAt: new Date('2026-01-01T08:00:00Z'),
  createdBy: 'vol-giovanna',
  updatedAt: new Date('2026-01-01T08:00:00Z'),
  updatedBy: 'vol-giovanna',
};

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-volunteers',
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('volunteers/vol-giovanna').set(president);
    await db.doc('volunteers/vol-marco').set(referente);
    await db.doc('volunteers/vol-luca').set(volontario);
    await db.doc('dogs/fenice').set({ nome: 'Fenice' });
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('4. un referente non può scrivere su volunteers', async () => {
  const db = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(
    db.doc('volunteers/vol-luca').update({ nome: 'Marco il referente' }),
  );
  await assertFails(
    db.doc('volunteers/nuovo').set({
      ...volontario,
      email: 'nuovo@amiciperlacoda.it',
    }),
  );
});

test('10. un utente attivo aggiorna solo i tre campi sul proprio documento', async () => {
  const db = testEnv.authenticatedContext('vol-luca').firestore();
  await assertSucceeds(
    db.doc('volunteers/vol-luca').update({
      mustChangePassword: false,
      ultimoAccesso: new Date('2026-09-08T08:00:00Z'),
      coloreAvatar: '#E04552',
    }),
  );
  await assertFails(db.doc('volunteers/vol-luca').update({ ruolo: 'presidente' }));
  await assertFails(db.doc('volunteers/vol-luca').update({ attivo: false }));
  await assertFails(
    db.doc('volunteers/vol-luca').update({
      mustChangePassword: false,
      ruolo: 'presidente',
    }),
  );
});

test('volontario con ultimoAccesso null sblocca la password al primo accesso', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('volunteers/vol-primo').set({
      ...volontario,
      email: 'primo@amiciperlacoda.it',
      ultimoAccesso: null,
    });
  });
  const db = testEnv.authenticatedContext('vol-primo').firestore();
  await assertSucceeds(
    db.doc('volunteers/vol-primo').update({ mustChangePassword: false }),
  );
  await assertFails(
    db.doc('volunteers/vol-primo').update({ ruolo: 'presidente' }),
  );
});

test('il presidente può creare e aggiornare un volontario', async () => {
  const db = testEnv.authenticatedContext('vol-giovanna').firestore();
  await assertSucceeds(
    db.doc('volunteers/vol-nuovo').set({
      ...volontario,
      email: 'nuovo@amiciperlacoda.it',
    }),
  );
  await assertSucceeds(
    db.doc('volunteers/vol-luca').update({ attivo: false }),
  );
});

test('authTokens: solo presidente o il proprio uid', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('volunteers/vol-luca').update({ attivo: true });
  });
  const presidentDb = testEnv.authenticatedContext('vol-giovanna').firestore();
  await assertSucceeds(
    presidentDb.doc('authTokens/vol-luca').set({ refreshToken: 't1' }),
  );
  await assertSucceeds(presidentDb.doc('authTokens/vol-luca').get());

  const referenteDb = testEnv.authenticatedContext('vol-marco').firestore();
  await assertFails(referenteDb.doc('authTokens/vol-luca').get());
  await assertFails(
    referenteDb.doc('authTokens/vol-luca').set({ refreshToken: 'x' }),
  );

  const selfDb = testEnv.authenticatedContext('vol-luca').firestore();
  await assertSucceeds(
    selfDb.doc('authTokens/vol-luca').set({ refreshToken: 't2' }),
  );
  await assertSucceeds(selfDb.doc('authTokens/vol-luca').get());
  await assertFails(selfDb.doc('authTokens/vol-marco').get());
});
