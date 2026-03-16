/// A Bluelink app for Hyundai
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

import 'package:flutter/material.dart';

import '../theme/hyundai_theme.dart';

/// Composite tile widgets — DoorTile, TyreTile, BigStatusTile, KVTable.
/// All colours resolved from Theme for dark mode support.

class BigStatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const BigStatusTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

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
          const SizedBox(width: 6),
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
          const SizedBox(width: 6),
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

class KVTable extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  const KVTable(this.rows, {super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: cs.outlineVariant,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Text(
                rows[i].key,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  rows[i].value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
