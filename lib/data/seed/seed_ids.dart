/// Prefisso di tutti i documenti inventati (cani, volontari, adozioni).
const seedIdPrefix = 'seed_';

/// Prefisso visibile nel nome dei cani di prova.
const seedNamePrefix = '[PROVA] ';

bool isSeedId(String id) => id.startsWith(seedIdPrefix);

/// Vecchi id dei 6 cani finti, prima del prefisso seed_.
/// `otto` non c'è: ora è un cane vero del CSV.
const legacyDemoDogIds = <String>['fenice', 'brando', 'nina', 'zeus', 'luna'];

const legacyDemoAdoptionIds = <String>[
  'ad_marta_luna',
  'ad_ferrari_otto',
  'ad_luca_brando',
  'ad_anna_nina',
  'ad_sara_zeus',
];
