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

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_provider.dart';
import '../theme/hyundai_theme.dart';

/// Settings screen — Bluelink credentials and app preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscurePin = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailCtrl.text = prefs.getString('bl_username') ?? '';
      _passCtrl.text = prefs.getString('bl_password') ?? '';
      _pinCtrl.text = prefs.getString('bl_pin') ?? '';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bl_username', _emailCtrl.text.trim());
    await prefs.setString('bl_password', _passCtrl.text);
    await prefs.setString('bl_pin', _pinCtrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(
      const Duration(seconds: 2),
      () => mounted ? setState(() => _saved = false) : null,
    );
  }

  Future<void> _clearAndLogout() async {
    await context.read<AppProvider>().logout();
    _emailCtrl.clear();
    _passCtrl.clear();
    _pinCtrl.clear();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Bluelink Credentials'),
          const SizedBox(height: 4),
          Text(
            'Credentials are stored locally on this device. '
            'They are used to fetch live data via the bluelink_fetch.py script.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Bluelink Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Bluelink Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinCtrl,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Bluelink PIN',
              prefixIcon: const Icon(Icons.pin_outlined),
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_saved ? Icons.check : Icons.save_outlined),
                label: Text(_saved ? 'Saved!' : 'Save Credentials'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _saved ? HyundaiColors.success : HyundaiColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _clearAndLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Clear & Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HyundaiColors.error,
                  side: const BorderSide(color: HyundaiColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _SectionTitle('Solid Pod'),
          const SizedBox(height: 4),
          Text(
            'Vehicle snapshots are saved to your Solid Pod under konapod/. '
            'Log in to your pod using the pod login button in the app bar.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('About bluelink_fetch.py'),
          const SizedBox(height: 4),
          Text(
            'This app uses the hyundai_kia_connect_api Python library as a '
            'backend for live Bluelink data.\n\n'
            'Ensure it is installed:\n'
            '  pip install hyundai-kia-connect-api\n\n'
            'Place bluelink_fetch.py in the same directory as the app binary.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
