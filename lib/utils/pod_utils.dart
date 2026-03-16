import 'dart:convert';

import 'package:intl/intl.dart';

import '../constants/app.dart';

/// Generates a status filename with the current timestamp.
/// e.g. status_20240315T142300.json
String makeStatusFilename() {
  final now = DateTime.now();
  final stamp = DateFormat("yyyyMMdd'T'HHmmss").format(now);
  return '$statusFilePrefix$stamp$statusFileSuffix';
}

/// Parses a DateTime from a status filename like status_20240315T142300.json.
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

/// Converts a vehicle data map to JSON string for pod storage.
String vehicleMapToJson(Map<String, dynamic> data) =>
    const JsonEncoder.withIndent('  ').convert(data);

/// Parses JSON string from pod into vehicle data map.
Map<String, dynamic>? vehicleMapFromJson(String json) {
  try {
    return jsonDecode(json) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
