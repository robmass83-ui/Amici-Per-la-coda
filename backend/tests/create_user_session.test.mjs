import assert from 'node:assert/strict';
import { test } from 'node:test';

const host = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099';

function parseAllowedAuthEmulatorAuthority(value) {
  if (typeof value !== 'string') {
    return null;
  }
  const raw = value.trim();
  if (!raw || raw.includes('://') || raw.startsWith('[')) {
    return null;
  }
  const colon = raw.lastIndexOf(':');
  if (colon <= 0 || colon === raw.length - 1) {
    return null;
  }
  const hostname = raw.slice(0, colon);
  const portText = raw.slice(colon + 1);
  if (!/^\d+$/.test(portText)) {
    return null;
  }
  const port = Number(portText);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    return null;
  }
  if (hostname !== '127.0.0.1' && hostname !== 'localhost') {
    return null;
  }
  return { host: hostname, port };
}

function isAllowedAuthEmulatorHost(value) {
  return parseAllowedAuthEmulatorAuthority(value) !== null;
}

function authUrl(path, emulatorHost = host) {
  const parsed = parseAllowedAuthEmulatorAuthority(emulatorHost);
  if (!parsed) {
    throw new Error('Questo test gira solo sull’Auth emulator locale.');
  }
  return `http://${parsed.host}:${parsed.port}/identitytoolkit.googleapis.com/v1/${path}?key=fake-api-key`;
}

test('accetta solo hostname Auth emulator loopback esatti', () => {
  for (const value of ['127.0.0.1:9099', 'localhost:9099']) {
    assert.equal(isAllowedAuthEmulatorHost(value), true, value);
  }
});

test('rifiuta host Auth emulator non loopback', () => {
  for (const value of [
    'localhost.example.com:9099',
    'evil.com:9099',
    '',
    '   ',
    'example.com:9099',
    '127.0.0.1.nip.io:9099',
    'notlocalhost:9099',
    'http://127.0.0.1:9099',
    '0.0.0.0:9099',
    '10.0.0.1:9099',
    '::1',
    '::1:9099',
    '[::1]',
    '[::1]:9099',
    '[127.0.0.1]',
    '[127.0.0.1]:9099',
    '127.0.0.1',
    'localhost',
    '127.0.0.1:',
    'localhost:0',
    '127.0.0.1:65536',
  ]) {
    assert.equal(isAllowedAuthEmulatorHost(value), false, value);
  }
});

test('costruisce URL Auth emulator dal host:port parsato', () => {
  assert.equal(
    authUrl('accounts:signUp', '127.0.0.1:9099'),
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key',
  );
  assert.throws(() => authUrl('accounts:signUp', '::1:9099'));
});

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
  if (!isAllowedAuthEmulatorHost(host)) {
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
