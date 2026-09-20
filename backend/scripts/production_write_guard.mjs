export function assertProductionWriteAllowed(scriptName) {
  const emulator = process.env.FIRESTORE_EMULATOR_HOST ?? '';
  if (emulator.includes('127.0.0.1') || emulator.includes('localhost')) {
    return;
  }
  const allowed =
    process.env.AMICI_ALLOW_PRODUCTION_WRITE === 'YES' &&
    process.argv.includes('--i-know-this-is-production');
  if (allowed) {
    console.warn(
      `${scriptName}: ok esplicito presente. Scrittura su PRODUZIONE ${process.env.GCLOUD_PROJECT ?? 'amici-per-la-coda'}.`,
    );
    return;
  }
  throw new Error(
    `${scriptName}: rifiuto. Questo script scriverebbe sul database di produzione. ` +
      `Usa l'emulatore (FIRESTORE_EMULATOR_HOST=127.0.0.1:8080) oppure, solo dopo un ok esplicito di questa volta, ` +
      `rilancia con AMICI_ALLOW_PRODUCTION_WRITE=YES e --i-know-this-is-production.`,
  );
}
