import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { parseCsv } from './lib.mjs';

export const ANAGRAFE_AUTHOR = 'anagrafe_import';
export const EXPECTED_DOGS = 39;
export const SLUG_ALIASES = {
  baileys: 'bailys',
  tear: 'tears',
  bianca: 'biamin',
  lois: 'louis',
};

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
export const DEFAULT_ANAGRAFE_DIR = join(SCRIPT_DIR, '..', '..', 'import', 'anagrafe_src');

const EMPTY_REPORT_FIELDS = [
  'pesoKg',
  'settore',
  'box',
  'statoDal',
  'adottabile',
  'sterilizzato',
  'dataSterilizzazione',
  'patologie',
  'conPersone',
  'carattere',
  'slogan',
  'descrizione',
  'noteCarattere',
  'referente',
  'modalitaIngresso',
  'tipoPelo',
  'zonaApplicazioneChip',
  'veterinarioApplicatore',
  'dataIscrizioneAnagrafe',
];

export function anagrafeDirOf(overrideDir) {
  return overrideDir || DEFAULT_ANAGRAFE_DIR;
}

export function loadAnagrafeBundle(dir = DEFAULT_ANAGRAFE_DIR) {
  const cani = rowsOf(join(dir, 'cani.csv'));
  const extra = rowsOf(join(dir, 'anagrafe_extra.csv'));
  const salute = rowsOf(join(dir, 'salute.csv'));
  const foto = rowsOf(join(dir, 'foto.csv'));
  return { cani, extra, salute, foto };
}

function rowsOf(path) {
  let raw = readFileSync(path, 'utf8');
  if (raw.charCodeAt(0) === 0xfeff) {
    raw = raw.slice(1);
  }
  const table = parseCsv(raw);
  if (table.length === 0) {
    return [];
  }
  const header = table[0];
  return table.slice(1).map((row) => {
    const item = {};
    for (let i = 0; i < header.length; i++) {
      item[header[i]] = (row[i] ?? '').trim();
    }
    return item;
  });
}

export function titleCaseName(raw) {
  const lower = String(raw ?? '')
    .trim()
    .toLowerCase();
  return lower.replace(/(^|[\s/'’])\S/g, (chunk) => chunk.toUpperCase());
}

export function slugDogId(nome) {
  const map = {
    à: 'a',
    á: 'a',
    è: 'e',
    é: 'e',
    ì: 'i',
    í: 'i',
    ò: 'o',
    ó: 'o',
    ù: 'u',
    ú: 'u',
    ä: 'a',
    ö: 'o',
    ü: 'u',
    ç: 'c',
    ñ: 'n',
  };
  let out = '';
  for (const char of String(nome).toLowerCase()) {
    out += map[char] ?? char;
  }
  return out.replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

export function parseItalianNoonUtc(raw) {
  if (!raw) {
    return null;
  }
  const parts = String(raw).split('/');
  if (parts.length !== 3) {
    return null;
  }
  const day = Number(parts[0]);
  const month = Number(parts[1]);
  const year = Number(parts[2]);
  if (!Number.isInteger(day) || !Number.isInteger(month) || !Number.isInteger(year)) {
    return null;
  }
  return new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
}

export function parseSiNo(raw) {
  switch (String(raw ?? '').toUpperCase()) {
    case 'SI':
    case 'SÌ':
    case 'YES':
    case 'TRUE':
      return true;
    case 'NO':
    case 'FALSE':
      return false;
    default:
      return null;
  }
}

export function parseDouble(raw) {
  if (!raw) {
    return null;
  }
  const value = Number(String(raw).replace(',', '.'));
  return Number.isFinite(value) ? value : null;
}

function emptyToNull(raw) {
  const value = String(raw ?? '').trim();
  return value === '' ? null : value;
}

export function buildAnagrafePlan(bundle) {
  const extras = new Map();
  for (const row of bundle.extra) {
    extras.set(row.microchip, row);
  }
  const saluteByName = new Map();
  for (const row of bundle.salute) {
    saluteByName.set(row.nome, row);
  }

  const dogs = [];
  const chips = new Set();
  for (const row of bundle.cani) {
    const microchip = emptyToNull(row.microchip);
    if (!microchip) {
      throw new Error(`Riga senza microchip: ${row.nome}`);
    }
    if (chips.has(microchip)) {
      throw new Error(`Microchip duplicato: ${microchip}`);
    }
    chips.add(microchip);
    const extra = extras.get(microchip) ?? {};
    const nome = titleCaseName(row.nome);
    const slug = slugDogId(nome);
    const dataIngresso = parseItalianNoonUtc(row.dataIngresso);
    if (!dataIngresso) {
      throw new Error(`dataIngresso mancante per ${row.nome}`);
    }
    const dataNascita = parseItalianNoonUtc(row.dataNascita);
    const stato = emptyToNull(row.stato) ?? 'in_rifugio';
    const note = emptyToNull(row.noteCarattere) ?? emptyToNull(row.note) ?? '';
    dogs.push({
      slug,
      aliasSlug: SLUG_ALIASES[slug] ?? null,
      microchip,
      nome,
      sesso: emptyToNull(row.sesso),
      dataNascita,
      nascitaPresunta: parseSiNo(row.nascitaPresunta) ?? false,
      razza: emptyToNull(row.razza) ?? '',
      taglia: emptyToNull(row.taglia),
      pesoKg: parseDouble(row.pesoKg),
      mantello: emptyToNull(row.mantello) ?? '',
      iscrittoAnagrafe: emptyToNull(row.iscrittoAnagrafe),
      provenienza: emptyToNull(row.provenienza) ?? '',
      modalitaIngresso: emptyToNull(row.modalitaIngresso),
      dataIngresso,
      settore: emptyToNull(row.settore) ?? '',
      box: emptyToNull(row.box) ?? '',
      stato,
      statoDal: parseItalianNoonUtc(row.statoDal) ?? dataIngresso,
      adottabile: parseSiNo(row.adottabile),
      sterilizzato: parseSiNo(row.sterilizzato),
      dataSterilizzazione: parseItalianNoonUtc(row.dataSterilizzazione),
      patologie: emptyToNull(row.patologie) ?? '',
      conPersone: emptyToNull(row.conPersone),
      conCani: emptyToNull(row.conCani),
      conGatti: emptyToNull(row.conGatti),
      conBambini: emptyToNull(row.conBambini),
      carattere: emptyToNull(row.carattere)
        ? row.carattere
            .split(/[;|]/)
            .map((item) => item.trim())
            .filter(Boolean)
        : [],
      slogan: emptyToNull(row.slogan) ?? '',
      descrizione: emptyToNull(row.descrizione) ?? '',
      noteCarattere: note,
      pubblicato: parseSiNo(row.pubblicato) ?? false,
      tipoPelo: emptyToNull(extra.tipoPelo),
      purezza: emptyToNull(extra.purezza),
      dataApplicazioneChip: parseItalianNoonUtc(extra.dataApplicazioneChip),
      zonaApplicazioneChip: emptyToNull(extra.zonaApplicazioneChip) ?? '',
      veterinarioApplicatore: emptyToNull(extra.veterinarioApplicatore) ?? '',
      dataIscrizioneAnagrafe: parseItalianNoonUtc(extra.dataIscrizioneAnagrafe),
      ultimaUbicazione: emptyToNull(extra.ultimaUbicazione) ?? '',
      dataIngressoStimata: parseSiNo(extra.dataIngressoStimata) ?? false,
      empty: {
        pesoKg: !row.pesoKg,
        settore: !row.settore,
        box: !row.box,
        statoDal: !row.statoDal,
        adottabile: !row.adottabile,
        sterilizzato: !row.sterilizzato,
        dataSterilizzazione: !row.dataSterilizzazione,
        patologie: !row.patologie,
        conPersone: !row.conPersone,
        carattere: !row.carattere,
        slogan: !row.slogan,
        descrizione: !row.descrizione,
        noteCarattere: !row.noteCarattere,
        referente: !row.referente,
        modalitaIngresso: !row.modalitaIngresso,
        tipoPelo: !extra.tipoPelo,
        zonaApplicazioneChip: !extra.zonaApplicazioneChip,
        veterinarioApplicatore: !extra.veterinarioApplicatore,
        dataIscrizioneAnagrafe: !extra.dataIscrizioneAnagrafe,
      },
      salute: saluteByName.get(row.nome) ?? null,
    });
  }

  const emptyCounts = {};
  for (const field of EMPTY_REPORT_FIELDS) {
    emptyCounts[field] = dogs.filter((dog) => dog.empty[field]).length;
  }

  const fotoRows = bundle.foto.filter((row) => row.file || row.cane);
  return {
    dogs,
    emptyCounts,
    fotoRows,
    errors: validatePlan(dogs, bundle),
  };
}

function validatePlan(dogs, bundle) {
  const errors = [];
  if (dogs.length !== EXPECTED_DOGS) {
    errors.push(`Attesi ${EXPECTED_DOGS} cani, trovati ${dogs.length}`);
  }
  if (bundle.salute.length !== EXPECTED_DOGS) {
    errors.push(`Attese ${EXPECTED_DOGS} righe salute, trovate ${bundle.salute.length}`);
  }
  const missingSalute = dogs.filter((dog) => !dog.salute).map((dog) => dog.nome);
  if (missingSalute.length > 0) {
    errors.push(`Salute mancante per: ${missingSalute.join(', ')}`);
  }
  return errors;
}

export function formatEmptyReport(emptyCounts) {
  const lines = ['Campi vuoti (il documento non lo dice):'];
  const entries = Object.entries(emptyCounts).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  for (const [field, count] of entries) {
    if (count === 0) {
      continue;
    }
    lines.push(`  ${field}: ${count}/${EXPECTED_DOGS}`);
  }
  return lines.join('\n');
}

export function keepIfIncomingEmpty(incoming, existing) {
  const incomingEmpty =
    incoming == null || incoming === '' || (Array.isArray(incoming) && incoming.length === 0);
  if (!incomingEmpty) {
    return incoming;
  }
  return existing;
}
