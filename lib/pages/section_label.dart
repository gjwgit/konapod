/// SectionLabel — uppercase section heading used across dashboard pages.
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
import 'package:markdown_tooltip/markdown_tooltip.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final String? tooltip;
  const SectionLabel(this.text, {super.key, this.tooltip});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: tooltip == null
          ? label
          : Row(
              children: [
                label,
                const Gap(6),
                MarkdownTooltip(
                  message: tooltip!,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
    );
  }
}
