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

test('run_web_emulator attende Firestore 8080 e Auth 9099 prima di Flutter', () => {
  const src = readFileSync(new URL('./run_web_emulator.ps1', import.meta.url), 'utf8');
  assert.match(src, /--project['\s,]+amici-per-la-coda/);
  assert.doesNotMatch(src, /demo-amici-web/);
  assert.doesNotMatch(src, /Start-Sleep -Seconds 8/);
  assert.match(src, /8080/);
  assert.match(src, /9099/);
  assert.match(src, /5000/);
  assert.match(src, /60/);
  assert.doesNotMatch(
    src,
    /Test-TcpOpen[\s\S]{0,120}Port 8080[\s\S]{0,40}-or[\s\S]{0,120}Port 9099/,
  );
  assert.doesNotMatch(
    src,
    /Test-TcpOpen[\s\S]{0,120}Port 9099[\s\S]{0,40}-or[\s\S]{0,120}Port 8080/,
  );
  assert.match(
    src,
    /Test-TcpOpen[\s\S]{0,120}Port 8080[\s\S]{0,40}-and[\s\S]{0,120}Port 9099/,
  );
});
