export const KNOWN_ROOT_COLLECTIONS = [
  'dogs',
  'photos',
  'health',
  'weights',
  'sponsorships',
  'expenses',
  'adopters',
  'vendors',
  'adoptions',
  'documents',
  'templates',
  'notes',
  'appointments',
  'volunteers',
  'authTokens',
  'boxes',
  'settings',
  'dogDrafts',
  'searchRecents',
];

export function toJsonValue(value) {
  if (value == null) {
    return null;
  }
  if (
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  ) {
    return value;
  }
  if (typeof Buffer !== 'undefined' && Buffer.isBuffer(value)) {
    return { __type: 'bytes', base64: value.toString('base64') };
  }
  if (value instanceof Date) {
    return { __type: 'timestamp', iso: value.toISOString() };
  }
  if (typeof value.toDate === 'function') {
    return { __type: 'timestamp', iso: value.toDate().toISOString() };
  }
  if (Array.isArray(value)) {
    return value.map(toJsonValue);
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [key, child] of Object.entries(value)) {
      out[key] = toJsonValue(child);
    }
    return out;
  }
  return String(value);
}

export function fromJsonValue(value) {
  if (value == null) {
    return null;
  }
  if (Array.isArray(value)) {
    return value.map(fromJsonValue);
  }
  if (typeof value === 'object') {
    if (value.__type === 'timestamp') {
      return new Date(value.iso);
    }
    if (value.__type === 'bytes') {
      return Buffer.from(value.base64, 'base64');
    }
    const out = {};
    for (const [key, child] of Object.entries(value)) {
      out[key] = fromJsonValue(child);
    }
    return out;
  }
  return value;
}
