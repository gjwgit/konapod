import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/app_provider.dart';
import '../theme/hyundai_theme.dart';
import '../widgets/sections_status.dart';
import '../widgets/sections_energy.dart';
import '../widgets/sections_comfort.dart';

// ── Status page ───────────────────────────────────────────────────────────────
class StatusPage extends StatelessWidget {
  final Vehicle v;
  const StatusPage({required this.v});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
      ]),
    );
  }
}

// ── Energy page ───────────────────────────────────────────────────────────────
class EnergyPage extends StatelessWidget {
  final Vehicle v;
  const EnergyPage({required this.v});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
      ]),
    );
  }
}

// ── Comfort page ──────────────────────────────────────────────────────────────
class ComfortPage extends StatelessWidget {
  final Vehicle v;
  const ComfortPage({required this.v});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionLabel('Climate'),
        ClimateSection(v: v),
        const SizedBox(height: 16),
        const SectionLabel('Tyres'),
        TyreSection(v: v),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── No data placeholder ───────────────────────────────────────────────────────
class NoDataPlaceholder extends StatelessWidget {
  final AppProvider provider;
  const NoDataPlaceholder({required this.provider});
  @override
  Widget build(BuildContext context) {
    if (provider.state == AppState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.directions_car_outlined, size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('No vehicle data',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Log in to Bluelink to fetch live data,\n'
            'or load a snapshot from your Solid Pod.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HyundaiColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(provider.errorMessage!,
                  style: const TextStyle(
                      color: HyundaiColors.error, fontSize: 12)),
            ),
          ],
        ]),
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
    final cs  = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yyyy HH:mm:ss');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (lastUpdated != null)
        _TsLine('Last updated', fmt.format(lastUpdated!), cs),
      if (fetchedAt != null)
        _TsLine('Fetched at', fmt.format(fetchedAt!), cs),
    ]);
  }
}

class _TsLine extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const _TsLine(this.label, this.value, this.cs);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      Icon(Icons.access_time, size: 13,
          color: cs.onSurfaceVariant),
      const SizedBox(width: 6),
      Text('$label: ',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      Text(value,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
    ]),
  );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );
}
