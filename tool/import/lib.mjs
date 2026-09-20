import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import sharp from 'sharp';

export const PHOTO_MAX_PER_DOG = 20;
export const PHOTO_FULL_MAX_SIDE = 1400;
export const PHOTO_FULL_REDUCED_SIDE = 1100;
export const PHOTO_FULL_QUALITY = 80;
export const PHOTO_FULL_MIN_QUALITY = 45;
export const PHOTO_FULL_MAX_BYTES = 450 * 1024;
export const PHOTO_DOCUMENT_MAX_BYTES = 900 * 1024;
export const PHOTO_THUMB_MAX_SIDE = 200;
export const PHOTO_THUMB_QUALITY = 70;
export const PHOTO_THUMB_MAX_BYTES = 12 * 1024;
export const PHOTO_QUALITY_STEP = 5;
export const IMPORT_AUTHOR = 'import';
export const FACEBOOK_STORICO_NOTE =
  'Importato da Facebook, data approssimativa';
export const RIFUGIO_STORICO_NOTE = 'Importato da anagrafe rifugio';
const FALLBACK_DATE = new Date(Date.UTC(2020, 0, 1));
const KNOWN_COLLECTIONS = [
  'dogs',
  'photos',
  'notes',
  'health',
  'weights',
  'expenses',
  'adoptions',
  'adopters',
  'appointments',
  'volunteers',
  'boxes',
  'settings',
  'documents',
  'sponsorships',
  'templates',
];

export class ImportStopError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ImportStopError';
  }
}

export function parseCsv(raw) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < raw.length; i++) {
    const char = raw[i];
    if (inQuotes) {
      if (char === '"') {
        if (raw[i + 1] === '"') {
          field += '"';
          i += 1;
        } else {
          inQuotes = false;
        }
      } else {
        field += char;
      }
    } else if (char === '"') {
      inQuotes = true;
    } else if (char === ',') {
      row.push(field);
      field = '';
    } else if (char === '\n') {
      row.push(field);
      field = '';
      if (row.some((cell) => String(cell).trim() !== '')) {
        rows.push(row);
      }
      row = [];
    } else if (char !== '\r') {
      field += char;
    }
  }
  if (field !== '' || row.length > 0) {
    row.push(field);
    if (row.some((cell) => String(cell).trim() !== '')) {
      rows.push(row);
    }
  }
  return rows;
}

export function csvObjects(raw) {
  const rows = parseCsv(raw);
  if (rows.length === 0) {
    return [];
  }
  const header = rows[0].map((h) => h.trim());
  return rows.slice(1).map((row) => {
    const obj = {};
    for (let i = 0; i < header.length; i++) {
      obj[header[i]] = row[i] ?? '';
    }
    return obj;
  });
}

export function slug(value) {
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
  const lower = String(value ?? '')
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase();
  for (const char of lower) {
    out += map[char] ?? char;
  }
  return out.replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

export function normalizeName(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

export function csvDogId(nome) {
  return `csv_${slug(nome)}`;
}

export function facebookDogId(nFb, nome) {
  return `fb_${Number(nFb)}_${slug(nome)}`;
}

export function photoIdFromFile(fileName) {
  const base = basename(String(fileName ?? '')).replace(/\.[^.]+$/, '');
  return `fbphoto_${slug(base)}`;
}

export function noteIdForDog(dogId) {
  return `note_${dogId}`;
}

function emptyToNull(value) {
  const text = String(value ?? '').trim();
  return text === '' ? null : text;
}

function parseSiNo(value) {
  const text = String(value ?? '').trim().toUpperCase();
  if (text === 'SI' || text === 'SÌ' || text === 'YES' || text === 'TRUE') {
    return true;
  }
  if (text === 'NO' || text === 'FALSE') {
    return false;
  }
  return null;
}

export function parseDate(value) {
  const text = String(value ?? '').trim();
  if (!text) {
    return null;
  }
  const it = text.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (it) {
    return new Date(Date.UTC(Number(it[3]), Number(it[2]) - 1, Number(it[1])));
  }
  const iso = text.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (iso) {
    return new Date(
      Date.UTC(Number(iso[1]), Number(iso[2]) - 1, Number(iso[3])),
    );
  }
  const parsed = new Date(text);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function parseNumber(value) {
  const text = String(value ?? '')
    .trim()
    .replace(',', '.');
  if (!text) {
    return null;
  }
  const n = Number(text);
  return Number.isFinite(n) ? n : null;
}

function parseList(value) {
  const text = String(value ?? '').trim();
  if (!text) {
    return null;
  }
  return text
    .split(/[;|]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function requiredDate(...candidates) {
  for (const value of candidates) {
    if (value instanceof Date && !Number.isNaN(value.getTime())) {
      return value;
    }
  }
  return FALLBACK_DATE;
}

function ts(date, Timestamp) {
  const d = date instanceof Date ? date : new Date(date);
  if (Timestamp?.fromDate) {
    return Timestamp.fromDate(d);
  }
  return { toDate: () => d };
}

function isGroupPhotoPath(filePath) {
  const parts = String(filePath).split(/[/\\]/).map((p) => p.toLowerCase());
  return parts.includes('foto_di_gruppo');
}

export function loadCsvBundle(root) {
  const dir = join(root, 'import');
  return {
    rifugio: csvObjects(readFileSync(join(dir, 'cani_rifugio.csv'), 'utf8')),
    facebook: csvObjects(readFileSync(join(dir, 'cani_facebook.csv'), 'utf8')),
    photos: csvObjects(readFileSync(join(dir, 'foto_facebook.csv'), 'utf8')),
  };
}

export function buildPlan(csv, { photoDir } = {}) {
  const errors = [];
  const rifugio = csv.rifugio.map((row) => {
    const nome = String(row.nome ?? '').trim();
    return {
      id: csvDogId(nome),
      nome,
      row,
      normalized: normalizeName(nome),
    };
  });
  const facebookCrea = [];
  const soloFoto = [];
  for (const row of csv.facebook) {
    const azione = String(row.azione ?? '').trim();
    const nome = String(row.nome ?? '').trim();
    if (azione === 'crea') {
      facebookCrea.push({
        id: facebookDogId(row.nFb, nome),
        nFb: Number(row.nFb),
        nome,
        row,
        normalized: normalizeName(nome),
      });
    } else if (azione === 'solo_foto') {
      const existingName = emptyToNull(row.caneEsistente) ?? nome;
      const match = rifugio.find(
        (dog) => dog.normalized === normalizeName(existingName),
      );
      if (!match) {
        errors.push(
          `solo_foto: cane «${existingName}» non trovato fra i 49 del rifugio`,
        );
      }
      soloFoto.push({
        nome,
        existingName,
        matchId: match?.id ?? null,
        row,
        normalized: normalizeName(existingName),
      });
    } else if (azione) {
      errors.push(`Azione sconosciuta «${azione}» per ${nome}`);
    }
  }

  const nameIndex = new Map();
  for (const dog of rifugio) {
    nameIndex.set(dog.normalized, { id: dog.id, nome: dog.nome, source: 'csv' });
  }
  for (const dog of facebookCrea) {
    nameIndex.set(dog.normalized, { id: dog.id, nome: dog.nome, source: 'fb' });
  }

  const photos = [];
  const missing = [];
  const skippedGroup = [];
  for (const row of csv.photos) {
    const file = String(row.file ?? '').trim();
    const caneNellApp = String(row.caneNellApp ?? row.cane ?? '').trim();
    const abs = photoDir ? join(photoDir, file) : file;
    if (isGroupPhotoPath(abs) || isGroupPhotoPath(file)) {
      skippedGroup.push(file);
      continue;
    }
    const target = nameIndex.get(normalizeName(caneNellApp));
    if (!target) {
      errors.push(`Foto ${file}: cane «${caneNellApp}» non trovato nel piano`);
    }
    const exists = photoDir ? existsSync(abs) : false;
    if (photoDir && !exists) {
      missing.push(file);
    }
    photos.push({
      file,
      path: abs,
      caneNellApp,
      copertina: String(row.copertina ?? '').trim().toUpperCase() === 'SI',
      ordine: Number(row.ordine ?? 0) || 0,
      dogId: target?.id ?? null,
      photoId: photoIdFromFile(file),
      missing: photoDir ? !exists : false,
    });
  }

  return {
    rifugio,
    facebookCrea,
    soloFoto,
    photos,
    missing,
    skippedGroup,
    errors,
    counts: {
      rifugio: rifugio.length,
      facebookCrea: facebookCrea.length,
      soloFoto: soloFoto.length,
      photos: photos.length,
    },
  };
}

async function getDoc(db, col, id) {
  const snap = await db.collection(col).doc(id).get();
  if (!snap.exists) {
    return null;
  }
  return snap.data();
}

export async function countCollection(db, col) {
  const snap = await db.collection(col).get();
  return snap.size;
}

async function loadDogsByNormalizedName(db) {
  const snap = await db.collection('dogs').get();
  const map = new Map();
  for (const doc of snap.docs) {
    const data = doc.data();
    map.set(normalizeName(data.nome ?? ''), { id: doc.id, data });
  }
  return map;
}

function assertWritable(ctx) {
  if (ctx.dryRun) {
    throw new Error('dry-run: tentativo di scrittura su Firestore');
  }
}

function preserveAuditAndCover(existing, doc) {
  if (!existing) {
    return doc;
  }
  return {
    ...doc,
    fotoCopertinaId: existing.fotoCopertinaId ?? doc.fotoCopertinaId ?? null,
    createdAt: existing.createdAt ?? doc.createdAt,
    createdBy: existing.createdBy ?? doc.createdBy,
    storicoStati: existing.storicoStati ?? doc.storicoStati,
  };
}

export function rifugioDogDocument(row, { now, Timestamp, existing }) {
  const nome = String(row.nome ?? '').trim();
  const dataNascita = parseDate(row.dataNascita);
  const dataIngresso = requiredDate(
    parseDate(row.dataIngresso),
    dataNascita,
    parseDate(row.statoDal),
  );
  const statoDal = requiredDate(parseDate(row.statoDal), dataIngresso);
  const stato = emptyToNull(row.stato) ?? 'in_rifugio';
  const doc = {
    nome,
    sesso: emptyToNull(row.sesso),
    dataNascita: dataNascita ? ts(dataNascita, Timestamp) : null,
    nascitaPresunta: parseSiNo(row.nascitaPresunta),
    razza: emptyToNull(row.razza),
    taglia: emptyToNull(row.taglia),
    pesoKg: parseNumber(row.pesoKg),
    mantello: emptyToNull(row.mantello),
    microchip: emptyToNull(row.microchip),
    iscrittoAnagrafe: emptyToNull(row.iscrittoAnagrafe),
    provenienza: emptyToNull(row.provenienza),
    modalitaIngresso: emptyToNull(row.modalitaIngresso),
    dataIngresso: ts(dataIngresso, Timestamp),
    settore: emptyToNull(row.settore),
    box: emptyToNull(row.box),
    stato,
    statoDal: ts(statoDal, Timestamp),
    adottabile: parseSiNo(row.adottabile),
    sterilizzato: parseSiNo(row.sterilizzato),
    dataSterilizzazione: parseDate(row.dataSterilizzazione)
      ? ts(parseDate(row.dataSterilizzazione), Timestamp)
      : null,
    slogan: emptyToNull(row.slogan),
    descrizione: emptyToNull(row.descrizione),
    carattere: parseList(row.carattere),
    conPersone: emptyToNull(row.conPersone),
    conCani: emptyToNull(row.conCani),
    conGatti: emptyToNull(row.conGatti),
    conBambini: emptyToNull(row.conBambini),
    noteCarattere: emptyToNull(row.noteCarattere),
    fotoCopertinaId: null,
    referenteId: null,
    pubblicato: parseSiNo(row.pubblicato),
    dataPubblicazione: null,
    archiviato: false,
    storicoStati: [
      {
        stato,
        dal: ts(statoDal, Timestamp),
        note: RIFUGIO_STORICO_NOTE,
        autoreId: IMPORT_AUTHOR,
        strutturaDestinazione: null,
      },
    ],
    createdAt: ts(now, Timestamp),
    createdBy: IMPORT_AUTHOR,
    updatedAt: ts(now, Timestamp),
    updatedBy: IMPORT_AUTHOR,
  };
  return preserveAuditAndCover(existing, doc);
}

export function facebookDogDocument(row, { now, Timestamp, existing }) {
  const nome = String(row.nome ?? '').trim();
  const stato = emptyToNull(row.stato) ?? 'in_rifugio';
  const statoDal = requiredDate(parseDate(row.statoDal));
  const doc = {
    nome,
    sesso: null,
    dataNascita: null,
    nascitaPresunta: null,
    razza: null,
    taglia: null,
    pesoKg: null,
    mantello: null,
    microchip: null,
    iscrittoAnagrafe: null,
    provenienza: null,
    modalitaIngresso: null,
    dataIngresso: ts(statoDal, Timestamp),
    settore: null,
    box: null,
    stato,
    statoDal: ts(statoDal, Timestamp),
    adottabile: null,
    sterilizzato: null,
    dataSterilizzazione: null,
    slogan: null,
    descrizione: emptyToNull(row.descrizione),
    carattere: null,
    conPersone: null,
    conCani: null,
    conGatti: null,
    conBambini: null,
    noteCarattere: null,
    fotoCopertinaId: null,
    referenteId: null,
    pubblicato: null,
    dataPubblicazione: null,
    archiviato: parseSiNo(row.archiviato) ?? false,
    storicoStati: [
      {
        stato,
        dal: ts(statoDal, Timestamp),
        note: FACEBOOK_STORICO_NOTE,
        autoreId: IMPORT_AUTHOR,
        strutturaDestinazione: null,
      },
    ],
    createdAt: ts(now, Timestamp),
    createdBy: IMPORT_AUTHOR,
    updatedAt: ts(now, Timestamp),
    updatedBy: IMPORT_AUTHOR,
  };
  return preserveAuditAndCover(existing, doc);
}

function noteDocument(dogId, testo, { now, Timestamp }) {
  return {
    dogId,
    tipo: 'generale',
    testo,
    autoreId: IMPORT_AUTHOR,
    createdAt: ts(now, Timestamp),
  };
}

export async function hasImportIds(db) {
  const snap = await db.collection('dogs').get();
  return snap.docs.filter(
    (doc) => doc.id.startsWith('csv_') || doc.id.startsWith('fb_'),
  );
}

export async function importDogs(ctx) {
  const { db, plan, now, Timestamp, dryRun } = ctx;
  const phase = ctx.phase ?? 'all';
  const doRifugio = phase === 'all' || phase === 'rifugio';
  const doFacebook = phase === 'all' || phase === 'facebook';
  const stats = {
    created: 0,
    updated: 0,
    soloFoto: 0,
    notes: 0,
    errors: [...plan.errors],
  };

  if (dryRun) {
    if (doFacebook) {
      for (const item of plan.soloFoto) {
        if (!item.matchId) {
          throw new ImportStopError(
            `solo_foto: cane «${item.existingName}» non trovato. Script fermato.`,
          );
        }
        stats.soloFoto += 1;
      }
    }
    if (doRifugio) {
      stats.created += plan.rifugio.length;
    }
    if (doFacebook) {
      stats.created += plan.facebookCrea.length;
    }
    return stats;
  }

  for (const item of doRifugio ? plan.rifugio : []) {
    const existing = await getDoc(db, 'dogs', item.id);
    const doc = rifugioDogDocument(item.row, { now, Timestamp, existing });
    assertWritable(ctx);
    await db.collection('dogs').doc(item.id).set(doc);
    const nota = emptyToNull(item.row.note);
    if (nota) {
      await db
        .collection('notes')
        .doc(noteIdForDog(item.id))
        .set(noteDocument(item.id, nota, { now, Timestamp }));
      stats.notes += 1;
    }
    if (existing) {
      stats.updated += 1;
    } else {
      stats.created += 1;
    }
  }

  if (doFacebook) {
    const byName = await loadDogsByNormalizedName(db);
    for (const item of plan.soloFoto) {
      const found = byName.get(item.normalized);
      if (!found) {
        throw new ImportStopError(
          `solo_foto: cane «${item.existingName}» non trovato. Script fermato.`,
        );
      }
      stats.soloFoto += 1;
    }
  }

  for (const item of doFacebook ? plan.facebookCrea : []) {
    const existing = await getDoc(db, 'dogs', item.id);
    const doc = facebookDogDocument(item.row, { now, Timestamp, existing });
    assertWritable(ctx);
    await db.collection('dogs').doc(item.id).set(doc);
    const nota = emptyToNull(item.row.nota);
    if (nota) {
      await db
        .collection('notes')
        .doc(noteIdForDog(item.id))
        .set(noteDocument(item.id, nota, { now, Timestamp }));
      stats.notes += 1;
    }
    if (existing) {
      stats.updated += 1;
    } else {
      stats.created += 1;
    }
  }

  return stats;
}

export async function compressDogPhoto(filePath) {
  const image = sharp(filePath).rotate();
  let quality = PHOTO_FULL_QUALITY;
  let side = PHOTO_FULL_MAX_SIDE;
  let full;
  while (true) {
    full = await image
      .clone()
      .resize({
        width: side,
        height: side,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .webp({ quality })
      .toBuffer();
    if (full.length <= PHOTO_FULL_MAX_BYTES) {
      break;
    }
    if (quality > PHOTO_FULL_MIN_QUALITY) {
      quality -= PHOTO_QUALITY_STEP;
      continue;
    }
    if (side > PHOTO_FULL_REDUCED_SIDE) {
      side = PHOTO_FULL_REDUCED_SIDE;
      continue;
    }
    break;
  }
  const fullMeta = await sharp(full).metadata();
  let thumbQuality = PHOTO_THUMB_QUALITY;
  let thumbSide = PHOTO_THUMB_MAX_SIDE;
  let thumb;
  while (true) {
    thumb = await image
      .clone()
      .resize({
        width: thumbSide,
        height: thumbSide,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .webp({ quality: thumbQuality })
      .toBuffer();
    if (thumb.length <= PHOTO_THUMB_MAX_BYTES) {
      break;
    }
    if (thumbQuality > PHOTO_FULL_MIN_QUALITY) {
      thumbQuality -= PHOTO_QUALITY_STEP;
      continue;
    }
    if (thumbSide <= 40) {
      break;
    }
    thumbSide = Math.max(40, Math.round(thumbSide * 0.85));
  }
  return {
    full,
    thumb,
    width: fullMeta.width ?? 0,
    height: fullMeta.height ?? 0,
    mime: 'image/webp',
  };
}

export async function compressDogPhotoJpegBaseline(filePath) {
  const image = sharp(filePath).rotate();
  const full = await image
    .clone()
    .resize({
      width: 900,
      height: 900,
      fit: 'inside',
      withoutEnlargement: true,
    })
    .jpeg({ quality: 72, chromaSubsampling: '4:2:0' })
    .toBuffer();
  const thumb = await image
    .clone()
    .resize({
      width: 160,
      height: 160,
      fit: 'inside',
      withoutEnlargement: true,
    })
    .jpeg({ quality: 60, chromaSubsampling: '4:2:0' })
    .toBuffer();
  return { full, thumb };
}

async function countPhotosForDog(db, dogId) {
  const snap = await db.collection('photos').where('dogId', '==', dogId).get();
  return snap.docs;
}

export async function importPhotos(ctx) {
  const { db, plan, now, Timestamp, dryRun } = ctx;
  const stats = {
    imported: 0,
    updated: 0,
    missing: [...plan.missing],
    overLimit: [],
    skippedGroup: [...plan.skippedGroup],
    bytesWritten: 0,
    errors: [],
  };
  if (dryRun) {
    stats.imported = plan.photos.filter((p) => !p.missing).length;
    return stats;
  }

  const dogs = await loadDogsByNormalizedName(db);
  const ordered = [...plan.photos].sort((a, b) => {
    const name = a.caneNellApp.localeCompare(b.caneNellApp, 'it');
    if (name !== 0) {
      return name;
    }
    return a.ordine - b.ordine;
  });

  const photoDocsByDog = new Map();
  async function photosOf(dogId) {
    if (!photoDocsByDog.has(dogId)) {
      photoDocsByDog.set(dogId, await countPhotosForDog(db, dogId));
    }
    return photoDocsByDog.get(dogId);
  }

  for (const item of ordered) {
    if (item.missing) {
      continue;
    }
    const found = dogs.get(normalizeName(item.caneNellApp));
    if (!found) {
      throw new ImportStopError(
        `Foto ${item.file}: cane «${item.caneNellApp}» non trovato. Script fermato.`,
      );
    }
    const dogId = found.id;
    const existingPhotos = await photosOf(dogId);
    const already = existingPhotos.find((doc) => doc.id === item.photoId);
    if (!already && existingPhotos.length >= PHOTO_MAX_PER_DOG) {
      stats.overLimit.push(`${item.file} (${item.caneNellApp})`);
      continue;
    }

    const compressed = await compressDogPhoto(item.path);
    const currentCover = found.data.fotoCopertinaId ?? null;
    let isCover = false;
    if (item.copertina) {
      if (currentCover && currentCover !== item.photoId) {
        isCover = false;
      } else {
        isCover = true;
      }
    }

    const photoDoc = {
      dogId,
      isCover,
      w: compressed.width,
      h: compressed.height,
      mime: compressed.mime,
      thumb: Buffer.from(compressed.thumb),
      bytesFull: compressed.full.length,
      createdAt: already?.data()?.createdAt ?? ts(now, Timestamp),
      createdBy: IMPORT_AUTHOR,
    };
    const fullDoc = { dati: Buffer.from(compressed.full) };
    if (compressed.full.length > PHOTO_FULL_MAX_BYTES) {
      stats.errors.push(
        `${item.file}: full ${compressed.full.length} oltre il limite`,
      );
      continue;
    }
    try {
      ensurePhotoDocumentFits(photoDoc);
      ensurePhotoDocumentFits(fullDoc);
    } catch (err) {
      stats.errors.push(`${item.file}: ${err.message}`);
      continue;
    }

    assertWritable(ctx);
    const batch = db.batch();
    const photoRef = db.collection('photos').doc(item.photoId);
    batch.set(photoRef, photoDoc);
    batch.set(photoRef.collection('full').doc('data'), fullDoc);
    if (isCover) {
      for (const other of existingPhotos) {
        if (other.id !== item.photoId && other.data().isCover) {
          batch.update(other.ref, { isCover: false });
        }
      }
      batch.update(db.collection('dogs').doc(dogId), {
        fotoCopertinaId: item.photoId,
      });
      found.data.fotoCopertinaId = item.photoId;
    }
    await batch.commit();
    stats.bytesWritten += compressed.full.length + compressed.thumb.length;
    if (already) {
      stats.updated += 1;
    } else {
      stats.imported += 1;
      existingPhotos.push({
        id: item.photoId,
        data: () => photoDoc,
        ref: photoRef,
      });
    }
  }
  return stats;
}

export async function verifyImport(db) {
  const dogsSnap = await db.collection('dogs').get();
  const photosSnap = await db.collection('photos').get();
  const dogIds = new Set(dogsSnap.docs.map((d) => d.id));
  const photoIds = new Set(photosSnap.docs.map((d) => d.id));
  const orphanPhotos = [];
  for (const doc of photosSnap.docs) {
    const dogId = doc.data().dogId;
    if (!dogIds.has(dogId)) {
      orphanPhotos.push(doc.id);
    }
  }
  const missingCovers = [];
  for (const doc of dogsSnap.docs) {
    const cover = doc.data().fotoCopertinaId;
    if (cover && !photoIds.has(cover)) {
      missingCovers.push({ dogId: doc.id, fotoCopertinaId: cover });
    }
  }
  return {
    dogs: dogsSnap.size,
    photos: photosSnap.size,
    orphanPhotos,
    missingCovers,
    ok: orphanPhotos.length === 0 && missingCovers.length === 0,
  };
}

function isByteArray(value) {
  return Buffer.isBuffer(value) || value instanceof Uint8Array;
}

function firestoreValueBytes(value) {
  if (value == null) {
    return 1;
  }
  if (
    typeof value.toUint8Array === 'function' &&
    typeof value.toDate !== 'function'
  ) {
    return asPhotoBytes(value).length;
  }
  if (isByteArray(value)) {
    return value.length;
  }
  if (typeof value === 'string') {
    return value.length;
  }
  if (typeof value === 'boolean') {
    return 1;
  }
  if (typeof value === 'number') {
    return 8;
  }
  if (typeof value?.toDate === 'function' || value instanceof Date) {
    return 8;
  }
  if (Array.isArray(value)) {
    return value.reduce((sum, item) => sum + firestoreValueBytes(item), 0);
  }
  if (typeof value === 'object') {
    return firestoreMapBytes(value);
  }
  return 8;
}

function firestoreMapBytes(map) {
  let total = 0;
  for (const [key, nested] of Object.entries(map)) {
    total += key.length + firestoreValueBytes(nested);
  }
  return total;
}

function ensurePhotoDocumentFits(data) {
  if (firestoreMapBytes(data) > PHOTO_DOCUMENT_MAX_BYTES) {
    throw new Error('La foto è troppo grande per essere salvata.');
  }
}

export function asPhotoBytes(value) {
  if (value == null) {
    return Buffer.alloc(0);
  }
  if (isByteArray(value)) {
    return Buffer.from(value);
  }
  if (typeof value.toUint8Array === 'function') {
    return Buffer.from(value.toUint8Array());
  }
  if (typeof value === 'string' && value.length) {
    return Buffer.from(value, 'base64');
  }
  return Buffer.alloc(0);
}

export const MIGRATE_PHOTOS_BATCH = 20;

export function isWebpBuffer(value) {
  const buf = asPhotoBytes(value);
  return (
    buf.length >= 12 &&
    buf.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buf.subarray(8, 12).toString('ascii') === 'WEBP'
  );
}

export function photoMigrationAction(data, fullData) {
  const fullBytes = asPhotoBytes(fullData?.dati ?? fullData?.b64);
  if (fullBytes.length === 0) {
    return 'missing_full';
  }
  const thumbBytes = asPhotoBytes(data?.thumb ?? data?.thumbB64);
  const storedAsBytes =
    isByteArray(data?.thumb) && isByteArray(fullData?.dati);
  const hasLegacy =
    (typeof data?.thumbB64 === 'string' && data.thumbB64.length > 0) ||
    (typeof fullData?.b64 === 'string' && fullData.b64.length > 0);
  const alreadyWebp =
    data?.mime === 'image/webp' &&
    storedAsBytes &&
    isWebpBuffer(fullBytes) &&
    (thumbBytes.length === 0 || isWebpBuffer(thumbBytes));
  if (alreadyWebp) {
    return hasLegacy ? 'strip_legacy' : 'skip';
  }
  return 'recompress';
}

function photoPayloadBytes(data, fullData) {
  return (
    firestoreMapBytes(data ?? {}) + firestoreMapBytes(fullData ?? {})
  );
}

function loadMigrateState(path) {
  if (!path || !existsSync(path)) {
    return { done: [], errors: [] };
  }
  try {
    const raw = JSON.parse(readFileSync(path, 'utf8'));
    return {
      done: Array.isArray(raw.done) ? raw.done : [],
      errors: Array.isArray(raw.errors) ? raw.errors : [],
    };
  } catch (_) {
    return { done: [], errors: [] };
  }
}

function saveMigrateState(path, state) {
  if (!path) {
    return;
  }
  writeFileSync(
    path,
    JSON.stringify(
      {
        updatedAt: new Date().toISOString(),
        done: state.done,
        errors: state.errors,
      },
      null,
      2,
    ),
  );
}

async function readFullData(db, photoId) {
  const snap = await db
    .collection('photos')
    .doc(photoId)
    .collection('full')
    .doc('data')
    .get();
  if (!snap.exists) {
    return null;
  }
  return snap.data();
}

function mb(bytes) {
  return bytes / (1024 * 1024);
}

/**
 * STEP 5: JPEG/base64 → WebP Blob, poi fotoCount. Idempotente, a blocchi di 20.
 */
export async function migratePhotos({
  db,
  dryRun = false,
  limit = 0,
  statePath,
  log = () => {},
  shouldStop = () => false,
} = {}) {
  const stats = {
    total: 0,
    skipped: 0,
    converted: 0,
    stripped: 0,
    missingFull: 0,
    errors: [],
    bytesBefore: 0,
    bytesAfter: 0,
    fotoCountUpdated: 0,
    fotoCountWouldUpdate: 0,
    stopped: false,
  };
  const photosSnap = await db.collection('photos').get();
  const docs = [...photosSnap.docs].sort((a, b) => a.id.localeCompare(b.id));
  stats.total = docs.length;
  const state = dryRun ? { done: [], errors: [] } : loadMigrateState(statePath);
  const doneSet = new Set(state.done);
  let processed = 0;
  let inBatch = 0;
  let batchIndex = 0;

  for (const doc of docs) {
    if (shouldStop()) {
      stats.stopped = true;
      log('Interrotto: lo stato è salvato, si può riprendere.');
      break;
    }
    if (limit > 0 && processed >= limit) {
      break;
    }
    const data = doc.data();
    let fullData;
    try {
      fullData = await readFullData(db, doc.id);
    } catch (err) {
      stats.errors.push({ id: doc.id, message: err.message || String(err) });
      log(`  ${doc.id}: errore lettura full (${err.message})`);
      continue;
    }
    const before = photoPayloadBytes(data, fullData ?? {});
    const action = photoMigrationAction(data, fullData);
    if (action === 'skip' || doneSet.has(doc.id)) {
      stats.skipped += 1;
      stats.bytesBefore += before;
      stats.bytesAfter += before;
      if (!dryRun && !doneSet.has(doc.id) && action === 'skip') {
        doneSet.add(doc.id);
        state.done.push(doc.id);
      }
      continue;
    }
    if (action === 'missing_full') {
      stats.missingFull += 1;
      stats.errors.push({ id: doc.id, message: 'full mancante o illeggibile' });
      log(`  ${doc.id}: full mancante, salto`);
      continue;
    }

    processed += 1;
    inBatch += 1;
    try {
      const result = await migrateOnePhoto(db, doc, data, fullData, {
        dryRun,
        action,
      });
      stats.bytesBefore += result.beforeBytes;
      stats.bytesAfter += result.afterBytes;
      if (result.status === 'converted') {
        stats.converted += 1;
      } else {
        stats.stripped += 1;
      }
      log(
        `  [${processed}${limit ? `/${limit}` : ''}] ${doc.id} ${result.status} ` +
          `${(result.beforeBytes / 1024).toFixed(1)} KB → ${(result.afterBytes / 1024).toFixed(1)} KB`,
      );
      if (!dryRun) {
        doneSet.add(doc.id);
        state.done.push(doc.id);
      }
    } catch (err) {
      stats.errors.push({ id: doc.id, message: err.message || String(err) });
      state.errors.push({ id: doc.id, message: err.message || String(err) });
      log(`  ${doc.id}: ${err.message || err}`);
    }
    if (inBatch >= MIGRATE_PHOTOS_BATCH) {
      batchIndex += 1;
      inBatch = 0;
      log(`Blocco ${batchIndex} (20 foto) completato.`);
      if (!dryRun) {
        saveMigrateState(statePath, state);
      }
    }
  }
  if (!dryRun) {
    saveMigrateState(statePath, state);
  }

  const countStats = await backfillFotoCount(db, { dryRun });
  stats.fotoCountUpdated = countStats.updated;
  stats.fotoCountWouldUpdate = countStats.wouldUpdate;
  stats.mbBefore = mb(stats.bytesBefore);
  stats.mbAfter = mb(stats.bytesAfter);
  return stats;
}

async function migrateOnePhoto(db, doc, data, fullData, { dryRun, action }) {
  const beforeBytes = photoPayloadBytes(data, fullData ?? {});
  const photoRef = db.collection('photos').doc(doc.id);
  const fullRef = photoRef.collection('full').doc('data');

  let nextPhoto = { ...data };
  let nextFull = { ...(fullData ?? {}) };

  if (action === 'recompress') {
    const source = asPhotoBytes(fullData?.dati ?? fullData?.b64);
    const compressed = await compressDogPhoto(source);
    nextPhoto = {
      ...data,
      thumb: Buffer.from(compressed.thumb),
      mime: compressed.mime,
      w: compressed.width,
      h: compressed.height,
      bytesFull: compressed.full.length,
    };
    nextFull = {
      ...(fullData ?? {}),
      dati: Buffer.from(compressed.full),
    };
  }

  ensurePhotoDocumentFits(nextPhoto);
  ensurePhotoDocumentFits({ dati: nextFull.dati });
  if (dryRun) {
    const cleanedPhoto = { ...nextPhoto };
    const cleanedFull = { ...nextFull };
    delete cleanedPhoto.thumbB64;
    delete cleanedFull.b64;
    return {
      status: action === 'recompress' ? 'converted' : 'stripped',
      beforeBytes,
      afterBytes: photoPayloadBytes(cleanedPhoto, cleanedFull),
    };
  }

  await photoRef.set(nextPhoto);
  await fullRef.set(nextFull);

  const check = await photoRef.get();
  const checkFull = await fullRef.get();
  const thumbBytes = asPhotoBytes(check.data()?.thumb);
  const datiBytes = asPhotoBytes(checkFull.data()?.dati);
  if (thumbBytes.length === 0 || datiBytes.length === 0) {
    throw new Error('verifica: thumb o dati vuoti dopo la scrittura');
  }
  await sharp(thumbBytes).metadata();
  await sharp(datiBytes).metadata();
  if (!isWebpBuffer(datiBytes) || !isWebpBuffer(thumbBytes)) {
    throw new Error('verifica: i bytes scritti non sono WebP');
  }

  const cleanedPhoto = { ...check.data() };
  const cleanedFull = { ...checkFull.data() };
  delete cleanedPhoto.thumbB64;
  delete cleanedFull.b64;
  await photoRef.set(cleanedPhoto);
  await fullRef.set(cleanedFull);
  return {
    status: action === 'recompress' ? 'converted' : 'stripped',
    beforeBytes,
    afterBytes: photoPayloadBytes(cleanedPhoto, cleanedFull),
  };
}

async function backfillFotoCount(db, { dryRun }) {
  const photosSnap = await db.collection('photos').get();
  const dogsSnap = await db.collection('dogs').get();
  const counts = new Map();
  for (const doc of photosSnap.docs) {
    const dogId = doc.data()?.dogId;
    if (!dogId) {
      continue;
    }
    counts.set(dogId, (counts.get(dogId) ?? 0) + 1);
  }
  let updated = 0;
  let wouldUpdate = 0;
  const pending = [];
  for (const doc of dogsSnap.docs) {
    const next = counts.get(doc.id) ?? 0;
    const current = Number(doc.data()?.fotoCount ?? 0);
    if (current === next) {
      continue;
    }
    wouldUpdate += 1;
    if (!dryRun) {
      pending.push({ ref: doc.ref ?? db.collection('dogs').doc(doc.id), next });
    }
  }
  if (dryRun) {
    return { updated: 0, wouldUpdate };
  }
  const batchSize = 400;
  for (let i = 0; i < pending.length; i += batchSize) {
    const chunk = pending.slice(i, i + batchSize);
    const batch = db.batch();
    for (const item of chunk) {
      batch.update(item.ref, { fotoCount: item.next });
    }
    await batch.commit();
    updated += chunk.length;
  }
  return { updated, wouldUpdate };
}

function serializeValue(value) {
  if (value == null) {
    return value;
  }
  if (isByteArray(value)) {
    return { __bytes: Buffer.from(value).toString('base64') };
  }
  if (typeof value.toDate === 'function') {
    return { __ts: value.toDate().toISOString() };
  }
  if (value instanceof Date) {
    return { __ts: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return value.map(serializeValue);
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = serializeValue(v);
    }
    return out;
  }
  return value;
}

function reviveValue(value, Timestamp) {
  if (value == null) {
    return value;
  }
  if (typeof value === 'object' && value.__bytes) {
    return Buffer.from(value.__bytes, 'base64');
  }
  if (typeof value === 'object' && value.__ts) {
    return ts(new Date(value.__ts), Timestamp);
  }
  if (Array.isArray(value)) {
    return value.map((item) => reviveValue(item, Timestamp));
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = reviveValue(v, Timestamp);
    }
    return out;
  }
  return value;
}

export async function backupAll(db, dir) {
  mkdirSync(dir, { recursive: true });
  const listed = await db.listCollections();
  const names = new Set(KNOWN_COLLECTIONS);
  for (const col of listed) {
    names.add(col.id);
  }
  const manifest = { collections: [] };
  for (const name of [...names].sort()) {
    const snap = await db.collection(name).get();
    const docs = [];
    for (const doc of snap.docs) {
      const entry = { id: doc.id, data: serializeValue(doc.data()) };
      if (name === 'photos') {
        const full = await db
          .collection('photos')
          .doc(doc.id)
          .collection('full')
          .doc('data')
          .get();
        if (full.exists) {
          entry.full = serializeValue(full.data());
        }
      }
      if (name === 'documents') {
        const chunks = await db
          .collection('documents')
          .doc(doc.id)
          .collection('chunks')
          .get();
        if (chunks.size) {
          entry.chunks = chunks.docs.map((chunk) => ({
            id: chunk.id,
            data: serializeValue(chunk.data()),
          }));
        }
      }
      docs.push(entry);
    }
    writeFileSync(join(dir, `${name}.json`), JSON.stringify(docs, null, 2));
    manifest.collections.push({ name, count: docs.length });
  }
  writeFileSync(join(dir, 'manifest.json'), JSON.stringify(manifest, null, 2));
  return manifest;
}

export async function restoreAll(db, dir, { Timestamp, dryRun } = {}) {
  if (dryRun) {
    return { restored: 0, deleted: 0 };
  }
  assertWritable({ dryRun });
  const files = readdirSync(dir).filter(
    (name) => name.endsWith('.json') && name !== 'manifest.json',
  );
  let restored = 0;
  let deleted = 0;
  for (const file of files) {
    const col = file.replace(/\.json$/, '');
    const docs = JSON.parse(readFileSync(join(dir, file), 'utf8'));
    const keep = new Set(docs.map((entry) => entry.id));
    for (const entry of docs) {
      await db
        .collection(col)
        .doc(entry.id)
        .set(reviveValue(entry.data, Timestamp));
      restored += 1;
      if (entry.full) {
        await db
          .collection(col)
          .doc(entry.id)
          .collection('full')
          .doc('data')
          .set(reviveValue(entry.full, Timestamp));
      }
      if (entry.chunks) {
        for (const chunk of entry.chunks) {
          await db
            .collection(col)
            .doc(entry.id)
            .collection('chunks')
            .doc(chunk.id)
            .set(reviveValue(chunk.data, Timestamp));
        }
      }
    }
    const live = await db.collection(col).get();
    let batch = db.batch();
    let ops = 0;
    const flush = async () => {
      if (ops === 0) {
        return;
      }
      await batch.commit();
      batch = db.batch();
      ops = 0;
    };
    for (const doc of live.docs) {
      if (keep.has(doc.id)) {
        continue;
      }
      if (col === 'photos') {
        batch.delete(
          db.collection(col).doc(doc.id).collection('full').doc('data'),
        );
        ops += 1;
      }
      if (col === 'documents') {
        const chunks = await db
          .collection(col)
          .doc(doc.id)
          .collection('chunks')
          .get();
        for (const chunk of chunks.docs) {
          batch.delete(chunk.ref);
          ops += 1;
          if (ops >= 400) {
            await flush();
          }
        }
      }
      batch.delete(doc.ref);
      ops += 1;
      deleted += 1;
      if (ops >= 400) {
        await flush();
      }
    }
    await flush();
  }
  return { restored, deleted };
}

export function formatReport(report) {
  const lines = [];
  lines.push(`# Rapporto importazione ${report.dateLabel}${report.dryRun ? ' — dry-run' : ''}`);
  lines.push('');
  lines.push(`Tempo: ${report.elapsedMs} ms`);
  lines.push(
    report.dryRun
      ? 'Scritture: nessuna (dry-run)'
      : `Scritture: sì · ${report.mbWritten.toFixed(2)} MB`,
  );
  if (report.forceWarning) {
    lines.push('');
    lines.push(`⚠️ ${report.forceWarning}`);
  }
  lines.push('');
  lines.push('## Cani');
  lines.push(`- Da creare (rifugio CSV): ${report.counts.rifugio}`);
  lines.push(`- Da creare (Facebook, azione=crea): ${report.counts.facebookCrea}`);
  lines.push(
    `- Solo foto (nessun documento dogs, nessun campo toccato): ${report.counts.soloFoto}`,
  );
  lines.push(`- Creati in questa esecuzione: ${report.dogs.created}`);
  lines.push(`- Aggiornati (stesso id, idempotente): ${report.dogs.updated}`);
  lines.push(`- Note scritte: ${report.dogs.notes}`);
  lines.push(`- Errori: ${report.errors.length}`);
  if (report.soloFotoMatches?.length) {
    lines.push('');
    lines.push('### Solo foto (risolti per nome normalizzato)');
    for (const item of report.soloFotoMatches) {
      lines.push(`- ${item.existingName} → ${item.matchId}`);
    }
  }
  lines.push('');
  lines.push('## Foto');
  lines.push(`- Righe CSV: ${report.counts.photos}`);
  lines.push(`- Importate / da importare: ${report.photos.imported}`);
  lines.push(`- Aggiornate (stesso id): ${report.photos.updated}`);
  lines.push(`- File mancanti: ${report.photos.missing.length}`);
  lines.push(`- Oltre il limite di 20: ${report.photos.overLimit.length}`);
  lines.push(`- Ignorate (foto_di_gruppo): ${report.photos.skippedGroup.length}`);
  if (report.photos.missing.length) {
    lines.push('');
    lines.push('### File mancanti');
    for (const file of report.photos.missing) {
      lines.push(`- ${file}`);
    }
  }
  if (report.photos.overLimit.length) {
    lines.push('');
    lines.push('### Oltre il limite');
    for (const file of report.photos.overLimit) {
      lines.push(`- ${file}`);
    }
  }
  lines.push('');
  lines.push('## Firestore (lettura)');
  lines.push(
    `- dogs prima: ${report.countsBefore.dogs} · dopo: ${report.countsAfter.dogs}`,
  );
  lines.push(
    `- photos prima: ${report.countsBefore.photos} · dopo: ${report.countsAfter.photos}`,
  );
  lines.push(
    `- notes prima: ${report.countsBefore.notes} · dopo: ${report.countsAfter.notes}`,
  );
  if (report.errors.length) {
    lines.push('');
    lines.push('## Errori');
    for (const err of report.errors) {
      lines.push(`- ${err}`);
    }
  }
  lines.push('');
  return lines.join('\n');
}

/** Giornata STEP 8: 4 volontari, operazioni del prompt. */
export const DAY_SCENARIO = {
  volunteers: 4,
  coldSessions: 4,
  listOpens: 20,
  sheetOpens: 40,
  galleryOpens: 15,
  photoUploads: 10,
  dataEdits: 5,
  daysPerMonth: 30,
};

/** Dataset audit STEP 1 (canile pieno). */
export const SHELTER_SCALE = { dogs: 199, photos: 284 };

const SPARK_EGRESS_BYTES = 10 * 1024 * 1024 * 1024;
const TARGET_MONTH_BYTES = 1024 * 1024 * 1024;

const KEEP_ALIVE = [
  'dogs',
  'covers',
  'health',
  'boxes',
  'appointments',
  'adoptions',
  'volunteers',
  'settings',
  'templates',
];

function documentStoredBytes(path, data) {
  return 32 + String(path).length + firestoreMapBytes(data ?? {});
}

async function sumCollection(db, name) {
  const snap = await db.collection(name).get();
  let bytes = 0;
  for (const doc of snap.docs) {
    bytes += documentStoredBytes(`${name}/${doc.id}`, doc.data());
  }
  return { count: snap.size, bytes };
}

export async function scanFirestoreUsage(db) {
  const collections = {};
  for (const name of KNOWN_COLLECTIONS) {
    if (name === 'photos') {
      continue;
    }
    collections[name] = await sumCollection(db, name);
  }

  const photosSnap = await db.collection('photos').get();
  let thumbs = 0;
  let covers = 0;
  let coverCount = 0;
  let fulls = 0;
  let fullCount = 0;
  let maxDoc = 0;
  const photosByDog = new Map();
  for (const doc of photosSnap.docs) {
    const data = doc.data() ?? {};
    const thumbBytes = documentStoredBytes(`photos/${doc.id}`, data);
    thumbs += thumbBytes;
    maxDoc = Math.max(maxDoc, thumbBytes);
    if (data.isCover === true) {
      covers += thumbBytes;
      coverCount += 1;
    }
    const dogId = data.dogId ?? '';
    photosByDog.set(dogId, (photosByDog.get(dogId) ?? 0) + 1);
    const fullSnap = await doc.ref.collection('full').doc('data').get();
    if (fullSnap.exists) {
      const fullBytes = documentStoredBytes(
        `photos/${doc.id}/full/data`,
        fullSnap.data(),
      );
      fulls += fullBytes;
      fullCount += 1;
      maxDoc = Math.max(maxDoc, fullBytes);
    }
  }

  collections.photos = { count: photosSnap.size, bytes: thumbs };
  collections.covers = { count: coverCount, bytes: covers };
  collections.photoFulls = { count: fullCount, bytes: fulls };

  let stored = 0;
  for (const item of Object.values(collections)) {
    stored += item.bytes;
  }

  const dogCount = collections.dogs.count || 1;
  const photoCount = photosSnap.size || 1;
  const dogsWithPhotos = [...photosByDog.values()].filter((n) => n > 0).length || 1;
  const avgThumbsPerDogWithPhotos =
    [...photosByDog.values()].reduce((a, n) => a + n, 0) / dogsWithPhotos;

  return {
    collections,
    storedBytes: stored,
    maxDocBytes: maxDoc,
    photoCount: photosSnap.size,
    coverCount,
    fullCount,
    dogCount: collections.dogs.count,
    avgDogBytes: collections.dogs.bytes / dogCount,
    avgThumbBytes: thumbs / photoCount,
    avgCoverBytes: coverCount ? covers / coverCount : 0,
    avgFullBytes: fullCount ? fulls / fullCount : 0,
    avgHealthPerDog: collections.health.bytes / dogCount,
    avgExpensesPerDog: collections.expenses.bytes / dogCount,
    avgWeightsPerDog: collections.weights.bytes / dogCount,
    avgNotesPerDog: collections.notes.bytes / dogCount,
    avgThumbsPerDogWithPhotos,
    dogsWithPhotos,
  };
}

export function projectTraffic(usage, scenario = DAY_SCENARIO, scale) {
  const u = scale ? scaleUsage(usage, scale) : usage;
  const keepAlive = KEEP_ALIVE.reduce(
    (sum, key) => sum + (u.collections[key]?.bytes ?? 0),
    0,
  );
  const extraListOpens = Math.max(0, scenario.listOpens - scenario.coldSessions);
  const listWarmBytes = 0;
  const sheetExpenses = scenario.sheetOpens * u.avgExpensesPerDog;
  const galleryThumbs =
    scenario.galleryOpens * u.avgThumbBytes * u.avgThumbsPerDogWithPhotos;
  const galleryFulls = scenario.galleryOpens * u.avgFullBytes;
  const uploadListenerEcho =
    scenario.photoUploads * scenario.volunteers * (u.avgCoverBytes + u.avgDogBytes);
  const editEcho = scenario.dataEdits * scenario.volunteers * u.avgDogBytes;
  const cold = scenario.coldSessions * keepAlive;
  const day =
    cold +
    extraListOpens * listWarmBytes +
    sheetExpenses +
    galleryThumbs +
    galleryFulls +
    uploadListenerEcho +
    editEcho;
  const month = day * scenario.daysPerMonth;
  return {
    keepAliveBytes: keepAlive,
    coldBytes: cold,
    listWarmBytes: extraListOpens * listWarmBytes,
    extraListOpens,
    sheetBytes: sheetExpenses,
    galleryThumbBytes: galleryThumbs,
    galleryFullBytes: galleryFulls,
    uploadEchoBytes: uploadListenerEcho,
    editEchoBytes: editEcho,
    dayBytes: day,
    monthBytes: month,
    sparkEgressBytes: SPARK_EGRESS_BYTES,
    targetMonthBytes: TARGET_MONTH_BYTES,
    underTarget: month < TARGET_MONTH_BYTES,
    ofSpark: month / SPARK_EGRESS_BYTES,
  };
}

function scaleUsage(usage, scale) {
  const dogFactor = scale.dogs / Math.max(usage.dogCount, 1);
  const photoFactor = scale.photos / Math.max(usage.photoCount, 1);
  const coverCount = Math.min(scale.dogs, scale.photos);
  const collections = { ...usage.collections };
  const scaleCol = (key, factor) => {
    const cur = usage.collections[key] ?? { count: 0, bytes: 0 };
    collections[key] = {
      count: Math.round(cur.count * factor),
      bytes: cur.bytes * factor,
    };
  };
  scaleCol('dogs', dogFactor);
  scaleCol('health', dogFactor);
  scaleCol('boxes', 1);
  scaleCol('appointments', dogFactor);
  scaleCol('adoptions', dogFactor);
  scaleCol('volunteers', 1);
  scaleCol('settings', 1);
  scaleCol('templates', 1);
  scaleCol('expenses', dogFactor);
  scaleCol('weights', dogFactor);
  scaleCol('notes', dogFactor);
  collections.covers = {
    count: coverCount,
    bytes: usage.avgCoverBytes * coverCount,
  };
  collections.photos = {
    count: scale.photos,
    bytes: usage.avgThumbBytes * scale.photos,
  };
  collections.photoFulls = {
    count: scale.photos,
    bytes: usage.avgFullBytes * scale.photos,
  };
  return {
    ...usage,
    collections,
    dogCount: scale.dogs,
    photoCount: scale.photos,
    coverCount,
    avgHealthPerDog: collections.health.bytes / scale.dogs,
    avgExpensesPerDog: collections.expenses.bytes / scale.dogs,
    avgWeightsPerDog: collections.weights.bytes / scale.dogs,
    avgNotesPerDog: collections.notes.bytes / scale.dogs,
    avgThumbsPerDogWithPhotos: scale.photos / scale.dogs,
    dogsWithPhotos: scale.dogs,
  };
}

export function formatTrafficReport(usage, live, scaled) {
  const mb = (n) => (n / (1024 * 1024)).toFixed(3);
  const lines = [
    '# STEP 8 — Traffico Firestore misurato',
    '',
    `Documenti cane: ${usage.dogCount} · foto: ${usage.photoCount} · copertine: ${usage.coverCount} · full: ${usage.fullCount}`,
    `Occupazione stimata: ${mb(usage.storedBytes)} MB (Spark storage 1 GiB)`,
    `Documento più grosso: ${mb(usage.maxDocBytes)} MB`,
    '',
    '## Byte per collezione (misurati)',
  ];
  const keys = [
    ...KEEP_ALIVE,
    'photos',
    'photoFulls',
    'expenses',
    'weights',
    'notes',
    'documents',
    'adopters',
    'sponsorships',
  ];
  for (const key of keys) {
    const item = usage.collections[key];
    if (!item) {
      continue;
    }
    lines.push(`- ${key}: ${item.count} doc · ${mb(item.bytes)} MB`);
  }
  const explain = (title, p) => {
    lines.push('');
    lines.push(`## ${title}`);
    lines.push(`- Keep-alive una sessione (dogs+copertine+health+box+appuntamenti+adozioni+volontari+impostazioni+template): ${mb(p.keepAliveBytes)} MB`);
    lines.push(`- ${DAY_SCENARIO.coldSessions} avvii a freddo: ${mb(p.coldBytes)} MB`);
    lines.push(`- ${p.extraListOpens} aperture lista a caldo (indexedStack + persistenza): ${mb(p.listWarmBytes)} MB`);
    lines.push(`- ${DAY_SCENARIO.sheetOpens} schede (spese per-cane, salute già in keep-alive): ${mb(p.sheetBytes)} MB`);
    lines.push(`- ${DAY_SCENARIO.galleryOpens} gallerie (thumb del cane + 1 full): ${mb(p.galleryThumbBytes + p.galleryFullBytes)} MB`);
    lines.push(`- ${DAY_SCENARIO.photoUploads} upload × ${DAY_SCENARIO.volunteers} listener: ${mb(p.uploadEchoBytes)} MB`);
    lines.push(`- ${DAY_SCENARIO.dataEdits} modifiche × ${DAY_SCENARIO.volunteers} listener: ${mb(p.editEchoBytes)} MB`);
    lines.push(`- **Giorno: ${mb(p.dayBytes)} MB**`);
    lines.push(`- **Mese (${DAY_SCENARIO.daysPerMonth} giorni): ${mb(p.monthBytes)} MB = ${(p.monthBytes / TARGET_MONTH_BYTES).toFixed(3)} GiB**`);
    lines.push(`- Quota Spark egress 10 GiB: ${(p.ofSpark * 100).toFixed(2)}% · target 1 GiB: ${p.underTarget ? 'OK' : 'SOPRA'}`);
  };
  explain('Proiezione sul database attuale', live);
  explain(`Proiezione canile pieno (${SHELTER_SCALE.dogs} cani, ${SHELTER_SCALE.photos} foto, medie misurate)`, scaled);
  lines.push('');
  return lines.join('\n');
}

export async function measureDayTraffic(db) {
  const usage = await scanFirestoreUsage(db);
  const live = projectTraffic(usage, DAY_SCENARIO);
  const scaled = projectTraffic(usage, DAY_SCENARIO, SHELTER_SCALE);
  return { usage, live, scaled, report: formatTrafficReport(usage, live, scaled) };
}

export async function countCore(db) {
  if (!db) {
    return { dogs: 0, photos: 0, notes: 0 };
  }
  return {
    dogs: await countCollection(db, 'dogs'),
    photos: await countCollection(db, 'photos'),
    notes: await countCollection(db, 'notes'),
  };
}

export function italianDate(d) {
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${dd}/${mm}/${yyyy}`;
}

export function stampForFile(d) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

export function writeReportFile(toolDir, markdown, now = new Date()) {
  mkdirSync(toolDir, { recursive: true });
  let name = `report-${stampForFile(now)}.md`;
  let path = join(toolDir, name);
  if (existsSync(path)) {
    const hh = String(now.getHours()).padStart(2, '0');
    const mi = String(now.getMinutes()).padStart(2, '0');
    name = `report-${stampForFile(now)}-${hh}${mi}.md`;
    path = join(toolDir, name);
  }
  writeFileSync(path, markdown);
  return path;
}
