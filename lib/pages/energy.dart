/// EnergyPage — EV battery, charging, efficiency and fuel sections.
///
// Time-stamp: <Thursday 2026-03-19 14:02:31 +1100 Graham Williams>
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
import 'package:provider/provider.dart';

import 'package:konapod/services/app_provider.dart';
import 'package:konapod/widgets/section_label.dart';
import 'package:konapod/widgets/sections_energy.dart';

class EnergyPage extends StatelessWidget {
  const EnergyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.watch<AppProvider>().selectedVehicle;

    if (v == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.battery_charging_full,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
              ),
              const Gap(16),
              const Text(
                'No vehicle data loaded.',
                style: TextStyle(fontSize: 16),
              ),
              const Gap(8),
              Text(
                'Load a Bluelink snapshot or pod data first.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            const SectionLabel(
              'EV Efficiency',
              tooltip: '**EV Efficiency**\n\n'
                  'Energy consumption rates from the car\'s onboard computer:\n\n'
                  '+ **Overall** — lifetime average since new\n'
                  '+ **Since Charging** — since the last full charge\n'
                  '+ **Latest Trip** — the most recent drive\n\n'
                  'Lower kWh/100km is better. Typical EV range is 13–20.',
            ),
            EfficiencySection(v: v),
            const Gap(16),
          ],
          if (v.isICE && !v.isEV) ...[
            const SectionLabel(
              'Fuel',
              tooltip: '**Fuel**\n\n'
                  'Current fuel level and estimated range on remaining fuel.',
            ),
            FuelSection(v: v),
            const Gap(16),
          ],
          const Gap(8),
        ],
      ),
    );
  }
}
