import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  EXPECTED_DOGS,
  SLUG_ALIASES,
  buildAnagrafePlan,
  loadAnagrafeBundle,
  parseItalianNoonUtc,
  parseSiNo,
  slugDogId,
  titleCaseName,
} from './anagrafe.mjs';

test('il CSV anagrafe ha 39 cani, 39 chip distinti e date a mezzogiorno UTC', () => {
  const plan = buildAnagrafePlan(loadAnagrafeBundle());
  assert.deepEqual(plan.errors, []);
  assert.equal(plan.dogs.length, EXPECTED_DOGS);
  const chips = new Set(plan.dogs.map((dog) => dog.microchip));
  assert.equal(chips.size, EXPECTED_DOGS);
  const orso = plan.dogs.find((dog) => dog.nome === 'Orso');
  assert.ok(orso);
  assert.equal(orso.microchip, '380260160527395');
  assert.equal(orso.sterilizzato, false);
  assert.equal(orso.adottabile, null);
  assert.equal(orso.tipoPelo, 'medio');
  assert.equal(orso.purezza, 'meticcio');
  assert.equal(orso.dataIngressoStimata, true);
  assert.equal(orso.dataIngresso.toISOString(), '2024-07-11T12:00:00.000Z');
  assert.equal(orso.dataApplicazioneChip.toISOString(), '2023-06-17T12:00:00.000Z');
  const wolf = plan.dogs.find((dog) => dog.nome === 'Wolf');
  assert.equal(wolf.razza, 'Pastore Tedesco');
  assert.equal(wolf.purezza, 'in_purezza');
  const totò = plan.dogs.find((dog) => dog.slug === 'toto');
  assert.ok(totò);
  assert.equal(totò.sterilizzato, null);
  assert.equal(plan.fotoRows.length, 0);
  assert.equal(plan.emptyCounts.adottabile, EXPECTED_DOGS);
  assert.ok(plan.emptyCounts.sterilizzato > 0);
  assert.ok(plan.emptyCounts.settore === EXPECTED_DOGS);
});

test('cella vuota non diventa false e il nome si normalizza', () => {
  assert.equal(parseSiNo(''), null);
  assert.equal(parseSiNo('NO'), false);
  assert.equal(parseSiNo('SI'), true);
  assert.equal(titleCaseName("TOTO'"), "Toto'");
  assert.equal(slugDogId("TOTO'"), 'toto');
  assert.equal(SLUG_ALIASES.baileys, 'bailys');
  const noon = parseItalianNoonUtc('11/07/2024');
  assert.equal(noon.getUTCHours(), 12);
});
