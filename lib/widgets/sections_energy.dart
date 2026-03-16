import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/hyundai_theme.dart';
import 'primitives.dart';

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
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                color: HyundaiColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Battery',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (v.evRangeKm != null)
                StatChip('Range', '${v.evRangeKm!.round()} km', Icons.route),
              if (v.batteryCapacityKwh != null) ...[
                const SizedBox(width: 20),
                StatChip(
                  'Capacity',
                  '${(v.batteryCapacityKwh! / 1000).toStringAsFixed(1)} kWh',
                  Icons.bolt,
                ),
              ],
              if (v.batteryRemainKwh != null) ...[
                const SizedBox(width: 20),
                StatChip(
                  'Remain',
                  '${(v.batteryRemainKwh! / 1000).toStringAsFixed(1)} kWh',
                  Icons.battery_full,
                ),
              ],
              if (v.batterySohPercent != null) ...[
                const SizedBox(width: 20),
                StatChip(
                  'SOH',
                  '${v.batterySohPercent!.toStringAsFixed(0)}%',
                  Icons.health_and_safety,
                ),
              ],
            ],
          ),
          if (v.chargingCurrentAc != null ||
              v.chargingPowerKw != null ||
              v.estimatedChargeCompletionMinutes != null ||
              v.estimatedFastChargeMins != null ||
              v.estimatedPortableChargeMins != null ||
              v.estimatedStationChargeMins != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                if (v.chargingCurrentAc != null)
                  StatChip(
                    'Current',
                    '${v.chargingCurrentAc!.toStringAsFixed(0)} A',
                    Icons.electric_bolt,
                  ),
                if (v.chargingPowerKw != null)
                  StatChip(
                    'Power',
                    '${v.chargingPowerKw!.toStringAsFixed(1)} kW',
                    Icons.flash_on,
                  ),
                if (v.estimatedChargeCompletionMinutes != null &&
                    v.estimatedChargeCompletionMinutes! > 0)
                  StatChip(
                    'Current Charge',
                    _fmtMin(v.estimatedChargeCompletionMinutes!),
                    Icons.timer,
                    color: HyundaiColors.accent,
                  ),
                if (v.estimatedFastChargeMins != null)
                  StatChip(
                    'Fast Charge',
                    _fmtMin(v.estimatedFastChargeMins!),
                    Icons.bolt,
                    color: HyundaiColors.accent,
                  ),
                if (v.estimatedPortableChargeMins != null)
                  StatChip(
                    'Portable',
                    _fmtMin(v.estimatedPortableChargeMins!),
                    Icons.power,
                  ),
                if (v.estimatedStationChargeMins != null)
                  StatChip(
                    'Station',
                    _fmtMin(v.estimatedStationChargeMins!),
                    Icons.ev_station,
                    color: HyundaiColors.accent,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          StatusRow(
            Icons.power,
            'Charging',
            v.isChargingOn == true,
            HyundaiColors.accent,
          ),
          StatusRow(
            Icons.electrical_services,
            'Plugged In',
            v.isPluggedIn == true,
            const Color(0xFF6C63FF),
          ),
          if (v.isChargeScheduledOn != null)
            StatusRow(
              Icons.schedule,
              'Charge Scheduled',
              v.isChargeScheduledOn == true,
              HyundaiColors.accent,
            ),
          if (v.targetSocAC != null) ...[
            const SizedBox(height: 8),
            KVRow('Target SOC (AC)', '${v.targetSocAC}%'),
          ],
          if (v.targetSocDC != null)
            KVRow('Target SOC (DC)', '${v.targetSocDC}%'),
          if (v.battery12VPercent != null) ...[
            Divider(
              height: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Row(
              children: [
                Icon(
                  Icons.battery_0_bar,
                  size: 16,
                  color: (v.battery12VPercent ?? 100) < 20
                      ? HyundaiColors.error
                      : HyundaiColors.midGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  '12V Battery: ${v.battery12VPercent}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: (v.battery12VPercent ?? 100) < 20
                        ? HyundaiColors.error
                        : HyundaiColors.darkGrey,
                  ),
                ),
                if (v.is12VBatteryWarning == true)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.warning_amber,
                      color: HyundaiColors.error,
                      size: 16,
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

class FuelSection extends StatelessWidget {
  final Vehicle v;
  const FuelSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final pct = v.fuelLevelPercent ?? 0;
    final barColor = pct < 15 ? HyundaiColors.error : HyundaiColors.warning;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_gas_station,
                color: HyundaiColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fuel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (v.fuelRangeKm != null) ...[
            const SizedBox(height: 10),
            StatChip('Range', '${v.fuelRangeKm!.round()} km', Icons.route),
          ],
          if (v.isLowFuelWarning == true) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.warning_amber, color: HyundaiColors.error, size: 16),
                SizedBox(width: 6),
                Text(
                  'Low fuel warning',
                  style: TextStyle(color: HyundaiColors.error, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
