/// Small helpers used by the Home "Add habit" flow.
library;

bool needsTarget(String type) {
  final t = type.toLowerCase();
  return t == 'count' || t == 'count_or_check' || t == 'counter';
}

String habitTypeLabel(String type) {
  final t = type.toLowerCase();
  if (t == 'check') return 'Check';
  if (t == 'count' || t == 'counter') return 'Contador';
  if (t == 'count_or_check') return 'Contador o check';
  return type;
}
