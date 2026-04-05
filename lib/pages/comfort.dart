/// ComfortPage — climate and tyre sections.
///
// Time-stamp: <Wednesday 2026-03-18 22:06:27 +1100 Graham Williams>
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

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/widgets/section_label.dart';
import 'package:konapod/widgets/sections_comfort.dart';

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
          const SectionLabel(
            'Climate',
            tooltip: '**Climate Control**\n\n'
                'Heating and cooling system status including '
                'cabin temperature settings, defrost, and steering wheel heater.',
          ),
          ClimateSection(v: v),
          const Gap(16),
          const SectionLabel(
            'Tyres',
            tooltip: '**Tyres**\n\n'
                'Tyre pressure status for each wheel. '
                'A warning (amber) indicates the pressure is outside '
                'the recommended range. Pressure values are in psi '
                'when available from the car.',
          ),
          TyreSection(v: v),
          const Gap(24),
        ],
      ),
    );
  }
}
