/// DoorsSection widget showing lock, engine, charging and door states.
///
// Time-stamp: <Thursday 2026-03-26 18:40:09 +1100 Graham Williams>
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

// ── Summary row ───────────────────────────────────────────────────────────────

class SummaryRow extends StatelessWidget {
  final double total, avg, best;
  final int days;
  const SummaryRow({
    super.key,
    required this.total,
    required this.avg,
    required this.best,
    required this.days,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          VisualsCell('Total', '${total.toStringAsFixed(1)} km', cs),
          VisualsCell('Average', '${avg.toStringAsFixed(1)} km', cs),
          VisualsCell('Furtherest', '${best.toStringAsFixed(1)} km', cs),
          VisualsCell('Days', '$days', cs),
        ],
      ),
    );
  }
}

class VisualsCell extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const VisualsCell(this.label, this.value, this.cs, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
            const Gap(2),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
}
