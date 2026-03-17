/// WindowsSection widget showing open/closed state of all windows.
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

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/widgets/primitives.dart';
import 'package:konapod/widgets/tiles.dart';

class WindowsSection extends StatelessWidget {
  final Vehicle v;
  const WindowsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DoorTile(
                  'Front Left',
                  v.isWindowFrontLeftOpen,
                  isWindow: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DoorTile(
                  'Front Right',
                  v.isWindowFrontRightOpen,
                  isWindow: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DoorTile(
                  'Rear Left',
                  v.isWindowRearLeftOpen,
                  isWindow: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DoorTile(
                  'Rear Right',
                  v.isWindowRearRightOpen,
                  isWindow: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
