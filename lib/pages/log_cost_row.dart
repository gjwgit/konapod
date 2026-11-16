/// LogCostRow — the cost per kWh and total cost of a charging session.
///
// Time-stamp: <Monday 2026-11-16 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:konapod/pages/log_cost_field.dart';

/// The cost per kWh beside the total cost. Either can be worked out from the
/// other, and whichever was worked out is noted as calculated.

class LogCostRow extends StatelessWidget {
  final TextEditingController costPerKwh;
  final TextEditingController totalCost;

  /// The cost per kWh the app worked out from the total cost, or null when
  /// it has not. The field is noted as calculated while it still shows this.
  final String? calculatedCostPerKwh;

  /// The total cost the app worked out from the cost per kWh, or null. As
  /// for [calculatedCostPerKwh].
  final String? calculatedTotalCost;

  const LogCostRow({
    super.key,
    required this.costPerKwh,
    required this.totalCost,
    required this.calculatedCostPerKwh,
    required this.calculatedTotalCost,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LogCostField(
              controller: costPerKwh,
              label: 'Cost per kWh',
              calculated: calculatedCostPerKwh,
              tooltip: '''

**Calculated Cost per kWh**

Worked out as the total cost divided by the energy charged, as no cost per
kWh was entered. Type a cost per kWh to replace it.

''',
            ),
          ),
          const Gap(16),
          Expanded(
            child: LogCostField(
              controller: totalCost,
              label: 'Total cost',
              calculated: calculatedTotalCost,
              tooltip: '''

**Calculated Total Cost**

Worked out as the cost per kWh times the energy charged. Type a total cost to
replace it.

''',
            ),
          ),
        ],
      );
}
