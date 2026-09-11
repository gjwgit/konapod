/// LogFinishTimeField — the charge finish date and time of a log entry.
///
// Time-stamp: <Saturday 2026-09-05 10:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:konapod/pages/log_timestamp_field.dart';

/// The labelled, read-only finish time of a charging session, laid out like
/// a [LabeledValueField] so it sits level with the duration fields beside
/// it. Tapping it calls [onTap], which the charge section uses to run the
/// date and time pickers and turn the result back into a duration.

class LogFinishTimeField extends StatelessWidget {
  /// When charging finished, or null while the duration is blank.
  final DateTime? finish;

  final VoidCallback onTap;

  const LogFinishTimeField({
    super.key,
    required this.finish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Finish',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        MarkdownTooltip(
          message: '''

          **Finish Time.**

          Tap to pick when the charge finished. The duration is worked out
          from the entry's date and time through to the finish time, so
          setting one updates the other.

          ''',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      finish == null ? '—' : LogTimestampField.fmt(finish!),
                    ),
                  ),
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
