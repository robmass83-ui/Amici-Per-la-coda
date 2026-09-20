import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { toAdminValue } from '../scripts/import_firestore_json.mjs';

class Timestamp {
  constructor(date) {
    this._date = date;
  }

  static fromDate(date) {
    return new Timestamp(date);
  }

  toDate() {
    return this._date;
  }
}

test('toAdminValue mantiene timestamp e bytes nidificati', () => {
  const iso = '2026-03-04T12:30:00.000Z';
  const bytes = Buffer.from('thumb-bytes');
  const result = toAdminValue(
    {
      createdAt: { __type: 'timestamp', iso },
      thumb: { __type: 'bytes', base64: bytes.toString('base64') },
    },
    Timestamp,
  );

  assert.notDeepEqual(result.createdAt, {});
  assert.ok(
    result.createdAt instanceof Timestamp || result.createdAt instanceof Date,
    'createdAt deve restare Date o Timestamp',
  );
  const date =
    result.createdAt instanceof Timestamp ? result.createdAt.toDate() : result.createdAt;
  assert.equal(date.toISOString(), iso);
  assert.ok(Buffer.isBuffer(result.thumb), 'thumb deve restare Buffer');
  assert.deepEqual(result.thumb, bytes);
});

test('import emulatore usa projectId amici-per-la-coda', () => {
  const src = readFileSync(
    new URL('../scripts/import_firestore_json.mjs', import.meta.url),
    'utf8',
  );
  assert.match(src, /projectId:\s*'amici-per-la-coda'/);
  assert.doesNotMatch(src, /demo-amici-web/);
});
