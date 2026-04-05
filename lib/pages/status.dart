/// StatusPage — vehicle status with hero, doors, windows, warnings and info.
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

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/pages/section_label.dart';
import 'package:konapod/pages/timestamp_row.dart';
import 'package:konapod/widgets/doors_section.dart';
import 'package:konapod/widgets/hero_card.dart';
import 'package:konapod/widgets/sections_comfort.dart';
import 'package:konapod/widgets/warnings_section.dart';
import 'package:konapod/widgets/windows_section.dart';

class StatusPage extends StatelessWidget {
  final Vehicle v;
  const StatusPage({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(v: v),
          const Gap(16),
          TimestampRow(
            lastUpdated: v.lastUpdated,
            fetchedAt: v.fetchedAt,
            registrationDate: v.registrationDate,
          ),
          const Gap(16),
          const SectionLabel(
            'Doors & Security',
            tooltip: '**Doors & Security**\n\n'
                'Open/closed state of each door, boot and bonnet. '
                'Red indicates a door is currently open.',
          ),
          DoorsSection(v: v),
          const Gap(16),
          const SectionLabel(
            'Windows',
            tooltip: '**Windows**\n\n'
                'Open/closed state of each window. '
                'Red indicates a window is currently open.',
          ),
          WindowsSection(v: v),
          const Gap(16),
          const SectionLabel(
            'Warnings',
            tooltip: '**Warnings**\n\n'
                'Active vehicle warnings reported by the onboard systems — '
                'low fuel, tyre pressure, 12V battery, smart key, and washer fluid.',
          ),
          WarningsSection(v: v),
          const Gap(16),
          const SectionLabel(
            'Vehicle Info',
            tooltip: '**Vehicle Info**\n\n'
                'Registration details including model, year, VIN, '
                'colour, trim, and fuel type.',
          ),
          InfoSection(v: v),
          if (v.extras.isNotEmpty) ...[
            const Gap(16),
            const SectionLabel('Additional Data'),
            ExtrasSection(extras: v.extras),
          ],
          const Gap(24),
        ],
      ),
    );
  }
}
