/// DoorsSection widget showing lock, engine, charging and door states.
///
// Time-stamp: <Wednesday 2026-03-18 09:56:35 +1100 Graham Williams>
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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/stat_card.dart';

class BatterySection extends StatelessWidget {
  final Vehicle v;
  const BatterySection({super.key, required this.v});

  static String _fmtMin(double m) {
    if (m < 60) return '${m.round()} min';
    final h = (m / 60).floor();
    final r = (m % 60).round();
    return r > 0 ? '${h}h ${r}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final pct = v.batteryLevelPercent ?? 0;
    final barColor = pct < 20
        ? HyundaiColors.error
        : pct < 40
            ? HyundaiColors.warning
            : HyundaiColors.success;

    final hasCharge = v.evRangeKm != null ||
        v.chargingCurrentAc != null ||
        v.chargingPowerKw != null ||
        (v.estimatedChargeCompletionMinutes != null &&
            v.estimatedChargeCompletionMinutes! > 0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HyundaiColors.primary, Color(0xFF7A5C44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HyundaiColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                color: Colors.white70,
                size: 20,
              ),
              const Gap(8),
              const Text(
                'Battery',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
              const Gap(12),
              if (v.isPluggedIn == true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'Plugged In',
                  inactiveLabel: '',
                  activeColor: HyundaiColors.accent,
                ),
              if (v.isChargingOn == true) ...[
                const Gap(8),
                const StatusBadge(
                  active: true,
                  activeLabel: 'Charging',
                  inactiveLabel: '',
                  activeColor: HyundaiColors.accent,
                ),
              ],
              const Spacer(),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(10),
          // ── Progress bar ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const Gap(14),
          // ── Battery stats line ────────────────────────────────────────────
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              if (v.batteryCapacityKwh != null)
                _HeroChip(
                  'Capacity',
                  '${(v.batteryCapacityKwh! / 3600).toStringAsFixed(1)} kWh',
                  Icons.bolt,
                  tooltip: '**Battery Capacity**\n\n'
                      'The total amount of energy the battery can store, '
                      'shown here in kilowatt-hours (kWh).\n\n'
                      'Think of it like the size of a fuel tank — a bigger number '
                      'means more energy available for driving. '
                      'The Kona EV has a 64.8 kWh usable capacity.\n\n'
                      '*Note: the API reports this in kilojoules (kJ); '
                      'dividing by 3600 converts to kWh.*',
                ),
              if (v.batteryRemainKwh != null)
                _HeroChip(
                  'Remaining',
                  '${(v.batteryRemainKwh! / 3600).toStringAsFixed(1)} kWh',
                  Icons.battery_full,
                  tooltip: '**Energy Remaining**\n\n'
                      'How much energy is currently stored in the battery, '
                      'shown here in kilowatt-hours (kWh).\n\n'
                      'This is your battery percentage expressed as actual energy. '
                      'For example, 58% of a 64.8 kWh battery '
                      '= roughly 37.6 kWh remaining.\n\n'
                      'Divide by your typical consumption (kWh/100km) '
                      'to estimate how far you can drive.\n\n'
                      '*Note: the API reports this in kilojoules (kJ); '
                      'dividing by 3600 converts to kWh.*',
                ),
              if (v.batterySohPercent != null)
                _HeroChip(
                  'State of Health',
                  '${v.batterySohPercent!.toStringAsFixed(0)}%',
                  Icons.health_and_safety,
                  tooltip: '**State of Health (SoH)**\n\n'
                      'How much of the battery\'s *original* capacity it can '
                      'still hold, as a percentage.\n\n'
                      '**100%** means the battery performs like new. '
                      'Over time, chemical changes inside the cells gradually '
                      'reduce how much energy they can store — this is normal '
                      'degradation that happens with all lithium-ion batteries.\n\n'
                      'Most manufacturers guarantee batteries stay above **70% SoH** '
                      'for 8 years or 160,000 km. Real-world data shows most EVs '
                      'lose only 2–3% per year in normal use.\n\n'
                      'A 90% SoH on a 64.8 kWh battery means it now holds ~58.3 kWh.',
                ),
              if (v.totalPowerConsumedKwh != null)
                _HeroChip(
                  'Total Consumed',
                  '${v.totalPowerConsumedKwh!} kWh',
                  Icons.electric_meter,
                  tooltip: '**Lifetime Total Consumed**\n\n'
                      'The total energy drawn from the battery across all driving '
                      'since the car was new, in kilowatt-hours (kWh).\n\n'
                      'This is the cumulative odometer of energy use. '
                      'Divide by total kilometres driven to get your lifetime '
                      'average efficiency.',
                ),
              if (v.powerConsumption30dKwh != null)
                _HeroChip(
                  'Last 30 Days',
                  '${v.powerConsumption30dKwh!} kWh',
                  Icons.calendar_month,
                  tooltip: '**Last 30 Days Consumption**\n\n'
                      'Total energy consumed over the past 30 days, '
                      'in kilowatt-hours (kWh).\n\n'
                      'A useful measure of recent usage patterns. '
                      'Divide by the distance driven in 30 days to see your '
                      'recent average efficiency.',
                ),
            ],
          ),
          // ── Charge line ───────────────────────────────────────────────────
          if (hasCharge) ...[
            const Gap(12),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const Gap(10),
            Row(
              children: [
                const Text(
                  'Charge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      if (v.evRangeKm != null)
                        _HeroChip(
                          'Range',
                          '${v.evRangeKm!.round()} km',
                          Icons.route,
                          tooltip: '**Estimated Range**\n\n'
                              'How far the car estimates it can travel on the '
                              'current charge, in kilometres.\n\n'
                              'Calculated by the car\'s onboard computer based on '
                              'current battery level, recent driving style, speed, '
                              'temperature, and climate control use. '
                              'Highway driving and cold weather will reduce this figure.',
                        ),
                      if (v.chargingCurrentAc != null)
                        _HeroChip(
                          'Current',
                          '${v.chargingCurrentAc!.toStringAsFixed(0)} A',
                          Icons.electric_bolt,
                          tooltip: '**Charging Current (Amps)**\n\n'
                              'The rate of electrical current flowing into the battery, '
                              'measured in amperes (A).\n\n'
                              'Think of it like the *flow rate* of water through a hose — '
                              'higher amps means more electricity per second, '
                              'which means faster charging.\n\n'
                              'A standard home wall charger typically delivers 8–16 A. '
                              'The car\'s onboard charger limits how much it will accept '
                              'regardless of what the charger can supply.',
                        ),
                      if (v.chargingPowerKw != null)
                        _HeroChip(
                          'Power',
                          '${v.chargingPowerKw!.toStringAsFixed(1)} kW',
                          Icons.flash_on,
                          tooltip: '**Charging Power (kW)**\n\n'
                              'The total rate at which energy is entering the battery, '
                              'measured in kilowatts (kW).\n\n'
                              'Power = Voltage × Current ÷ 1000. '
                              'A 7.4 kW home charger adds roughly 40–50 km of range '
                              'per hour. DC fast chargers deliver 50–100 kW, '
                              'adding the same range in minutes.\n\n'
                              'Charging slows above 80% to protect the battery.',
                        ),
                      if (v.estimatedChargeCompletionMinutes != null &&
                          v.estimatedChargeCompletionMinutes! > 0)
                        _HeroChip(
                          'Time to 100%',
                          _fmtMin(v.estimatedChargeCompletionMinutes!),
                          Icons.timer,
                          tooltip: '**Time to Full Charge**\n\n'
                              'The car\'s estimate of how long until the battery '
                              'reaches 100% at the current charging rate.\n\n'
                              'This updates as charging progresses. '
                              'The final 20% (80–100%) always takes proportionally '
                              'longer because the car deliberately slows the charge '
                              'rate to protect battery longevity.',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact stat chip styled for the hero card (white text on dark bg).
class _HeroChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color = Colors.white;
  final String? tooltip;
  const _HeroChip(
    this.label,
    this.value,
    this.icon, {
    this.tooltip,
  });
  @override
  Widget build(BuildContext context) {
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? Colors.white60),
        const Gap(4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
    if (tooltip == null) return chip;
    return MarkdownTooltip(message: tooltip!, child: chip);
  }
}
