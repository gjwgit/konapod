import 'package:intl/intl.dart';

import '../constants/app.dart';

/// Generates a status filename with the current timestamp.
/// e.g. status_20240315T142300.ttl
String makeStatusFilename() {
  final now = DateTime.now();
  final stamp = DateFormat("yyyyMMdd'T'HHmmss").format(now);
  return '$statusFilePrefix$stamp$statusFileSuffix';
}

/// Parses a DateTime from a status filename like status_20240315T142300.ttl.
DateTime? parseStatusFilename(String filename) {
  try {
    final base = filename
        .replaceFirst(statusFilePrefix, '')
        .replaceFirst(statusFileSuffix, '');
    return DateFormat("yyyyMMdd'T'HHmmss").parse(base);
  } catch (_) {
    return null;
  }
}
