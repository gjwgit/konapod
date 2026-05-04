/// EnergyPage — EV battery, charging, efficiency and fuel sections.
///
// Time-stamp: <Saturday 2026-05-02 20:41:42 +1000 Graham Williams>
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

import 'package:konapod/models/battery_observation.dart';
import 'package:konapod/screens/battery_analysis_screen.dart';
import 'package:konapod/services/app_provider.dart';
import 'package:konapod/services/battery_observation_service.dart';
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
            const _EfficiencyBarSection(),
            const Gap(16),
            const SectionLabel(
              'Battery Observations',
              tooltip: '**Battery Observations**\n\n'
                  'Data collected each time vehicle data is refreshed from '
                  'Bluelink or loaded from your Pod.\n\n'
                  '**Top:** Battery % vs estimated range (trend = km per 1%)\n'
                  '**Middle:** % vs kWh remaining and Range vs kWh remaining\n'
                  '**Bottom:** All recorded observations',
            ),
            const _BatterySection(),
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

/// Compact panel: scatter plot on top, scrollable table below.
/// Single loader that shares observations across all battery plots and table.
class _BatterySection extends StatefulWidget {
  const _BatterySection();

  @override
  State<_BatterySection> createState() => _BatterySectionState();
}

class _BatterySectionState extends State<_BatterySection> {
  List<BatteryObservation>? _obs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    BatteryObservationService.load().then((data) {
      if (mounted) {
        data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setState(() {
          _obs = data;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final obs = _obs ?? [];
    if (obs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No battery observations yet.\nRefresh Bluelink data to start collecting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final withKwh = obs.where((o) => o.remainKwh != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: BatteryScatterPlot(observations: obs),
          ),
        ),
        if (withKwh.isNotEmpty) ...[
          const Gap(8),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: BatteryKwhScatterPlot(
                      observations: withKwh,
                      mode: KwhPlotMode.pctVsKwh,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                    child: BatteryKwhScatterPlot(
                      observations: withKwh,
                      mode: KwhPlotMode.rangeVsKwh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const Gap(8),
        ObservationTable(
          observations: obs,
          onDelete: (o) async {
            final updated = obs.where((e) => e != o).toList();
            setState(() => _obs = updated);
            await BatteryObservationService.saveAll(updated);
          },
        ),
      ],
    );
  }
}

/// Loads battery observations and renders the efficiency bar chart.
class _EfficiencyBarSection extends StatefulWidget {
  const _EfficiencyBarSection();

  @override
  State<_EfficiencyBarSection> createState() => _EfficiencyBarSectionState();
}

class _EfficiencyBarSectionState extends State<_EfficiencyBarSection> {
  List<BatteryObservation>? _obs;

  @override
  void initState() {
    super.initState();
    BatteryObservationService.load().then((data) {
      if (mounted) {
        final withKwh = data
            .where(
              (o) =>
                  o.remainKwh != null && o.odometerKm != null && o.rangeKm > 0,
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setState(() => _obs = withKwh);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final obs = _obs;
    if (obs == null) return const SizedBox.shrink();
    if (obs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: BatteryEfficiencyBarChart(observations: obs),
      ),
    );
  }
}
