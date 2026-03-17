/// Top-level page widgets: Status, Energy, Comfort, and placeholder.
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

import 'package:intl/intl.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/services/app_provider.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/sections_comfort.dart';
import 'package:konapod/widgets/sections_energy.dart';
import 'package:konapod/widgets/sections_status.dart';

// ── Status page ───────────────────────────────────────────────────────────────
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
          const SizedBox(height: 16),
          const SectionLabel('Doors & Security'),
          DoorsSection(v: v),
          const SizedBox(height: 16),
          const SectionLabel('Windows'),
          WindowsSection(v: v),
          const SizedBox(height: 16),
          const SectionLabel('Warnings'),
          WarningsSection(v: v),
          const SizedBox(height: 16),
          const SectionLabel('Vehicle Info'),
          InfoSection(v: v),
          const SizedBox(height: 16),
          _TimestampRow(lastUpdated: v.lastUpdated, fetchedAt: v.fetchedAt),
          if (v.extras.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionLabel('Additional Data'),
            ExtrasSection(extras: v.extras),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Energy page ───────────────────────────────────────────────────────────────
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
            const SectionLabel('Battery & Charging'),
            BatterySection(v: v),
            const SizedBox(height: 16),
          ],
          if (v.isICE && !v.isEV) ...[
            const SectionLabel('Fuel'),
            FuelSection(v: v),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Comfort page ──────────────────────────────────────────────────────────────
class ComfortPage extends StatelessWidget {
  final Vehicle v;
  const ComfortPage({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Climate'),
          ClimateSection(v: v),
          const SizedBox(height: 16),
          const SectionLabel('Tyres'),
          TyreSection(v: v),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── No data placeholder ───────────────────────────────────────────────────────
class NoDataPlaceholder extends StatelessWidget {
  final AppProvider provider;
  const NoDataPlaceholder({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    if (provider.state == AppState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No vehicle data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Log in to Bluelink to fetch live data,\n'
              'or load a snapshot from your Solid Pod.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HyundaiColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(
                    color: HyundaiColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  final DateTime? lastUpdated;
  final DateTime? fetchedAt;
  const _TimestampRow({this.lastUpdated, this.fetchedAt});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yyyy HH:mm:ss');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastUpdated != null)
          _TsLine('Last updated', fmt.format(lastUpdated!), cs),
        if (fetchedAt != null)
          _TsLine('Fetched at', fmt.format(fetchedAt!), cs),
      ],
    );
  }
}

class _TsLine extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const _TsLine(this.label, this.value, this.cs);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 13,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}
