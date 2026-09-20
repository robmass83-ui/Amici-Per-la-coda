import { test } from 'node:test';
import assert from 'node:assert/strict';

import { buildAnagrafePlan, loadAnagrafeBundle } from './anagrafe.mjs';
import {
  DEFAULT_DOCUMENTI_ZIP,
  DOCUMENT_INLINE_MAX_BYTES,
  EXPECTED_DOCUMENTS,
  buildDocumentiPlan,
  documentChunkCount,
  documentIdOf,
  withExtractedZip,
} from './documenti_cani.mjs';

test('lo zip ha 39 PDF, un chip ciascuno, tutti sotto 700 KB', () => {
  withExtractedZip(DEFAULT_DOCUMENTI_ZIP, (dir) => {
    const plan = buildDocumentiPlan(dir);
    assert.deepEqual(plan.errors, []);
    assert.equal(plan.docs.length, EXPECTED_DOCUMENTS);
    const chips = new Set(plan.docs.map((doc) => doc.microchip));
    assert.equal(chips.size, EXPECTED_DOCUMENTS);
    assert.ok(plan.docs.every((doc) => doc.tipo === 'anagrafe'));
    assert.ok(plan.docs.every((doc) => doc.size > 0));
    assert.ok(plan.docs.every((doc) => doc.size <= DOCUMENT_INLINE_MAX_BYTES));
    assert.ok(plan.docs.every((doc) => documentChunkCount(doc.size) === 0));

    const orso = plan.docs.find((doc) => doc.cane === 'ORSO');
    assert.ok(orso);
    assert.equal(orso.microchip, '380260160527395');
    assert.equal(orso.id, 'anagrafe_380260160527395');
    assert.equal(orso.dataDocumento.toISOString(), '2024-07-15T12:00:00.000Z');
    assert.match(orso.nome, /passaggio/i);

    const totò = plan.docs.find((doc) => doc.microchip === '380260043988168');
    assert.ok(totò);
    assert.equal(totò.cane, "TOTO'");
    assert.match(totò.nome, /Scheda anagrafe/i);

    const dogs = buildAnagrafePlan(loadAnagrafeBundle()).dogs;
    const dogChips = new Set(dogs.map((dog) => dog.microchip));
    for (const doc of plan.docs) {
      assert.equal(doc.id, documentIdOf(doc.microchip));
      assert.ok(dogChips.has(doc.microchip), `chip assente in anagrafe: ${doc.microchip}`);
    }
  });
});
