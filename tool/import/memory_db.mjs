/** Firestore in memoria: stessa superficie usata dallo script (collection/doc/batch). */

export class MemoryTimestamp {
  constructor(date) {
    this._date = date instanceof Date ? date : new Date(date);
  }

  toDate() {
    return this._date;
  }

  toISOString() {
    return this._date.toISOString();
  }

  static fromDate(date) {
    return new MemoryTimestamp(date);
  }
}

export class MemoryDb {
  constructor() {
    /** @type {Map<string, Record<string, unknown>>} */
    this.store = new Map();
    this.writes = 0;
  }

  collection(name) {
    return new MemoryCollection(this, name);
  }

  batch() {
    return new MemoryBatch(this);
  }

  async listCollections() {
    const names = new Set();
    for (const key of this.store.keys()) {
      names.add(key.split('/')[0]);
    }
    return [...names].sort().map((id) => ({ id }));
  }

  _get(path) {
    const data = this.store.get(path);
    return {
      id: path.split('/').pop(),
      exists: data != null,
      data: () => (data == null ? undefined : clone(data)),
      ref: new MemoryRef(this, path),
    };
  }

  _set(path, data) {
    this.writes += 1;
    this.store.set(path, clone(data));
  }

  _update(path, patch) {
    const current = this.store.get(path);
    if (current == null) {
      throw new Error(`Documento mancante: ${path}`);
    }
    this.writes += 1;
    this.store.set(path, { ...clone(current), ...clone(patch) });
  }

  _delete(path) {
    if (this.store.has(path)) {
      this.writes += 1;
    }
    this.store.delete(path);
    const prefix = `${path}/`;
    for (const key of [...this.store.keys()]) {
      if (key.startsWith(prefix)) {
        this.store.delete(key);
        this.writes += 1;
      }
    }
  }

  _docsIn(colPath) {
    const prefix = `${colPath}/`;
    const docs = [];
    for (const [key, data] of this.store) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      const rest = key.slice(prefix.length);
      if (rest.includes('/')) {
        continue;
      }
      docs.push({
        id: rest,
        exists: true,
        data: () => clone(data),
        ref: new MemoryRef(this, key),
      });
    }
    return docs;
  }
}

class MemoryCollection {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    this.id = path.split('/').pop();
    this._filters = [];
  }

  doc(id) {
    return new MemoryRef(this._db, `${this.path}/${id}`);
  }

  where(field, op, value) {
    const next = new MemoryCollection(this._db, this.path);
    next._filters = [...this._filters, { field, op, value }];
    return next;
  }

  async get() {
    let docs = this._db._docsIn(this.path);
    for (const filter of this._filters) {
      if (filter.op !== '==') {
        throw new Error(`Filtro non supportato: ${filter.op}`);
      }
      docs = docs.filter((doc) => doc.data()[filter.field] === filter.value);
    }
    return { docs, size: docs.length, empty: docs.length === 0 };
  }
}

class MemoryRef {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    this.id = path.split('/').pop();
  }

  collection(name) {
    return new MemoryCollection(this._db, `${this.path}/${name}`);
  }

  async get() {
    return this._db._get(this.path);
  }

  async set(data) {
    this._db._set(this.path, data);
  }

  async update(data) {
    this._db._update(this.path, data);
  }

  async delete() {
    this._db._delete(this.path);
  }
}

class MemoryBatch {
  constructor(db) {
    this._db = db;
    this._ops = [];
  }

  set(ref, data) {
    this._ops.push(() => this._db._set(ref.path, data));
    return this;
  }

  update(ref, data) {
    this._ops.push(() => this._db._update(ref.path, data));
    return this;
  }

  delete(ref) {
    this._ops.push(() => this._db._delete(ref.path));
    return this;
  }

  async commit() {
    for (const op of this._ops) {
      op();
    }
  }
}

function clone(value) {
  if (value == null) {
    return value;
  }
  if (Buffer.isBuffer(value)) {
    return Buffer.from(value);
  }
  if (value instanceof Uint8Array) {
    return Uint8Array.from(value);
  }
  if (value instanceof MemoryTimestamp) {
    return MemoryTimestamp.fromDate(value.toDate());
  }
  if (
    value &&
    typeof value === 'object' &&
    typeof value.toDate === 'function' &&
    !(value instanceof Date)
  ) {
    return MemoryTimestamp.fromDate(value.toDate());
  }
  if (value instanceof Date) {
    return new Date(value.getTime());
  }
  if (Array.isArray(value)) {
    return value.map(clone);
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = clone(nested);
    }
    return out;
  }
  return value;
}
