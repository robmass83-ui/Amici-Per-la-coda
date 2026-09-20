#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  backupAll,
  buildPlan,
  countCore,
  formatReport,
  hasImportIds,
  importDogs,
  importPhotos,
  italianDate,
  loadCsvBundle,
  measureDayTraffic,
  migratePhotos,
  restoreAll,
  stampForFile,
  verifyImport,
  writeReportFile,
} from './lib.mjs';
import { assertProductionWriteAllowed } from '../../backend/scripts/production_write_guard.mjs';

assertProductionWriteAllowed('import.mjs');

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const ROOT = join(SCRIPT_DIR, '..', '..');

function parseArgs(argv) {
  const flags = new Set();
  const values = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--dir' || arg === '--restore' || arg === '--limit') {
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        throw new Error(`${arg} richiede un valore`);
      }
      values[arg.slice(2)] = next;
      i += 1;
    } else if (arg.startsWith('--')) {
      flags.add(arg.slice(2));
    } else if (!values.restore && flags.has('restore')) {
      values.restore = arg;
    }
  }
  return { flags, values };
}

function usage() {
  return `Uso:
  node import.mjs --dry-run
  node import.mjs --backup
  node import.mjs --dogs
  node import.mjs --photos [--dir <cartella foto>]
  node import.mjs --verify
  node import.mjs --migrate-photos [--dry-run] [--limit N]
  node import.mjs --measure
  node import.mjs --restore backup-<data>/

Opzioni: --force  (richiesto se esistono già documenti csv_* o fb_*)
         --limit N  (solo --migrate-photos: massimo N foto da convertire)
Percorso foto predefinito: import/foto/
`;
}

async function initFirestore() {
  const saPath = join(SCRIPT_DIR, 'serviceAccount.json');
  if (!existsSync(saPath)) {
    throw new Error(`Manca la chiave Admin: ${saPath}`);
  }
  const { initializeApp, cert, getApps } = await import('firebase-admin/app');
  const { getFirestore, Timestamp } = await import('firebase-admin/firestore');
  const sa = JSON.parse(readFileSync(saPath, 'utf8'));
  if (getApps().length === 0) {
    initializeApp({ credential: cert(sa) });
  }
  return { db: getFirestore(), Timestamp };
}

async function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (err) {
    console.error(err.message);
    console.error(usage());
    process.exit(1);
  }
  const { flags, values } = parsed;
  const dryRun = flags.has('dry-run');
  const doBackup = flags.has('backup');
  const doDogs = flags.has('dogs');
  const doPhotos = flags.has('photos');
  const doVerify = flags.has('verify');
  const doRestore = flags.has('restore') || Boolean(values.restore);
  const doMigratePhotos = flags.has('migrate-photos');
  const doMeasure = flags.has('measure');
  const force = flags.has('force');
  const limit = values.limit ? Number(values.limit) : 0;
  if (values.limit && (!Number.isFinite(limit) || limit < 0)) {
    console.error('--limit richiede un numero ≥ 0');
    process.exit(1);
  }

  if (
    !dryRun &&
    !doBackup &&
    !doDogs &&
    !doPhotos &&
    !doVerify &&
    !doRestore &&
    !doMigratePhotos &&
    !doMeasure
  ) {
    console.log(usage());
    process.exit(0);
  }

  const photoDir = resolve(values.dir ?? join(ROOT, 'import', 'foto'));
  const now = new Date();
  const started = Date.now();
  let db = null;
  let Timestamp = null;
  try {
    ({ db, Timestamp } = await initFirestore());
  } catch (err) {
    if (!dryRun) {
      console.error(err.message);
      process.exit(1);
    }
    console.warn(`Firestore non disponibile (solo piano CSV): ${err.message}`);
  }

  if (doMeasure) {
    if (!db) {
      console.error('Serve Firestore per --measure');
      process.exit(1);
    }
    const result = await measureDayTraffic(db);
    console.log(result.report);
    return;
  }

  if (dryRun && db) {
    const raw = db;
    db = {
      collection(name) {
        const col = raw.collection(name);
        return {
          doc(id) {
            const ref = col.doc(id);
            return {
              id,
              get: () => ref.get(),
              collection(sub) {
                const subCol = ref.collection(sub);
                return {
                  doc(sid) {
                    return {
                      get: () => subCol.doc(sid).get(),
                      set() {
                        throw new Error('dry-run: scrittura vietata');
                      },
                    };
                  },
                  get: () => subCol.get(),
                };
              },
              set() {
                throw new Error('dry-run: scrittura vietata');
              },
              update() {
                throw new Error('dry-run: scrittura vietata');
              },
              delete() {
                throw new Error('dry-run: scrittura vietata');
              },
            };
          },
          get: () => col.get(),
          where: (field, op, value) => col.where(field, op, value),
        };
      },
      batch() {
        throw new Error('dry-run: scrittura vietata');
      },
      listCollections: () => raw.listCollections(),
    };
  }

  if (doRestore) {
    const dir = resolve(values.restore);
    if (!existsSync(dir)) {
      console.error(`Cartella backup non trovata: ${dir}`);
      process.exit(1);
    }
    if (dryRun) {
      console.log(`dry-run: ripristinerei da ${dir}`);
      return;
    }
    const result = await restoreAll(db, dir, { Timestamp, dryRun: false });
    console.log(`Ripristinati ${result.restored} documenti da ${dir}`);
    if (result.deleted) {
      console.log(
        `Rimossi ${result.deleted} documenti non presenti nel backup`,
      );
    }
    return;
  }

  if (doBackup) {
    const dir = join(SCRIPT_DIR, `backup-${stampForFile(now)}`);
    const manifest = await backupAll(db, dir);
    const tot = manifest.collections.reduce((n, c) => n + c.count, 0);
    console.log(`Backup in ${dir} (${tot} documenti)`);
    for (const col of manifest.collections) {
      if (col.count) {
        console.log(`  ${col.name}: ${col.count}`);
      }
    }
    if (!dryRun && !doDogs && !doPhotos && !doVerify && !doMigratePhotos) {
      return;
    }
  }

  if (doMigratePhotos) {
    if (!db) {
      console.error('Firestore non disponibile');
      process.exit(1);
    }
    const statePath = join(SCRIPT_DIR, '.migrate-photos-state.json');
    let stop = false;
    const onSigint = () => {
      stop = true;
      console.log('Interruzione richiesta: finisco la foto in corso e salvo lo stato.');
    };
    process.on('SIGINT', onSigint);
    try {
      const stats = await migratePhotos({
        db,
        dryRun,
        limit,
        statePath,
        log: (line) => console.log(line),
        shouldStop: () => stop,
      });
      console.log(
        [
          dryRun ? 'DRY-RUN migrazione foto' : 'Migrazione foto',
          `foto ${stats.total}`,
          `convertite ${stats.converted}`,
          `legacy rimossi ${stats.stripped}`,
          `già ok ${stats.skipped}`,
          `full mancanti ${stats.missingFull}`,
          `errori ${stats.errors.length}`,
          `MB prima ${stats.mbBefore.toFixed(2)}`,
          `MB dopo ${stats.mbAfter.toFixed(2)}`,
          dryRun
            ? `fotoCount da aggiornare ${stats.fotoCountWouldUpdate}`
            : `fotoCount aggiornati ${stats.fotoCountUpdated}`,
          stats.stopped ? 'INTERROTTO' : '',
        ]
          .filter(Boolean)
          .join(' · '),
      );
      if (stats.errors.length) {
        for (const err of stats.errors) {
          console.log(`  errore ${err.id}: ${err.message}`);
        }
      }
    } finally {
      process.off('SIGINT', onSigint);
    }
    return;
  }

  const ctxBase = { db, Timestamp, now, dryRun, photoDir, root: ROOT };

  if (doVerify && !doDogs && !doPhotos && !dryRun) {
    const result = await verifyImport(db);
    console.log(
      result.ok
        ? `Verify OK · ${result.dogs} cani · ${result.photos} foto`
        : 'Verify: problemi trovati',
    );
    if (result.orphanPhotos.length) {
      console.log('Foto orfane:', result.orphanPhotos.join(', '));
    }
    if (result.missingCovers.length) {
      console.log(
        'Copertine mancanti:',
        result.missingCovers
          .map((item) => `${item.dogId} → ${item.fotoCopertinaId}`)
          .join(', '),
      );
    }
    process.exit(result.ok ? 0 : 1);
  }

  const csv = loadCsvBundle(ROOT);
  const plan = buildPlan(csv, { photoDir });
  if (plan.errors.length && (doDogs || doPhotos) && !dryRun) {
    const fatal = plan.errors.some((e) => e.startsWith('solo_foto:'));
    if (fatal) {
      throw new Error(plan.errors.join('\n'));
    }
  }

  if ((doDogs || doPhotos) && !dryRun && db) {
    const existing = await hasImportIds(db);
    if (existing.length && !force) {
      console.error(
        `Trovati ${existing.length} documenti csv_* / fb_*. Usa --force per procedere.`,
      );
      process.exit(1);
    }
  }

  let forceWarning = '';
  if (dryRun && db) {
    const existing = await hasImportIds(db);
    if (existing.length) {
      forceWarning = `Ci sono già ${existing.length} documenti csv_* / fb_*. L'import vero richiederà --force.`;
    }
  }

  const countsBefore = await countCore(db);
  const dogsStats = { created: 0, updated: 0, soloFoto: 0, notes: 0, errors: [] };
  const photoStats = {
    imported: 0,
    updated: 0,
    missing: plan.missing,
    overLimit: [],
    skippedGroup: plan.skippedGroup,
    bytesWritten: 0,
  };

  const runDogs = dryRun || doDogs;
  const runPhotos = dryRun || doPhotos;

  if (runDogs) {
    Object.assign(
      dogsStats,
      await importDogs({ ...ctxBase, plan, phase: 'all' }),
    );
  }
  if (runPhotos) {
    Object.assign(photoStats, await importPhotos({ ...ctxBase, plan }));
  }

  const countsAfter = await countCore(db);
  const errors = [
    ...(plan.errors ?? []),
    ...(dogsStats.errors ?? []),
    ...(photoStats.errors ?? []),
  ];
  const report = {
    dateLabel: italianDate(now),
    dryRun,
    elapsedMs: Date.now() - started,
    mbWritten: (photoStats.bytesWritten ?? 0) / (1024 * 1024),
    forceWarning,
    counts: plan.counts,
    dogs: dogsStats,
    photos: photoStats,
    soloFotoMatches: plan.soloFoto.map((item) => ({
      existingName: item.existingName,
      matchId: item.matchId,
    })),
    countsBefore,
    countsAfter,
    errors,
  };
  const markdown = formatReport(report);
  const reportPath = writeReportFile(SCRIPT_DIR, markdown, now);
  console.log(markdown);
  console.log(`Rapporto scritto in ${reportPath}`);

  if (doVerify && db && !dryRun) {
    const result = await verifyImport(db);
    console.log(
      result.ok ? 'Verify OK' : `Verify KO · orfane ${result.orphanPhotos.length} · copertine ${result.missingCovers.length}`,
    );
  }

  if (errors.length && !dryRun) {
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
