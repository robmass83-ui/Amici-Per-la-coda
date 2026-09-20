import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

test('deploy_hosting non lancia firebase deploy nudo', () => {
  const src = readFileSync(new URL('./deploy_hosting.ps1', import.meta.url), 'utf8');
  assert.match(src, /deploy --only hosting/);
  assert.doesNotMatch(src, /firebase deploy\s*$/m);
  assert.doesNotMatch(src, /firebase deploy --only firestore/);
  assert.doesNotMatch(src, /firebase deploy --only rules/);
});
