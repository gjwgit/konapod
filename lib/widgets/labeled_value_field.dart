/// Labeled numeric input with unit label snug to the right of the value.
///
// Time-stamp: <2026-05-22>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

/// Renders a label above a narrow input field with the unit immediately
/// to the right:
///
///   Odometer
///   [3161] km
///
/// The widget sizes itself to its minimum width (field + unit). Wrap it
/// in [Flexible] (NOT [Expanded]) in the parent row so it can take half
/// the available space without being forced to fill it. [Expanded] passes
/// tight constraints which prevent the inner row from shrinking; [Flexible]
/// passes loose constraints which allows it.
class LabeledValueField extends StatelessWidget {
  final String labelText;
  final String unit;
  final TextEditingController controller;
  final TextInputType keyboardType;

  /// Width of the input box. 96 suits 4-5 digit values; 64 suits short
  /// values like duration hours/minutes.
  final double fieldWidth;

  const LabeledValueField({
    super.key,
    required this.labelText,
    required this.unit,
    required this.controller,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.fieldWidth = 96,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelText,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: fieldWidth,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
