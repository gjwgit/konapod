/// LogEndReadingsSection — end vehicle readings for a log book entry.
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

/// The end vehicle readings, injected into the charging section by
/// [LogEntryEdit]. A readings grid under a label row that carries the
/// Fetch from Bluelink button.

class LogEndReadingsSection extends StatelessWidget {
  final ColorScheme cs;

  /// Whether a Bluelink fetch is in flight — shows a spinner in place of the
  /// icon and disables the button.
  final bool fetching;

  /// Fetch the end readings from Bluelink. Null when not logged in to
  /// Bluelink, in which case the button is not offered at all.
  final VoidCallback? onFetch;

  final TextEditingController odoCtrl;
  final TextEditingController battCtrl;
  final TextEditingController remainCtrl;
  final TextEditingController rangeCtrl;

  const LogEndReadingsSection({
    super.key,
    required this.cs,
    required this.fetching,
    required this.onFetch,
    required this.odoCtrl,
    required this.battCtrl,
    required this.remainCtrl,
    required this.rangeCtrl,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(12),
          Row(
            children: [
              LogSectionLabel('End Readings', cs),
              const Spacer(),
              // Fetch from Bluelink button
              if (onFetch != null)
                TextButton.icon(
                  icon: fetching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined, size: 16),
                  label: const Text('From Bluelink'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: fetching ? null : onFetch,
                ),
            ],
          ),
          const Gap(8),
          LogReadingsGrid(
            odoCtrl: odoCtrl,
            battCtrl: battCtrl,
            remainCtrl: remainCtrl,
            rangeCtrl: rangeCtrl,
          ),
        ],
      );
}
