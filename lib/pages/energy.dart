/// EnergyPage — EV battery, charging, efficiency and fuel sections.
///
// Time-stamp: <Thursday 2026-03-19 05:34:29 +1100 Graham Williams>
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
import 'package:konapod/widgets/sections_energy.dart';

class EnergyPage extends StatelessWidget {
  final Vehicle v;
  const EnergyPage({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (v.isEV) ...[
            BatterySection(v: v),
            const Gap(8),
            BatteryStatusCard(v: v),
            const Gap(16),
            const SectionLabel('EV Efficiency'),
            EfficiencySection(v: v),
            const Gap(16),
          ],
          if (v.isICE && !v.isEV) ...[
            const SectionLabel('Fuel'),
            FuelSection(v: v),
            const Gap(16),
          ],
          const Gap(8),
        ],
      ),
    );
  }
}
