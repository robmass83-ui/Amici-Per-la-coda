String newEntityId(String prefix, DateTime now, {int index = 0}) {
  return '${prefix}_${now.microsecondsSinceEpoch}_$index';
}
