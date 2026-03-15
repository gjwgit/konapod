import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../models/vehicle.dart';
import '../theme/hyundai_theme.dart';
import '../widgets/stat_card.dart';
import 'dashboard_widgets.dart';

/// Content sections for the vehicle dashboard.
/// Each section takes a Vehicle and renders one card.

// ─── Hero ─────────────────────────────────────────────────────────────────────
class HeroCard extends StatelessWidget {
  final Vehicle v;
  const HeroCard({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HyundaiColors.primary, Color(0xFF00497A)],
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (v.color.isNotEmpty)
                      Text(
                        v.color,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HyundaiColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v.fuelType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                active: v.isLocked == true,
                activeLabel: 'Locked',
                inactiveLabel: 'Unlocked',
                activeColor: HyundaiColors.success,
              ),
              StatusBadge(
                active: v.isEngineRunning == true,
                activeLabel: 'Engine On',
                inactiveLabel: 'Engine Off',
                activeColor: HyundaiColors.warning,
              ),
              if (v.isChargingOn == true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'Charging',
                  inactiveLabel: '',
                  activeColor: HyundaiColors.accent,
                ),
              if (v.isPluggedIn == true && v.isChargingOn != true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'Plugged In',
                  inactiveLabel: '',
                  activeColor: Color(0xFF6C63FF),
                ),
              if (v.isClimateOn == true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'Climate On',
                  inactiveLabel: '',
                  activeColor: Color(0xFF00B4D8),
                ),
              if (v.isAccOn == true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'ACC On',
                  inactiveLabel: '',
                  activeColor: HyundaiColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(
                v.odometerKm != null
                    ? '${NumberFormat('#,##0').format(v.odometerKm!.round())} km'
                    : '– km',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (v.vin.isNotEmpty)
                Text(
                  v.vin.length > 8
                      ? '…${v.vin.substring(v.vin.length - 8)}'
                      : v.vin,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Battery ──────────────────────────────────────────────────────────────────
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
              const Text(
                'Battery',
                style: TextStyle(
                  color: HyundaiColors.darkGrey,
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
              backgroundColor: HyundaiColors.lightGrey,
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
                  '${v.batteryCapacityKwh!.toStringAsFixed(1)} kWh',
                  Icons.bolt,
                ),
              ],
              if (v.estimatedChargeCompletionMinutes != null &&
                  v.isChargingOn == true) ...[
                const SizedBox(width: 20),
                StatChip(
                  'Full in',
                  _fmtMin(v.estimatedChargeCompletionMinutes!),
                  Icons.timer,
                  color: HyundaiColors.accent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: HyundaiColors.lightGrey),
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
            const Divider(height: 16, color: HyundaiColors.lightGrey),
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

// ─── Fuel ─────────────────────────────────────────────────────────────────────
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
              const Text(
                'Fuel',
                style: TextStyle(
                  color: HyundaiColors.darkGrey,
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
              backgroundColor: HyundaiColors.lightGrey,
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

// ─── Doors ────────────────────────────────────────────────────────────────────
class DoorsSection extends StatelessWidget {
  final Vehicle v;
  const DoorsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BigStatusTile(
                  icon: v.isLocked == true ? Icons.lock : Icons.lock_open,
                  label: 'Doors',
                  value: v.isLocked == null
                      ? '–'
                      : v.isLocked!
                          ? 'Locked'
                          : 'Unlocked',
                  color: v.isLocked == true
                      ? HyundaiColors.success
                      : HyundaiColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BigStatusTile(
                  icon: Icons.directions_car,
                  label: 'Engine',
                  value: v.isEngineRunning == null
                      ? '–'
                      : v.isEngineRunning!
                          ? 'Running'
                          : 'Off',
                  color: v.isEngineRunning == true
                      ? HyundaiColors.warning
                      : HyundaiColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: HyundaiColors.lightGrey),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: DoorTile('Front Left', v.isDoorFrontLeftOpen)),
              const SizedBox(width: 8),
              Expanded(child: DoorTile('Front Right', v.isDoorFrontRightOpen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: DoorTile('Rear Left', v.isDoorRearLeftOpen)),
              const SizedBox(width: 8),
              Expanded(child: DoorTile('Rear Right', v.isDoorRearRightOpen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: DoorTile('Boot', v.isTrunkOpen)),
              const SizedBox(width: 8),
              Expanded(child: DoorTile('Bonnet', v.isBonnetOpen)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Windows ──────────────────────────────────────────────────────────────────
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

// ─── Climate ──────────────────────────────────────────────────────────────────
class ClimateSection extends StatelessWidget {
  final Vehicle v;
  const ClimateSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusRow(
            Icons.air,
            'Climate Control',
            v.isClimateOn == true,
            const Color(0xFF00B4D8),
          ),
          StatusRow(
            Icons.ac_unit,
            'Front Defrost',
            v.isDefrostingOn == true,
            HyundaiColors.accent,
          ),
          StatusRow(
            Icons.back_hand_outlined,
            'Rear Window Heat',
            v.isRearWindowDefrostOn == true,
            HyundaiColors.accent,
          ),
          StatusRow(
            Icons.settings_input_component,
            'Steering Wheel Heat',
            v.isSteeringWheelHeatOn == true,
            HyundaiColors.warning,
          ),
          StatusRow(
            Icons.wb_sunny_outlined,
            'Side Mirror Heat',
            v.isSideMirrorHeatOn == true,
            HyundaiColors.warning,
          ),
          if (v.targetTempC != null) ...[
            const Divider(height: 16, color: HyundaiColors.lightGrey),
            KVRow('Set Temperature', '${v.targetTempC!.toStringAsFixed(1)}°C'),
          ],
          if (v.seatHeatFrontLeft != null ||
              v.seatHeatFrontRight != null ||
              v.seatHeatRearLeft != null ||
              v.seatHeatRearRight != null) ...[
            const Divider(height: 16, color: HyundaiColors.lightGrey),
            Row(
              children: [
                const Icon(
                  Icons.airline_seat_recline_normal,
                  color: HyundaiColors.midGrey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Seat Heat',
                    style: TextStyle(
                      color: HyundaiColors.darkGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (v.seatHeatFrontLeft != null)
                  SeatBadge('FL', v.seatHeatFrontLeft!),
                if (v.seatHeatFrontRight != null) ...[
                  const SizedBox(width: 4),
                  SeatBadge('FR', v.seatHeatFrontRight!),
                ],
                if (v.seatHeatRearLeft != null) ...[
                  const SizedBox(width: 4),
                  SeatBadge('RL', v.seatHeatRearLeft!),
                ],
                if (v.seatHeatRearRight != null) ...[
                  const SizedBox(width: 4),
                  SeatBadge('RR', v.seatHeatRearRight!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tyres ────────────────────────────────────────────────────────────────────
class TyreSection extends StatelessWidget {
  final Vehicle v;
  const TyreSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final allOk = v.tyrePressureWarningAll != true &&
        v.tyrePressureWarningFrontLeft != true &&
        v.tyrePressureWarningFrontRight != true &&
        v.tyrePressureWarningRearLeft != true &&
        v.tyrePressureWarningRearRight != true;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tire_repair,
                color: allOk ? HyundaiColors.success : HyundaiColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                allOk ? 'All tyres OK' : 'Tyre pressure warning',
                style: TextStyle(
                  color: allOk ? HyundaiColors.success : HyundaiColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TyreTile(
                  'Front Left',
                  v.tyrePressureWarningFrontLeft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TyreTile(
                  'Front Right',
                  v.tyrePressureWarningFrontRight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TyreTile('Rear Left', v.tyrePressureWarningRearLeft),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TyreTile('Rear Right', v.tyrePressureWarningRearRight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Warnings ─────────────────────────────────────────────────────────────────
class WarningsSection extends StatelessWidget {
  final Vehicle v;
  const WarningsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final warnings = <String>[
      if (v.isLowFuelWarning == true) 'Low fuel',
      if (v.tyrePressureWarningAll == true) 'Tyre pressure (all)',
      if (v.tyrePressureWarningFrontLeft == true) 'Tyre pressure FL',
      if (v.tyrePressureWarningFrontRight == true) 'Tyre pressure FR',
      if (v.tyrePressureWarningRearLeft == true) 'Tyre pressure RL',
      if (v.tyrePressureWarningRearRight == true) 'Tyre pressure RR',
      if (v.is12VBatteryWarning == true) '12V battery low',
      if (v.isSmartKeyBatteryWarning == true) 'Smart key battery',
      if (v.isWasherFluidWarning == true) 'Washer fluid low',
      if (v.isBrakingFluidWarning == true) 'Braking fluid low',
    ];
    return DashboardCard(
      child: warnings.isEmpty
          ? const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: HyundaiColors.success,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'No active warnings',
                  style: TextStyle(
                    color: HyundaiColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: HyundaiColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            w,
                            style: const TextStyle(
                              color: HyundaiColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ─── Vehicle Info ─────────────────────────────────────────────────────────────
class InfoSection extends StatelessWidget {
  final Vehicle v;
  const InfoSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      if (v.vin.isNotEmpty) MapEntry('VIN', v.vin),
      MapEntry('Model', v.modelName),
      if (v.modelYear.isNotEmpty) MapEntry('Year', v.modelYear),
      if (v.trim.isNotEmpty) MapEntry('Trim', v.trim),
      MapEntry('Powertrain', v.fuelType),
      if (v.color.isNotEmpty) MapEntry('Colour', v.color),
      if (v.odometerKm != null)
        MapEntry(
          'Odometer',
          '${NumberFormat('#,##0').format(v.odometerKm!.round())} km',
        ),
      if (v.totalDrivenKm != null)
        MapEntry(
          'Total Driven',
          '${NumberFormat('#,##0').format(v.totalDrivenKm!.round())} km',
        ),
      if (v.dailyDrivenKm != null)
        MapEntry('Today', '${v.dailyDrivenKm!.toStringAsFixed(1)} km'),
      if (v.latitude != null && v.longitude != null)
        MapEntry(
          'GPS',
          '${v.latitude!.toStringAsFixed(5)}, ${v.longitude!.toStringAsFixed(5)}',
        ),
      if (v.locationAddress != null && v.locationAddress!.isNotEmpty)
        MapEntry('Address', v.locationAddress!),
      if (v.battery12VPercent != null)
        MapEntry('12V Battery', '${v.battery12VPercent}%'),
      if (v.lastUpdated != null)
        MapEntry(
          'Last Updated',
          DateFormat('dd MMM yyyy HH:mm').format(v.lastUpdated!),
        ),
    ];
    return KVTable(rows);
  }
}

// ─── Additional / Extra Data ──────────────────────────────────────────────────
class ExtrasSection extends StatelessWidget {
  final Map<String, dynamic> extras;
  const ExtrasSection({super.key, required this.extras});
  @override
  Widget build(BuildContext context) {
    final rows = extras.entries
        .where(
          (e) =>
              e.value != null &&
              e.value != false &&
              e.value != 0 &&
              e.value != '',
        )
        .map(
          (e) => MapEntry(e.key.replaceAll('_', ' '), e.value.toString()),
        )
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return KVTable(rows);
  }
}
