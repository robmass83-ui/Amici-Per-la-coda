import { existsSync, mkdtempSync, readFileSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

import { ANAGRAFE_AUTHOR, EXPECTED_DOGS, parseItalianNoonUtc } from './anagrafe.mjs';

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));

export const DOCUMENTI_AUTHOR = ANAGRAFE_AUTHOR;
export const EXPECTED_DOCUMENTS = EXPECTED_DOGS;
export const DEFAULT_DOCUMENTI_ZIP = join(
  SCRIPT_DIR,
  '..',
  '..',
  'docs',
  'documenti-cani.zip',
);
export const DOCUMENT_INLINE_MAX_BYTES = 700 * 1024;
export const DOCUMENT_CHUNK_BYTES = 600 * 1024;
export const DOCUMENT_MAX_BYTES = 10 * 1024 * 1024;

export function documentiZipOf(overrideZip) {
  return overrideZip || DEFAULT_DOCUMENTI_ZIP;
}

export function documentIdOf(microchip) {
  return `anagrafe_${String(microchip).trim()}`;
}

export function extractDocumentiZip(zipPath, destDir) {
  if (!existsSync(zipPath)) {
    throw new Error(`Zip non trovato: ${zipPath}`);
  }
  const result = spawnSync('tar', ['-xf', zipPath, '-C', destDir], {
    encoding: 'utf8',
  });
  if (result.status !== 0) {
    throw new Error(result.stderr || result.stdout || 'Estrazione zip fallita');
  }
  return destDir;
}

export function withExtractedZip(zipPath, fn) {
  const dir = mkdtempSync(join(tmpdir(), 'documenti-cani-'));
  try {
    extractDocumentiZip(zipPath, dir);
    return fn(dir);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export async function withExtractedZipAsync(zipPath, fn) {
  const dir = mkdtempSync(join(tmpdir(), 'documenti-cani-'));
  try {
    extractDocumentiZip(zipPath, dir);
    return await fn(dir);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export function loadDocumentiManifest(dir) {
  const jsonPath = join(dir, '_manifest.json');
  if (!existsSync(jsonPath)) {
    throw new Error(`Manca _manifest.json in ${dir}`);
  }
  const raw = JSON.parse(readFileSync(jsonPath, 'utf8'));
  const items = Array.isArray(raw.documenti) ? raw.documenti : [];
  return {
    generato: raw.generato || '',
    fonte: raw.fonte || '',
    items,
  };
}

export function buildDocumentiPlan(dir) {
  const manifest = loadDocumentiManifest(dir);
  const docs = [];
  const chips = new Set();
  const errors = [];

  for (const row of manifest.items) {
    const microchip = String(row.microchip ?? '').trim();
    const file = String(row.file ?? '').trim();
    const tipo = String(row.tipo ?? '').trim() || 'anagrafe';
    const nome = String(row.nomeDocumento ?? '').trim();
    if (!microchip) {
      errors.push(`Riga senza microchip: ${file || nome}`);
      continue;
    }
    if (chips.has(microchip)) {
      errors.push(`Microchip duplicato: ${microchip}`);
      continue;
    }
    chips.add(microchip);
    if (!file) {
      errors.push(`File mancante per ${microchip}`);
      continue;
    }
    const path = join(dir, file);
    if (!existsSync(path)) {
      errors.push(`File assente: ${file}`);
      continue;
    }
    const size = statSync(path).size;
    const declared = Number(row.dimensioneByte);
    if (Number.isFinite(declared) && declared > 0 && declared !== size) {
      errors.push(`${file}: peso ${size} byte, manifest ${declared}`);
    }
    if (size > DOCUMENT_MAX_BYTES) {
      errors.push(`${file}: pesa più di 10 MB`);
    }
    const dataDocumento = parseItalianNoonUtc(row.dataDocumento);
    if (!dataDocumento) {
      errors.push(`${file}: dataDocumento non valida (${row.dataDocumento})`);
    }
    docs.push({
      id: documentIdOf(microchip),
      microchip,
      cane: String(row.cane ?? '').trim(),
      tipo,
      nome,
      mime: 'application/pdf',
      dataDocumento,
      enteEmittente: String(row.enteEmittente ?? '').trim(),
      intestatario: String(row.intestatario ?? '').trim(),
      file,
      path,
      size,
    });
  }

  if (docs.length !== EXPECTED_DOCUMENTS) {
    errors.push(`Attesi ${EXPECTED_DOCUMENTS} documenti, trovati ${docs.length}`);
  }
  return {
    generato: manifest.generato,
    fonte: manifest.fonte,
    docs,
    errors,
  };
}

export function documentChunkCount(byteLength) {
  if (byteLength <= DOCUMENT_INLINE_MAX_BYTES) {
    return 0;
  }
  return Math.ceil(byteLength / DOCUMENT_CHUNK_BYTES);
}

export function splitDocumentBytes(bytes) {
  if (bytes.length <= DOCUMENT_INLINE_MAX_BYTES) {
    return [];
  }
  const chunks = [];
  for (let offset = 0; offset < bytes.length; offset += DOCUMENT_CHUNK_BYTES) {
    chunks.push(bytes.subarray(offset, offset + DOCUMENT_CHUNK_BYTES));
  }
  return chunks;
}
