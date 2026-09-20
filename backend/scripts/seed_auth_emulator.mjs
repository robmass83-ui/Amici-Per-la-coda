const host = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099';
if (!host.includes('127.0.0.1') && !host.includes('localhost')) {
  throw new Error('seed_auth_emulator.mjs: solo Auth emulator locale.');
}

const email = process.argv[2] ?? 'presidente@amiciperlacoda.it';
const password = process.argv[3] ?? 'Password1';
const res = await fetch(
  `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  },
);
const body = await res.json();
if (!res.ok) {
  throw new Error(`seed Auth fallito: ${JSON.stringify(body)}`);
}
console.log(`Auth emulator: creato ${email} uid=${body.localId}`);
