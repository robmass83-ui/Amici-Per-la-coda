import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';

const dir = dirname(fileURLToPath(import.meta.url));
const rulesSource = readFileSync(join(dir, '..', 'firestore.rules'), 'utf8');

test('le regole non usano mustChangePassword come barriera', () => {
  const withoutComments = rulesSource
    .replace(/\/\/.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '');
  if (withoutComments.includes('mustChangePassword')) {
    throw new Error(
      'mustChangePassword è comparso nelle regole. È un controllo di interfaccia, non una barriera. Fermarsi.',
    );
  }
});

const seed = {
  'dogs/fenice': { nome: 'Fenice' },
  'photos/p1': { dogId: 'fenice', mime: 'image/jpeg' },
  'photos/p1/full/data': { dati: 'x' },
  'health/h1': { dogId: 'fenice' },
  'weights/w1': { dogId: 'fenice' },
  'sponsorships/s1': { dogId: 'fenice' },
  'expenses/e1': { dogId: 'fenice' },
  'adopters/a1': { nome: 'Ada' },
  'vendors/v1': { nome: 'Vet' },
  'adoptions/ad1': { dogId: 'fenice' },
  'documents/d1': { dogId: 'fenice', nome: 'pdf' },
  'documents/d1/chunks/0': { dati: 'x' },
  'templates/t1': { nome: 'Modulo' },
  'notes/n1': { dogId: 'fenice', testo: 'Ciao', autoreId: 'vol-1' },
  'appointments/ap1': { titolo: 'Visita' },
  'volunteers/vol-1': {
    nome: 'Luca',
    attivo: true,
    ruolo: 'volontario',
    mustChangePassword: true,
  },
  'authTokens/vol-1': { refreshToken: 'secret' },
  'boxes/b1': { nome: 'Box 1' },
  'settings/association': { denominazione: 'Amici per la Coda ODV' },
  'dogDrafts/vol-1': { step: 1 },
  'searchRecents/vol-1': { q: 'fenice' },
};

const listPaths = [
  'dogs',
  'photos',
  'health',
  'weights',
  'sponsorships',
  'expenses',
  'adopters',
  'vendors',
  'adoptions',
  'documents',
  'templates',
  'notes',
  'appointments',
  'volunteers',
  'authTokens',
  'boxes',
  'settings',
  'dogDrafts',
  'searchRecents',
];

const getPaths = Object.keys(seed);
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-amici-anonymous',
    firestore: { rules: rulesSource },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [path, data] of Object.entries(seed)) {
      await db.doc(path).set(data);
    }
  });
});

after(async () => {
  await testEnv.cleanup();
});

function anon() {
  return testEnv.unauthenticatedContext().firestore();
}

for (const path of getPaths) {
  test(`anonimo non legge ${path}`, async () => {
    await assertFails(anon().doc(path).get());
  });
  test(`anonimo non aggiorna ${path}`, async () => {
    await assertFails(anon().doc(path).update({ x: 1 }));
  });
}

for (const col of listPaths) {
  test(`anonimo non elenca ${col}`, async () => {
    await assertFails(anon().collection(col).get());
  });
  test(`anonimo non crea in ${col}`, async () => {
    await assertFails(anon().collection(col).doc('nuovo').set({ x: 1 }));
  });
}
