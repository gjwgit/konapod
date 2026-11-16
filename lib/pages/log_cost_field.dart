/// LogCostField — a dollar amount of a charging session, noted when calculated.
///
// Time-stamp: <Monday 2026-11-16 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

/// A dollar amount noted as calculated, with [tooltip] saying how, while it
/// still shows the [calculated] value.

class LogCostField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  /// The value the app worked out for this field, or null when it has not.
  final String? calculated;

  /// Markdown explaining how the calculated value was worked out.
  final String tooltip;

  const LogCostField({
    super.key,
    required this.controller,
    required this.label,
    required this.calculated,
    required this.tooltip,
  });

  // Rebuilt as the user types, so the note goes the moment the calculated
  // value is edited.

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final isCalculated = calculated != null && value.text == calculated;
        final field = TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            labelText: label,
            prefixText: r'$ ',
            helperText: isCalculated ? 'calculated' : null,
            helperStyle: TextStyle(
              color: cs.tertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
        if (!isCalculated) return field;

        return MarkdownTooltip(message: tooltip, child: field);
      },
    );
  }
}
