/// LocationMapCard — shows the vehicle's current GPS location on a map.
///
// Time-stamp: <2026-05-30>
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

import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/primitives.dart';

/// Displays a small OpenStreetMap view centred on the vehicle's last known
/// GPS position with a marker. Renders nothing if no coordinates are set.
class LocationMapCard extends StatelessWidget {
  final Vehicle v;
  const LocationMapCard({super.key, required this.v});

  @override
  Widget build(BuildContext context) {
    final lat = v.latitude;
    final lng = v.longitude;
    if (lat == null || lng == null) return const SizedBox.shrink();

    final point = LatLng(lat, lng);
    final cs = Theme.of(context).colorScheme;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.locationAddress != null && v.locationAddress!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: cs.primary),
                const Gap(6),
                Expanded(
                  child: Text(
                    v.locationAddress!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                  // A static display — disable rotation but allow the user
                  // to pan and zoom to explore the surroundings.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.togaware.konapod',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: HyundaiColors.accent,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),
          // Attribution is required by the OpenStreetMap tile usage policy.
          Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
          ),
          Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
