import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

import { MemoryDb, MemoryTimestamp } from './memory_db.mjs';
import {
  PHOTO_FULL_MAX_BYTES,
  PHOTO_THUMB_MAX_BYTES,
  asPhotoBytes,
  backupAll,
  buildPlan,
  compressDogPhoto,
  compressDogPhotoJpegBaseline,
  countCollection,
  csvDogId,
  importDogs,
  importPhotos,
  loadCsvBundle,
  normalizeName,
  restoreAll,
  verifyImport,
} from './lib.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const NOW = new Date('2026-09-11T12:00:00Z');
const csvBundle = loadCsvBundle(ROOT);
const SOLO_FOTO = [
  'Aramis',
  'Diana',
  'Duca',
  'Flora',
  'Max',
  'Mirtillo',
  'Molly',
  'Totò',
];

let generatedPhotoDir;

async function makeJpeg(path, width = 1200, height = 1000) {
  await sharp({
    create: {
      width,
      height,
      channels: 3,
      background: { r: 21, g: 122, b: 60 },
    },
  })
    .jpeg({ quality: 90 })
    .toFile(path);
}

async function ensureGeneratedPhotos() {
  if (generatedPhotoDir) {
    return generatedPhotoDir;
  }
  generatedPhotoDir = mkdtempSync(join(tmpdir(), 'amici-import-foto-'));
  const plan = buildPlan(csvBundle, { photoDir: generatedPhotoDir });
  for (const item of plan.photos) {
    await makeJpeg(item.path);
  }
  return generatedPhotoDir;
}

function snapshot(data) {
  return JSON.stringify(data, (_, value) => {
    if (value && typeof value.toDate === 'function') {
      return value.toDate().toISOString();
    }
    if (value instanceof Date) {
      return value.toISOString();
    }
    return value;
  });
}

function ctx(db, plan, extra = {}) {
  return {
    db,
    plan,
    now: NOW,
    Timestamp: MemoryTimestamp,
    dryRun: false,
    phase: 'all',
    ...extra,
  };
}

test('1. --dry-run sui CSV reali: 49+98 creazioni, 8 solo foto, 267 foto, 0 errori, nessuna scrittura', async () => {
  const photoDir = join(ROOT, 'import', 'foto');
  const plan = buildPlan(csvBundle, { photoDir });
  const db = new MemoryDb();
  const before = {
    dogs: await countCollection(db, 'dogs'),
    photos: await countCollection(db, 'photos'),
    notes: await countCollection(db, 'notes'),
  };

  assert.equal(plan.counts.rifugio, 49);
  assert.equal(plan.counts.facebookCrea, 98);
  assert.equal(plan.counts.soloFoto, 8);
  assert.equal(plan.counts.photos, 267);
  assert.equal(plan.errors.length, 0);
  assert.equal(plan.missing.length, 0);
  assert.deepEqual(
    plan.soloFoto.map((item) => item.existingName).sort(),
    [...SOLO_FOTO].sort(),
  );
  for (const item of plan.soloFoto) {
    assert.ok(item.matchId, `solo_foto ${item.existingName} deve risolvere un csv_*`);
    assert.ok(item.matchId.startsWith('csv_'));
  }

  await importDogs(ctx(db, plan, { dryRun: true }));
  await importPhotos(ctx(db, plan, { dryRun: true }));

  assert.equal(db.writes, 0);
  assert.equal(await countCollection(db, 'dogs'), before.dogs);
  assert.equal(await countCollection(db, 'photos'), before.photos);
  assert.equal(await countCollection(db, 'notes'), before.notes);
});

test('2. Dopo --dogs: 147 cani; gli 8 solo_foto non creano nulla e restano invariati', async () => {
  const plan = buildPlan(csvBundle, { photoDir: join(ROOT, 'import', 'foto') });
  const db = new MemoryDb();

  await importDogs(ctx(db, plan, { phase: 'rifugio' }));
  const before = {};
  for (const name of SOLO_FOTO) {
    const id = csvDogId(name);
    const snap = await db.collection('dogs').doc(id).get();
    assert.equal(snap.exists, true, `manca ${id} dopo il CSV rifugio`);
    before[id] = snapshot(snap.data());
  }
  const dogsAfterRifugio = await countCollection(db, 'dogs');
  assert.equal(dogsAfterRifugio, 49);

  await importDogs(ctx(db, plan, { phase: 'facebook' }));
  assert.equal(await countCollection(db, 'dogs'), 147);

  for (const name of SOLO_FOTO) {
    const id = csvDogId(name);
    const after = await db.collection('dogs').doc(id).get();
    assert.equal(snapshot(after.data()), before[id]);
    const fbId = [...db.store.keys()].find(
      (key) =>
        key.startsWith('dogs/fb_') &&
        normalizeName(db.store.get(key).nome) === normalizeName(name),
    );
    assert.equal(fbId, undefined, `solo_foto ${name} non deve creare un fb_*`);
  }
});

test('3. Rilanciare --dogs non cambia il numero di documenti', async () => {
  const plan = buildPlan(csvBundle, { photoDir: join(ROOT, 'import', 'foto') });
  const db = new MemoryDb();
  await importDogs(ctx(db, plan));
  const dogs = await countCollection(db, 'dogs');
  const notes = await countCollection(db, 'notes');
  assert.equal(dogs, 147);
  await importDogs(ctx(db, plan));
  assert.equal(await countCollection(db, 'dogs'), dogs);
  assert.equal(await countCollection(db, 'notes'), notes);
});

test('4. Ogni full ≤ 450 KB WebP e ≥ 900 px sul lato lungo; ogni thumb ≤ 12 KB', async () => {
  const photoDir = await ensureGeneratedPhotos();
  const db = new MemoryDb();
  const plan = buildPlan(csvBundle, { photoDir });
  await importDogs(ctx(db, plan));
  await importPhotos(ctx(db, plan));

  const photos = await db.collection('photos').get();
  assert.ok(photos.size > 0);
  for (const doc of photos.docs) {
    const data = doc.data();
    assert.equal(data.mime, 'image/webp');
    assert.ok(data.bytesFull <= PHOTO_FULL_MAX_BYTES, `${doc.id} full ${data.bytesFull}`);
    const longSide = Math.max(data.w, data.h);
    assert.ok(longSide >= 900, `${doc.id} lato lungo ${longSide}`);
    const thumbBytes = asPhotoBytes(data.thumb);
    assert.ok(Buffer.isBuffer(data.thumb), `${doc.id} thumb deve essere bytes`);
    assert.equal(data.thumbB64, undefined);
    assert.ok(
      thumbBytes.length <= PHOTO_THUMB_MAX_BYTES,
      `${doc.id} thumb ${thumbBytes.length}`,
    );
    const fullSnap = await db
      .collection('photos')
      .doc(doc.id)
      .collection('full')
      .doc('data')
      .get();
    assert.equal(fullSnap.exists, true);
    const fullData = fullSnap.data();
    assert.equal(Object.keys(fullData).join(','), 'dati');
    assert.ok(Buffer.isBuffer(fullData.dati));
    assert.equal(fullData.b64, undefined);
    assert.deepEqual(Object.keys(data).sort(), [
      'bytesFull',
      'createdAt',
      'createdBy',
      'dogId',
      'h',
      'isCover',
      'mime',
      'thumb',
      'w',
    ]);
  }
});

test('5. Gli 8 solo_foto hanno le foto in più e la stessa copertina di prima', async () => {
  const photoDir = await ensureGeneratedPhotos();
  const db = new MemoryDb();
  const plan = buildPlan(csvBundle, { photoDir });
  await importDogs(ctx(db, plan));

  for (const name of SOLO_FOTO) {
    const id = csvDogId(name);
    const coverId = `keep_cover_${id}`;
    await db.collection('photos').doc(coverId).set({
      dogId: id,
      isCover: true,
      w: 10,
      h: 10,
      mime: 'image/jpeg',
      thumb: Buffer.from('x'),
      bytesFull: 1,
      createdAt: MemoryTimestamp.fromDate(NOW),
      createdBy: 'preesistente',
    });
    await db.collection('dogs').doc(id).update({ fotoCopertinaId: coverId });
  }

  await importPhotos(ctx(db, plan));

  for (const name of SOLO_FOTO) {
    const id = csvDogId(name);
    const dog = (await db.collection('dogs').doc(id).get()).data();
    assert.equal(dog.fotoCopertinaId, `keep_cover_${id}`);
    const photos = await db.collection('photos').where('dogId', '==', id).get();
    assert.ok(photos.size > 1, `${name} deve avere foto Facebook in più`);
    for (const doc of photos.docs) {
      if (doc.id.startsWith('fbphoto_')) {
        assert.equal(doc.data().isCover, false);
      }
    }
  }
});

test('6. --verify: nessuna foto orfana, nessuna copertina inesistente', async () => {
  const photoDir = await ensureGeneratedPhotos();
  const db = new MemoryDb();
  const plan = buildPlan(csvBundle, { photoDir });
  await importDogs(ctx(db, plan));
  await importPhotos(ctx(db, plan));
  const ok = await verifyImport(db);
  assert.equal(ok.ok, true);
  assert.deepEqual(ok.orphanPhotos, []);
  assert.deepEqual(ok.missingCovers, []);

  await db.collection('photos').doc('fbphoto_orfana').set({
    dogId: 'cane_inesistente',
    isCover: false,
    w: 1,
    h: 1,
    mime: 'image/jpeg',
    thumb: Buffer.alloc(0),
    bytesFull: 0,
    createdAt: MemoryTimestamp.fromDate(NOW),
    createdBy: 'import',
  });
  await db.collection('dogs').doc(csvDogId('Orso')).update({
    fotoCopertinaId: 'copertina_fantasma',
  });
  const bad = await verifyImport(db);
  assert.equal(bad.ok, false);
  assert.ok(bad.orphanPhotos.includes('fbphoto_orfana'));
  assert.ok(bad.missingCovers.some((item) => item.fotoCopertinaId === 'copertina_fantasma'));
});

test('7. --restore riporta un cane cancellato a mano', async () => {
  const db = new MemoryDb();
  const plan = buildPlan(csvBundle, { photoDir: join(ROOT, 'import', 'foto') });
  await importDogs(ctx(db, plan));
  const backupDir = mkdtempSync(join(tmpdir(), 'amici-import-bak-'));
  await backupAll(db, backupDir);
  const id = csvDogId('Orso');
  assert.equal((await db.collection('dogs').doc(id).get()).exists, true);
  await db.collection('dogs').doc(id).delete();
  assert.equal((await db.collection('dogs').doc(id).get()).exists, false);
  await restoreAll(db, backupDir, { Timestamp: MemoryTimestamp, dryRun: false });
  const restored = await db.collection('dogs').doc(id).get();
  assert.equal(restored.exists, true);
  assert.equal(restored.data().nome, 'Orso');
});

test('8. backup serializza i bytes delle foto senza esplodere il Buffer', async () => {
  const photoDir = await ensureGeneratedPhotos();
  const db = new MemoryDb();
  const plan = buildPlan(csvBundle, { photoDir });
  await importDogs(ctx(db, plan));
  await importPhotos(ctx(db, plan));
  const backupDir = mkdtempSync(join(tmpdir(), 'amici-import-photo-bak-'));
  await backupAll(db, backupDir);
  const photosJson = JSON.parse(readFileSync(join(backupDir, 'photos.json'), 'utf8'));
  assert.ok(photosJson.length > 0);
  const first = photosJson[0];
  assert.equal(typeof first.data.thumb.__bytes, 'string');
  assert.equal(first.data.thumbB64, undefined);
  assert.equal(typeof first.full.dati.__bytes, 'string');
  assert.equal(first.full.b64, undefined);
  assert.equal(Object.keys(first.data.thumb).join(','), '__bytes');

  const restored = new MemoryDb();
  await restoreAll(restored, backupDir, {
    Timestamp: MemoryTimestamp,
    dryRun: false,
  });
  const live = (await restored.collection('photos').doc(first.id).get()).data();
  assert.ok(Buffer.isBuffer(live.thumb));
  assert.deepEqual(live.thumb, asPhotoBytes(first.data.thumb.__bytes));
});

test('9. WebP vs JPEG attuale: tabella risparmio su 3 immagini', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'amici-webp-cmp-'));
  const large = join(dir, 'camera.jpg');
  const small = join(dir, 'small.jpg');
  const transparent = join(dir, 'alpha.png');

  await sharp({
    create: {
      width: 4000,
      height: 3000,
      channels: 3,
      noise: { type: 'gaussian', mean: 128, sigma: 16 },
    },
  })
    .jpeg({ quality: 90 })
    .toFile(large);

  await sharp({
    create: {
      width: 64,
      height: 48,
      channels: 3,
      background: { r: 21, g: 122, b: 60 },
    },
  })
    .jpeg({ quality: 90 })
    .toFile(small);

  await sharp({
    create: {
      width: 400,
      height: 400,
      channels: 4,
      background: { r: 21, g: 122, b: 60, alpha: 0.4 },
    },
  })
    .png()
    .toFile(transparent);

  const cases = [
    ['foto fotocamera ~4K', large],
    ['immagine già piccola', small],
    ['PNG con trasparenza', transparent],
  ];
  const rows = [];
  const savingsActual = [];
  const savingsSame = [];
  for (const [label, path] of cases) {
    const src = await sharp(path).toBuffer();
    const jpeg = await compressDogPhotoJpegBaseline(path);
    const webp = await compressDogPhoto(path);
    const jpegSame = await sharp(path)
      .rotate()
      .resize({
        width: 1400,
        height: 1400,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .jpeg({ quality: 80, chromaSubsampling: '4:2:0' })
      .toBuffer();
    const vsActual = 1 - webp.full.length / jpeg.full.length;
    const vsSame = 1 - webp.full.length / jpegSame.length;
    savingsActual.push(vsActual);
    savingsSame.push(vsSame);
    assert.ok(webp.full.length <= PHOTO_FULL_MAX_BYTES, `${label} full`);
    assert.ok(webp.thumb.length <= PHOTO_THUMB_MAX_BYTES, `${label} thumb`);
    assert.equal(webp.mime, 'image/webp');
    const longSide = Math.max(webp.width, webp.height);
    assert.ok(longSide <= 1400, `${label} lato ${longSide}`);
    rows.push(
      `${label}\tsrc=${src.length}\tJPEG900=${jpeg.full.length}\tJPEG1400q80=${jpegSame.length}\tWebP=${webp.full.length} thumb=${webp.thumb.length}\tvs900 ${(vsActual * 100).toFixed(1)}%\tvs1400 ${(vsSame * 100).toFixed(1)}%`,
    );
  }
  const avgActual = savingsActual.reduce((a, b) => a + b, 0) / savingsActual.length;
  const avgSame = savingsSame.reduce((a, b) => a + b, 0) / savingsSame.length;
  console.log('STEP4 WebP vs JPEG:');
  for (const row of rows) {
    console.log(row);
  }
  console.log(
    `risparmio medio full: vs JPEG attuale 900px q72 ${(avgActual * 100).toFixed(1)}%; vs JPEG 1400px q80 ${(avgSame * 100).toFixed(1)}%`,
  );
  assert.ok(
    avgSame > 0,
    `A parità di 1400px q80 WebP deve pesare meno del JPEG (media ${avgSame})`,
  );
});

