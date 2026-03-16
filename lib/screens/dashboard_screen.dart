/// A Bluelink app for Hyundai
///
// Time-stamp: <Monday 2026-03-16 22:01:12 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../services/app_provider.dart';
import '../theme/hyundai_theme.dart';
import '../widgets/sections_comfort.dart';
import '../widgets/sections_energy.dart';
import '../widgets/sections_status.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final v = provider.selectedVehicle;
        return Scaffold(
          backgroundColor: HyundaiColors.scaffoldBg,
          appBar: _buildAppBar(context, provider, v),
          body: v == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: provider.refresh,
                  color: HyundaiColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _DashboardBody(v: v),
                  ),
                ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AppProvider provider,
    Vehicle? v,
  ) {
    return AppBar(
      title: v != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.nickname,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${v.modelYear} ${v.modelName}'
                  '${v.trim.isNotEmpty ? ' · ${v.trim}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            )
          : const Text('Konapod'),
      actions: [
        if (provider.isRefreshing)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.refresh,
          ),
        PopupMenuButton<String>(
          onSelected: (val) async {
            if (val == 'logout') {
              await provider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Sign out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Vehicle v;
  const _DashboardBody({required this.v});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroCard(v: v),
        const SizedBox(height: 16),
        if (v.isEV) ...[
          const SectionHeader('Battery & Charging'),
          BatterySection(v: v),
          const SizedBox(height: 16),
        ],
        if (v.isICE && !v.isEV) ...[
          const SectionHeader('Fuel'),
          FuelSection(v: v),
          const SizedBox(height: 16),
        ],
        const SectionHeader('Doors & Security'),
        DoorsSection(v: v),
        const SizedBox(height: 16),
        const SectionHeader('Windows'),
        WindowsSection(v: v),
        const SizedBox(height: 16),
        const SectionHeader('Climate'),
        ClimateSection(v: v),
        const SizedBox(height: 16),
        const SectionHeader('Tyres'),
        TyreSection(v: v),
        const SizedBox(height: 16),
        const SectionHeader('Warnings'),
        WarningsSection(v: v),
        const SizedBox(height: 16),
        const SectionHeader('Vehicle Info'),
        InfoSection(v: v),
        if (v.extras.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader('Additional Data'),
          ExtrasSection(extras: v.extras),
        ],
        const SizedBox(height: 8),
        if (v.lastUpdated != null)
          Center(
            child: Text(
              'Last updated ${_timeAgo(v.lastUpdated!)}',
              style: const TextStyle(
                color: HyundaiColors.midGrey,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM HH:mm').format(dt);
  }
}
