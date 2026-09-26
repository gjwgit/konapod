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
/// runs the date and time pickers and reports the result to [onChanged].

class LogTimestampField extends StatelessWidget {
  final ColorScheme cs;
  final DateTime timestamp;

  /// Called with the new date and time once both pickers have been answered.
  /// Cancelling either picker leaves [timestamp] alone.
  final ValueChanged<DateTime> onChanged;

  const LogTimestampField({
    super.key,
    required this.cs,
    required this.timestamp,
    required this.onChanged,
  });

  /// Run the date picker then the time picker, starting from the current
  /// value.

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(timestamp),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionLabel('Date & Time', cs),
          const Gap(8),
          InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.schedule_outlined, size: 18),
              ),
              child: Text(fmt(timestamp)),
            ),
          ),
        ],
      );

  /// Format a log book date and time as `dd/mm/yyyy  hh:mm`. Shared with
  /// the charge finish time field so both read the same.

  static String fmt(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }
}
