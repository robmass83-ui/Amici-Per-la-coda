import assert from 'node:assert/strict';
import { test } from 'node:test';

const host = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099';

function authUrl(path) {
  return `http://${host}/identitytoolkit.googleapis.com/v1/${path}?key=fake-api-key`;
}

async function post(path, body) {
  const res = await fetch(authUrl(path), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  return { ok: res.ok, json };
}

test('createUser via Identity Toolkit non sostituisce la sessione del presidente', async () => {
  if (!host.includes('127.0.0.1') && !host.includes('localhost')) {
    throw new Error('Questo test gira solo sull’Auth emulator locale.');
  }
  const suffix = Date.now();
  const presidentEmail = `pres-${suffix}@amiciperlacoda.it`;
  const otherEmail = `vol-${suffix}@amiciperlacoda.it`;
  const password = 'Password1';

  const pres = await post('accounts:signUp', {
    email: presidentEmail,
    password,
    returnSecureToken: true,
  });
  assert.equal(pres.ok, true, JSON.stringify(pres.json));
  const presidentUid = pres.json.localId;
  const presidentToken = pres.json.idToken;
  assert.ok(presidentUid);
  assert.ok(presidentToken);

  const created = await post('accounts:signUp', {
    email: otherEmail,
    password,
    returnSecureToken: true,
  });
  assert.equal(created.ok, true, JSON.stringify(created.json));
  assert.notEqual(created.json.localId, presidentUid);

  const still = await post('accounts:lookup', { idToken: presidentToken });
  assert.equal(still.ok, true, JSON.stringify(still.json));
  const users = still.json.users ?? [];
  assert.equal(users[0]?.localId, presidentUid);
});
