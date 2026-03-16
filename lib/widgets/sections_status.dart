import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../models/vehicle.dart';
import '../theme/hyundai_theme.dart';
import '../widgets/stat_card.dart';
import 'primitives.dart';
import 'tiles.dart';

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.modelName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              if (v.color.isNotEmpty)
                Text(v.color,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: HyundaiColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(v.fuelType,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
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
            StatusBadge(
              active: true,
              activeLabel: 'Charging',
              inactiveLabel: '',
              activeColor: HyundaiColors.accent,
            ),
          if (v.isPluggedIn == true && v.isChargingOn != true)
            StatusBadge(
              active: true,
              activeLabel: 'Plugged In',
              inactiveLabel: '',
              activeColor: const Color(0xFF6C63FF),
            ),
          if (v.isClimateOn == true)
            StatusBadge(
              active: true,
              activeLabel: 'Climate On',
              inactiveLabel: '',
              activeColor: const Color(0xFF00B4D8),
            ),
          if (v.isAccOn == true)
            StatusBadge(
              active: true,
              activeLabel: 'ACC On',
              inactiveLabel: '',
              activeColor: HyundaiColors.warning,
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.speed, color: Colors.white54, size: 16),
          const SizedBox(width: 6),
          Text(
            v.odometerKm != null
                ? '${NumberFormat('#,##0').format(v.odometerKm!.round())} km'
                : '– km',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if (v.evRangeKm != null || v.fuelRangeKm != null) ...[
            const SizedBox(width: 16),
            const Icon(Icons.route, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              '${(v.evRangeKm ?? v.fuelRangeKm)!.round()} km available',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ],
          if (v.batteryLevelPercent != null) ...[
            const SizedBox(width: 16),
            const Icon(Icons.battery_charging_full,
                color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              '${v.batteryLevelPercent!.round()}% charge',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ],
          const Spacer(),
          if (v.vin.isNotEmpty)
            Text(
              v.vin.length > 8
                  ? '…${v.vin.substring(v.vin.length - 8)}'
                  : v.vin,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
            ),
        ]),
      ]),
    );
  }
}

class DoorsSection extends StatelessWidget {
  final Vehicle v;
  const DoorsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(children: [
        Row(children: [
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
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DoorTile('Front Left', v.isDoorFrontLeftOpen)),
          const SizedBox(width: 8),
          Expanded(child: DoorTile('Front Right', v.isDoorFrontRightOpen)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DoorTile('Rear Left', v.isDoorRearLeftOpen)),
          const SizedBox(width: 8),
          Expanded(child: DoorTile('Rear Right', v.isDoorRearRightOpen)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DoorTile('Boot', v.isTrunkOpen)),
          const SizedBox(width: 8),
          Expanded(child: DoorTile('Bonnet', v.isBonnetOpen)),
        ]),
      ]),
    );
  }
}

class WindowsSection extends StatelessWidget {
  final Vehicle v;
  const WindowsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(children: [
        Row(children: [
          Expanded(
              child: DoorTile('Front Left', v.isWindowFrontLeftOpen,
                  isWindow: true)),
          const SizedBox(width: 8),
          Expanded(
              child: DoorTile('Front Right', v.isWindowFrontRightOpen,
                  isWindow: true)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: DoorTile('Rear Left', v.isWindowRearLeftOpen,
                  isWindow: true)),
          const SizedBox(width: 8),
          Expanded(
              child: DoorTile('Rear Right', v.isWindowRearRightOpen,
                  isWindow: true)),
        ]),
      ]),
    );
  }
}

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
          ? const Row(children: [
              Icon(Icons.check_circle, color: HyundaiColors.success, size: 20),
              SizedBox(width: 10),
              Text('No active warnings',
                  style: TextStyle(
                      color: HyundaiColors.success,
                      fontWeight: FontWeight.w600)),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          const Icon(Icons.warning_amber,
                              color: HyundaiColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text(w,
                              style: const TextStyle(
                                  color: HyundaiColors.error, fontSize: 13)),
                        ]),
                      ))
                  .toList(),
            ),
    );
  }
}
