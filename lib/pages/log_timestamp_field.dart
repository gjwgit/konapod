/// LogTimestampField — the date and time field of a log book entry.
///
// Time-stamp: <Friday 2026-08-08 10:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:konapod/pages/log_entry_widgets.dart';

/// The labelled, read-only date and time of a log book entry. Tapping it
/// calls [onTap], which the editor uses to run the date and time pickers.

class LogTimestampField extends StatelessWidget {
  final ColorScheme cs;
  final DateTime timestamp;
  final VoidCallback onTap;

  const LogTimestampField({
    super.key,
    required this.cs,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionLabel('Date & Time', cs),
          const Gap(8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.schedule_outlined, size: 18),
              ),
              child: Text(_fmt(timestamp)),
            ),
          ),
        ],
      );

  static String _fmt(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }
}
