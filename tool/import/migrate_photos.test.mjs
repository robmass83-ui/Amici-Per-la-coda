import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import sharp from 'sharp';

import { MemoryDb, MemoryTimestamp } from './memory_db.mjs';
import {
  asPhotoBytes,
  compressDogPhoto,
  isWebpBuffer,
  migratePhotos,
  photoMigrationAction,
} from './lib.mjs';

const NOW = new Date('2026-09-12T12:00:00Z');

async function makeJpeg(width = 800, height = 600) {
  return sharp({
    create: {
      width,
      height,
      channels: 3,
      background: { r: 21, g: 122, b: 60 },
    },
  })
    .jpeg({ quality: 85 })
    .toBuffer();
}

async function seedDog(db, id, { fotoCount = 0 } = {}) {
  await db.collection('dogs').doc(id).set({
    nome: id,
    fotoCount,
    createdAt: MemoryTimestamp.fromDate(NOW),
  });
}

async function seedPhoto(db, id, dogId, shape) {
  await db.collection('photos').doc(id).set(shape.photo);
  if (shape.full) {
    await db.collection('photos').doc(id).collection('full').doc('data').set(shape.full);
  }
}

test('photoMigrationAction: skip WebP Blob, recompress JPEG/base64', async () => {
  const jpeg = await makeJpeg();
  const webp = await compressDogPhoto(jpeg);
  assert.equal(
    photoMigrationAction(
      {
        mime: 'image/webp',
        thumb: webp.thumb,
        dogId: 'a',
      },
      { dati: webp.full },
    ),
    'skip',
  );
  assert.equal(
    photoMigrationAction(
      {
        mime: 'image/webp',
        thumb: webp.thumb,
        thumbB64: jpeg.toString('base64'),
        dogId: 'a',
      },
      { dati: webp.full, b64: jpeg.toString('base64') },
    ),
    'strip_legacy',
  );
  assert.equal(
    photoMigrationAction(
      {
        mime: 'image/jpeg',
        thumbB64: jpeg.toString('base64'),
        dogId: 'a',
      },
      { b64: jpeg.toString('base64') },
    ),
    'recompress',
  );
  assert.equal(
    photoMigrationAction({ mime: 'image/jpeg', dogId: 'a' }, null),
    'missing_full',
  );
});

test('dry-run non scrive e conta cosa convertirebbe', async () => {
  const db = new MemoryDb();
  await seedDog(db, 'fenice', { fotoCount: 0 });
  const jpeg = await makeJpeg();
  await seedPhoto(db, 'legacy', 'fenice', {
    photo: {
      dogId: 'fenice',
      isCover: true,
      w: 800,
      h: 600,
      mime: 'image/jpeg',
      thumbB64: jpeg.toString('base64'),
      bytesFull: jpeg.length,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: { b64: jpeg.toString('base64') },
  });
  const writesBefore = db.writes;
  const stats = await migratePhotos({ db, dryRun: true, log: () => {} });
  assert.equal(db.writes, writesBefore);
  assert.equal(stats.converted, 1);
  assert.equal(stats.fotoCountWouldUpdate, 1);
  assert.equal(stats.fotoCountUpdated, 0);
  const still = (await db.collection('photos').doc('legacy').get()).data();
  assert.equal(still.thumbB64, jpeg.toString('base64'));
  assert.equal(still.mime, 'image/jpeg');
});

test('migra base64 JPEG e Blob JPEG, salta WebP, aggiorna fotoCount', async () => {
  const db = new MemoryDb();
  await seedDog(db, 'fenice', { fotoCount: 0 });
  await seedDog(db, 'brando', { fotoCount: 9 });
  const jpeg = await makeJpeg();
  const webp = await compressDogPhoto(jpeg);
  await seedPhoto(db, 'p-b64', 'fenice', {
    photo: {
      dogId: 'fenice',
      isCover: true,
      w: 800,
      h: 600,
      mime: 'image/jpeg',
      thumbB64: jpeg.toString('base64'),
      bytesFull: jpeg.length,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: { b64: jpeg.toString('base64') },
  });
  await seedPhoto(db, 'p-blob-jpeg', 'fenice', {
    photo: {
      dogId: 'fenice',
      isCover: false,
      w: 800,
      h: 600,
      mime: 'image/jpeg',
      thumb: jpeg.subarray(0, Math.min(8000, jpeg.length)),
      bytesFull: jpeg.length,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: { dati: jpeg },
  });
  await seedPhoto(db, 'p-webp', 'brando', {
    photo: {
      dogId: 'brando',
      isCover: true,
      w: webp.width,
      h: webp.height,
      mime: 'image/webp',
      thumb: webp.thumb,
      bytesFull: webp.full.length,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: { dati: webp.full },
  });

  const statePath = join(mkdtempSync(join(tmpdir(), 'mig-ph-')), 'state.json');
  const stats = await migratePhotos({ db, dryRun: false, statePath, log: () => {} });
  assert.equal(stats.converted, 2);
  assert.equal(stats.skipped, 1);
  assert.equal(stats.errors.length, 0);
  assert.equal(stats.fotoCountUpdated, 2);

  const b64 = (await db.collection('photos').doc('p-b64').get()).data();
  assert.equal(b64.mime, 'image/webp');
  assert.equal(b64.thumbB64, undefined);
  assert.ok(isWebpBuffer(b64.thumb));
  const b64Full = (
    await db.collection('photos').doc('p-b64').collection('full').doc('data').get()
  ).data();
  assert.equal(b64Full.b64, undefined);
  assert.ok(isWebpBuffer(b64Full.dati));
  assert.ok(asPhotoBytes(b64Full.dati).length <= 450 * 1024);

  const blob = (await db.collection('photos').doc('p-blob-jpeg').get()).data();
  assert.equal(blob.mime, 'image/webp');
  assert.ok(isWebpBuffer(blob.thumb));

  assert.equal((await db.collection('dogs').doc('fenice').get()).data().fotoCount, 2);
  assert.equal((await db.collection('dogs').doc('brando').get()).data().fotoCount, 1);

  const again = await migratePhotos({ db, dryRun: false, statePath, log: () => {} });
  assert.equal(again.converted, 0);
  assert.equal(again.skipped, 3);
  assert.equal(again.fotoCountUpdated, 0);
});

test('errore su una foto non blocca le altre; --limit ne prende N', async () => {
  const db = new MemoryDb();
  await seedDog(db, 'fenice');
  const jpeg = await makeJpeg(400, 300);
  await seedPhoto(db, 'bad', 'fenice', {
    photo: {
      dogId: 'fenice',
      isCover: false,
      w: 1,
      h: 1,
      mime: 'image/jpeg',
      thumbB64: jpeg.toString('base64'),
      bytesFull: 1,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: null,
  });
  await seedPhoto(db, 'ok1', 'fenice', {
    photo: {
      dogId: 'fenice',
      isCover: true,
      w: 400,
      h: 300,
      mime: 'image/jpeg',
      thumbB64: jpeg.toString('base64'),
      bytesFull: jpeg.length,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: { b64: jpeg.toString('base64') },
  });
  await seedPhoto(db, 'ok2', 'fenice', {
    photo: {
      dogId: 'fenice',
      isCover: false,
      w: 400,
      h: 300,
      mime: 'image/jpeg',
      thumbB64: jpeg.toString('base64'),
      bytesFull: jpeg.length,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'test',
    },
    full: { b64: jpeg.toString('base64') },
  });

  const limited = await migratePhotos({
    db,
    dryRun: false,
    limit: 1,
    log: () => {},
  });
  assert.equal(limited.converted, 1);
  assert.equal(limited.missingFull, 1);
  const ok1 = (await db.collection('photos').doc('ok1').get()).data();
  const ok2 = (await db.collection('photos').doc('ok2').get()).data();
  const convertedCount = [ok1, ok2].filter((p) => p.mime === 'image/webp').length;
  assert.equal(convertedCount, 1);

  const rest = await migratePhotos({ db, dryRun: false, log: () => {} });
  assert.equal(rest.converted, 1);
  assert.equal(
    (await db.collection('photos').doc('ok2').get()).data().mime,
    'image/webp',
  );
  assert.ok(rest.errors.some((e) => e.id === 'bad') || rest.missingFull >= 1);
});
