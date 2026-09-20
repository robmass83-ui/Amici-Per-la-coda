import assert from 'node:assert/strict';
import { test } from 'node:test';
import { assertProductionWriteAllowed } from '../scripts/production_write_guard.mjs';

test('emulatore: scrittura consentita', () => {
  const prevEmu = process.env.FIRESTORE_EMULATOR_HOST;
  const prevFlag = process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  try {
    assertProductionWriteAllowed('import_test');
  } finally {
    if (prevEmu == null) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = prevEmu;
    }
    if (prevFlag == null) {
      delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
    } else {
      process.env.AMICI_ALLOW_PRODUCTION_WRITE = prevFlag;
    }
  }
});

test('produzione senza ok: abort', () => {
  const prevEmu = process.env.FIRESTORE_EMULATOR_HOST;
  const prevFlag = process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  const prevArgv = process.argv.slice();
  delete process.env.FIRESTORE_EMULATOR_HOST;
  delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  process.argv = ['node', 'script.mjs'];
  try {
    assert.throws(
      () => assertProductionWriteAllowed('import_test'),
      /rifiuto|produzione/i,
    );
  } finally {
    process.argv = prevArgv;
    if (prevEmu == null) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = prevEmu;
    }
    if (prevFlag == null) {
      delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
    } else {
      process.env.AMICI_ALLOW_PRODUCTION_WRITE = prevFlag;
    }
  }
});

test('emulatore localhost: scrittura consentita', () => {
  const prevEmu = process.env.FIRESTORE_EMULATOR_HOST;
  const prevFlag = process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  try {
    assertProductionWriteAllowed('import_test');
  } finally {
    if (prevEmu == null) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = prevEmu;
    }
    if (prevFlag == null) {
      delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
    } else {
      process.env.AMICI_ALLOW_PRODUCTION_WRITE = prevFlag;
    }
  }
});

test('produzione: entrambi i flag insieme consentiti', () => {
  const prevEmu = process.env.FIRESTORE_EMULATOR_HOST;
  const prevFlag = process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  const prevArgv = process.argv.slice();
  delete process.env.FIRESTORE_EMULATOR_HOST;
  process.env.AMICI_ALLOW_PRODUCTION_WRITE = 'YES';
  process.argv = ['node', 'script.mjs', '--i-know-this-is-production'];
  try {
    assertProductionWriteAllowed('import_test');
  } finally {
    process.argv = prevArgv;
    if (prevEmu == null) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = prevEmu;
    }
    if (prevFlag == null) {
      delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
    } else {
      process.env.AMICI_ALLOW_PRODUCTION_WRITE = prevFlag;
    }
  }
});

test('produzione: solo AMICI_ALLOW_PRODUCTION_WRITE rifiutato', () => {
  const prevEmu = process.env.FIRESTORE_EMULATOR_HOST;
  const prevFlag = process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  const prevArgv = process.argv.slice();
  delete process.env.FIRESTORE_EMULATOR_HOST;
  process.env.AMICI_ALLOW_PRODUCTION_WRITE = 'YES';
  process.argv = ['node', 'script.mjs'];
  try {
    assert.throws(
      () => assertProductionWriteAllowed('import_test'),
      /rifiuto|produzione/i,
    );
  } finally {
    process.argv = prevArgv;
    if (prevEmu == null) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = prevEmu;
    }
    if (prevFlag == null) {
      delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
    } else {
      process.env.AMICI_ALLOW_PRODUCTION_WRITE = prevFlag;
    }
  }
});

test('produzione: solo --i-know-this-is-production rifiutato', () => {
  const prevEmu = process.env.FIRESTORE_EMULATOR_HOST;
  const prevFlag = process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  const prevArgv = process.argv.slice();
  delete process.env.FIRESTORE_EMULATOR_HOST;
  delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
  process.argv = ['node', 'script.mjs', '--i-know-this-is-production'];
  try {
    assert.throws(
      () => assertProductionWriteAllowed('import_test'),
      /rifiuto|produzione/i,
    );
  } finally {
    process.argv = prevArgv;
    if (prevEmu == null) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = prevEmu;
    }
    if (prevFlag == null) {
      delete process.env.AMICI_ALLOW_PRODUCTION_WRITE;
    } else {
      process.env.AMICI_ALLOW_PRODUCTION_WRITE = prevFlag;
    }
  }
});

