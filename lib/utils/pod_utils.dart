/// Utilities for generating and parsing pod snapshot filenames.
///
// Time-stamp: <Monday 2026-03-16 22:01:12 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Claude, Graham Williams

library;

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
