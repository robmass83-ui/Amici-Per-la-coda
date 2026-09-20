import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  DAY_SCENARIO,
  SHELTER_SCALE,
  projectTraffic,
} from './lib.mjs';

function usageFixture() {
  const dogCount = 20;
  const photoCount = 29;
  const coverCount = 20;
  const avgDog = 3000;
  const avgThumb = 8000;
  const avgFull = 100000;
  const health = 50000;
  const expenses = 10000;
  return {
    collections: {
      dogs: { count: dogCount, bytes: avgDog * dogCount },
      covers: { count: coverCount, bytes: avgThumb * coverCount },
      health: { count: 40, bytes: health },
      boxes: { count: 8, bytes: 2000 },
      appointments: { count: 5, bytes: 4000 },
      adoptions: { count: 5, bytes: 8000 },
      volunteers: { count: 4, bytes: 4000 },
      settings: { count: 1, bytes: 1500 },
      templates: { count: 3, bytes: 90000 },
      photos: { count: photoCount, bytes: avgThumb * photoCount },
      photoFulls: { count: photoCount, bytes: avgFull * photoCount },
      expenses: { count: 10, bytes: expenses },
      weights: { count: 0, bytes: 0 },
      notes: { count: 0, bytes: 0 },
    },
    storedBytes: 1,
    maxDocBytes: avgFull,
    photoCount,
    coverCount,
    fullCount: photoCount,
    dogCount,
    avgDogBytes: avgDog,
    avgThumbBytes: avgThumb,
    avgCoverBytes: avgThumb,
    avgFullBytes: avgFull,
    avgHealthPerDog: health / dogCount,
    avgExpensesPerDog: expenses / dogCount,
    avgWeightsPerDog: 0,
    avgNotesPerDog: 0,
    avgThumbsPerDogWithPhotos: photoCount / coverCount,
    dogsWithPhotos: coverCount,
  };
}

test('la proiezione mensile è la somma delle voci × 30, sotto 1 GiB sul fixture', () => {
  const usage = usageFixture();
  const p = projectTraffic(usage);
  const keepAlive =
    usage.collections.dogs.bytes +
    usage.collections.covers.bytes +
    usage.collections.health.bytes +
    usage.collections.boxes.bytes +
    usage.collections.appointments.bytes +
    usage.collections.adoptions.bytes +
    usage.collections.volunteers.bytes +
    usage.collections.settings.bytes +
    usage.collections.templates.bytes;
  assert.equal(p.keepAliveBytes, keepAlive);
  assert.equal(p.coldBytes, DAY_SCENARIO.coldSessions * keepAlive);
  assert.equal(p.extraListOpens, DAY_SCENARIO.listOpens - DAY_SCENARIO.coldSessions);
  assert.equal(p.listWarmBytes, 0);
  assert.equal(p.sheetBytes, DAY_SCENARIO.sheetOpens * usage.avgExpensesPerDog);
  const gallery =
    DAY_SCENARIO.galleryOpens *
      usage.avgThumbBytes *
      usage.avgThumbsPerDogWithPhotos +
    DAY_SCENARIO.galleryOpens * usage.avgFullBytes;
  assert.equal(p.galleryThumbBytes + p.galleryFullBytes, gallery);
  const day =
    p.coldBytes +
    p.listWarmBytes +
    p.sheetBytes +
    p.galleryThumbBytes +
    p.galleryFullBytes +
    p.uploadEchoBytes +
    p.editEchoBytes;
  assert.equal(p.dayBytes, day);
  assert.equal(p.monthBytes, day * DAY_SCENARIO.daysPerMonth);
  assert.equal(p.underTarget, true);
  assert.ok(p.monthBytes < 1024 * 1024 * 1024);
});

test('lo scale 199/284 usa le medie, non inventa i byte per foto', () => {
  const usage = usageFixture();
  const p = projectTraffic(usage, DAY_SCENARIO, SHELTER_SCALE);
  const covers = usage.avgCoverBytes * Math.min(SHELTER_SCALE.dogs, SHELTER_SCALE.photos);
  assert.ok(p.keepAliveBytes > covers);
  assert.equal(p.underTarget, true);
});
