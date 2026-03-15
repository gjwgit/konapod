import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../theme/hyundai_theme.dart';
import 'primitives.dart';
import 'tiles.dart';


class ClimateSection extends StatelessWidget {
  final Vehicle v;
  const ClimateSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StatusRow(Icons.air, 'Climate Control', v.isClimateOn == true,
            const Color(0xFF00B4D8)),
        StatusRow(Icons.ac_unit, 'Front Defrost', v.isDefrostingOn == true,
            HyundaiColors.accent),
        StatusRow(Icons.back_hand_outlined, 'Rear Window Heat',
            v.isRearWindowDefrostOn == true, HyundaiColors.accent),
        StatusRow(Icons.settings_input_component, 'Steering Wheel Heat',
            v.isSteeringWheelHeatOn == true, HyundaiColors.warning),
        StatusRow(Icons.wb_sunny_outlined, 'Side Mirror Heat',
            v.isSideMirrorHeatOn == true, HyundaiColors.warning),
        if (v.targetTempC != null) ...[
          const Divider(height: 16, color: HyundaiColors.lightGrey),
          KVRow('Set Temperature', '${v.targetTempC!.toStringAsFixed(1)}°C'),
        ],
        if (v.seatHeatFrontLeft != null ||
            v.seatHeatFrontRight != null ||
            v.seatHeatRearLeft != null ||
            v.seatHeatRearRight != null) ...[
          const Divider(height: 16, color: HyundaiColors.lightGrey),
          Row(children: [
            const Icon(Icons.airline_seat_recline_normal,
                color: HyundaiColors.midGrey, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Seat Heat',
                  style: TextStyle(
                      color: HyundaiColors.darkGrey, fontSize: 13)),
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
          ]),
        ],
      ]),
    );
  }
}

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.tire_repair,
              color: allOk ? HyundaiColors.success : HyundaiColors.error,
              size: 18),
          const SizedBox(width: 8),
          Text(
            allOk ? 'All tyres OK' : 'Tyre pressure warning',
            style: TextStyle(
              color: allOk ? HyundaiColors.success : HyundaiColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TyreTile(
                  'Front Left', v.tyrePressureWarningFrontLeft)),
          const SizedBox(width: 8),
          Expanded(
              child: TyreTile(
                  'Front Right', v.tyrePressureWarningFrontRight)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child:
                  TyreTile('Rear Left', v.tyrePressureWarningRearLeft)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  TyreTile('Rear Right', v.tyrePressureWarningRearRight)),
        ]),
      ]),
    );
  }
}

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
        MapEntry('Odometer',
            '${NumberFormat('#,##0').format(v.odometerKm!.round())} km'),
      if (v.totalDrivenKm != null)
        MapEntry('Total Driven',
            '${NumberFormat('#,##0').format(v.totalDrivenKm!.round())} km'),
      if (v.dailyDrivenKm != null)
        MapEntry('Today', '${v.dailyDrivenKm!.toStringAsFixed(1)} km'),
      if (v.latitude != null && v.longitude != null)
        MapEntry('GPS',
            '${v.latitude!.toStringAsFixed(5)}, ${v.longitude!.toStringAsFixed(5)}'),
      if (v.locationAddress != null && v.locationAddress!.isNotEmpty)
        MapEntry('Address', v.locationAddress!),
      if (v.battery12VPercent != null)
        MapEntry('12V Battery', '${v.battery12VPercent}%'),
      if (v.lastUpdated != null)
        MapEntry('Last Updated',
            DateFormat('dd MMM yyyy HH:mm').format(v.lastUpdated!)),
    ];
    return KVTable(rows);
  }
}

class ExtrasSection extends StatelessWidget {
  final Map<String, dynamic> extras;
  const ExtrasSection({super.key, required this.extras});
  @override
  Widget build(BuildContext context) {
    final rows = extras.entries
        .where((e) =>
            e.value != null &&
            e.value != false &&
            e.value != 0 &&
            e.value != '')
        .map((e) =>
            MapEntry(e.key.replaceAll('_', ' '), e.value.toString()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return KVTable(rows);
  }
}
