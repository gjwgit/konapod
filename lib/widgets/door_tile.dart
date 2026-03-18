/// DoorTile widget showing open/closed state for doors and windows.
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

class DoorTile extends StatelessWidget {
  final String label;
  final bool? isOpen;
  final bool isWindow;
  const DoorTile(this.label, this.isOpen, {super.key, this.isWindow = false});
  @override
  Widget build(BuildContext context) {
    final open = isOpen == true;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: open
            ? HyundaiColors.error.withValues(alpha: 0.07)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isWindow
                ? (open ? Icons.crop_square : Icons.crop_din)
                : (open ? Icons.sensor_door : Icons.sensor_door_outlined),
            size: 14,
            color: open ? HyundaiColors.error : HyundaiColors.success,
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurface),
          ),
          const Spacer(),
          Text(
            isOpen == null
                ? '–'
                : open
                    ? 'Open'
                    : 'Closed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: open ? HyundaiColors.error : HyundaiColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
