/// TyreTile widget showing tyre pressure warning status.
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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:konapod/theme/hyundai_theme.dart';

class TyreTile extends StatelessWidget {
  final String label;
  final bool? warning;
  const TyreTile(this.label, this.warning, {super.key});
  @override
  Widget build(BuildContext context) {
    final warn = warning == true;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: warn
            ? HyundaiColors.error.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: warn
            ? Border.all(color: HyundaiColors.error.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            warn ? Icons.warning_amber : Icons.check_circle_outline,
            color: warn ? HyundaiColors.error : HyundaiColors.success,
            size: 16,
          ),
          const Gap(6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: warn ? HyundaiColors.error : cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
