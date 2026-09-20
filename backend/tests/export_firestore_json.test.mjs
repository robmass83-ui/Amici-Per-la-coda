import assert from 'node:assert/strict';
import { test } from 'node:test';
import { fromJsonValue, toJsonValue, KNOWN_ROOT_COLLECTIONS } from '../scripts/firestore_json_codec.mjs';

test('elenco collezioni obbligatorie della spec', () => {
  const required = [
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
  for (const name of required) {
    assert.ok(KNOWN_ROOT_COLLECTIONS.includes(name), name);
  }
});

test('toJsonValue serializza timestamp, bytes e mappe', () => {
  const encoded = toJsonValue({
    nome: 'Fenice',
    createdAt: { toDate: () => new Date('2026-01-01T08:00:00.000Z') },
    thumb: Buffer.from('abc'),
    tags: ['a', 'b'],
    vuoto: null,
  });
  assert.deepEqual(encoded, {
    nome: 'Fenice',
    createdAt: { __type: 'timestamp', iso: '2026-01-01T08:00:00.000Z' },
    thumb: { __type: 'bytes', base64: Buffer.from('abc').toString('base64') },
    tags: ['a', 'b'],
    vuoto: null,
  });
});

test('fromJsonValue è l\'inverso per timestamp e bytes', () => {
  const source = {
    createdAt: { __type: 'timestamp', iso: '2026-01-01T08:00:00.000Z' },
    thumb: { __type: 'bytes', base64: Buffer.from('abc').toString('base64') },
  };
  const decoded = fromJsonValue(source);
  assert.ok(decoded.createdAt instanceof Date);
  assert.equal(decoded.createdAt.toISOString(), '2026-01-01T08:00:00.000Z');
  assert.ok(Buffer.isBuffer(decoded.thumb));
  assert.equal(decoded.thumb.toString(), 'abc');
});
