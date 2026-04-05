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
import 'package:konapod/widgets/primitives.dart';

class BatteryStatusCard extends StatelessWidget {
  final Vehicle v;
  const BatteryStatusCard({super.key, required this.v});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.isChargeScheduledOn != null)
            MarkdownTooltip(
              message: '**Charge Schedule**\n\n'
                  'Whether a timed charge is configured. When enabled, '
                  'the car will only begin charging during the scheduled '
                  'window — useful for off-peak electricity rates.',
              child: StatusRow(
                Icons.schedule,
                'Charge Scheduled',
                v.isChargeScheduledOn == true,
                HyundaiColors.accent,
              ),
            ),
          if (v.targetSocAC != null) ...[
            const Gap(8),
            MarkdownTooltip(
              message: '**Target SOC (AC)**\n\n'
                  'The charge level the car will stop at when using an '
                  'AC (slow) charger — typically a home wall box.\n\n'
                  'Setting this below 100% helps preserve battery '
                  'longevity for daily driving.',
              child: KVRow('Target SOC (AC)', '${v.targetSocAC}%'),
            ),
          ],
          if (v.targetSocDC != null)
            MarkdownTooltip(
              message: '**Target SOC (DC)**\n\n'
                  'The charge level the car will stop at when using a '
                  'DC (fast) charger.\n\n'
                  'Usually set to 80% because DC charging above 80% '
                  'is much slower and generates more heat.',
              child: KVRow('Target SOC (DC)', '${v.targetSocDC}%'),
            ),
          if (v.battery12VPercent != null) ...[
            Divider(
              height: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            MarkdownTooltip(
              message: '**12V Auxiliary Battery**\n\n'
                  'The small lead-acid battery that powers the car\'s '
                  'electronics (lights, computer, locks) when the main '
                  'EV battery is off.\n\n'
                  'Below 20% is a warning — the car may not start. '
                  'The main battery trickle-charges the 12V battery '
                  'periodically.',
              child: Row(
                children: [
                  Icon(
                    Icons.battery_0_bar,
                    size: 16,
                    color: (v.battery12VPercent ?? 100) < 20
                        ? HyundaiColors.error
                        : HyundaiColors.midGrey,
                  ),
                  const Gap(8),
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
            ),
          ],
        ],
      ),
    );
  }
}
