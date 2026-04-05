/// TimestampRow — displays last updated, fetched at and registration date.
///
// Time-stamp: <Wednesday 2026-03-18 22:06:27 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

class TimestampRow extends StatelessWidget {
  final DateTime? lastUpdated;
  final DateTime? fetchedAt;
  final DateTime? registrationDate;
  const TimestampRow({
    super.key,
    this.lastUpdated,
    this.fetchedAt,
    this.registrationDate,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yyyy HH:mm:ss');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastUpdated != null)
          _TsLine(
            'Last updated',
            fmt.format(lastUpdated!),
            cs,
            tooltip: '**Last Updated**\n\n'
                'When the car last reported its status to the '
                'Bluelink servers. The car transmits periodically '
                'and after events like locking or charging.',
          ),
        const Gap(16),
        if (fetchedAt != null)
          _TsLine(
            'Fetched at',
            fmt.format(fetchedAt!),
            cs,
            tooltip: '**Fetched At**\n\n'
                'When this app retrieved the data from the Bluelink API. '
                'May be later than "Last Updated" if the car has been '
                'offline or in an area without cellular coverage.',
          ),
        const Gap(16),
        if (registrationDate != null)
          _TsLine(
            'Data collected since',
            fmt.format(registrationDate!),
            cs,
            tooltip: '**Data Collected Since**\n\n'
                'The date the vehicle was first registered with '
                'the Bluelink service — typically the delivery date.',
          ),
      ],
    );
  }
}

class _TsLine extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  final String? tooltip;
  const _TsLine(this.label, this.value, this.cs, {this.tooltip});
  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 13, color: cs.onSurfaceVariant),
          const Gap(6),
          Text(
            '$label: ',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
    if (tooltip == null) return row;

    return MarkdownTooltip(message: tooltip!, child: row);
  }
}
