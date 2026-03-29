/// LogLocationSection — self-contained location entry with geocoding.
///
// Time-stamp: <Friday 2026-03-28 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/pages/log_entry_widgets.dart';

/// Holds lat/lon/address values read from [LogLocationSection].

class LocationValues {
  final double? latitude;
  final double? longitude;
  final String? address;

  const LocationValues({
    this.latitude,
    this.longitude,
    this.address,
  });
}

/// Self-contained location section.
///
/// Access via [GlobalKey<LogLocationSectionState>]:
/// ```dart
/// final _locKey = GlobalKey<LogLocationSectionState>();
/// final loc = _locKey.currentState!.currentValues;
/// ```

class LogLocationSection extends StatefulWidget {
  final LogEntry? entry;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LogLocationSection({
    super.key,
    this.entry,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LogLocationSection> createState() => LogLocationSectionState();
}

class LogLocationSectionState extends State<LogLocationSection> {
  late double? _latitude;
  late double? _longitude;
  late String? _address;
  late final TextEditingController _manualAddress;
  bool _geocoding = false;
  String? _geocodeError;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _latitude = e?.latitude ?? widget.initialLatitude;
    _longitude = e?.longitude ?? widget.initialLongitude;
    _address = e?.locationAddress ?? widget.initialAddress;
    _manualAddress = TextEditingController(
      text: (_latitude == null && e?.locationAddress != null)
          ? e!.locationAddress
          : '',
    );
  }

  @override
  void dispose() {
    _manualAddress.dispose();
    super.dispose();
  }

  LocationValues get currentValues => LocationValues(
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
      );

  Future<void> _geocode() async {
    final addr = _manualAddress.text.trim();
    if (addr.isEmpty) return;
    setState(() {
      _geocoding = true;
      _geocodeError = null;
    });
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {'q': addr, 'format': 'json', 'limit': '1'},
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KonaPod/1.0 (konapod@togaware.com)'},
      );
      if (response.statusCode != 200) {
        setState(() {
          _geocodeError =
              'Geocoding request failed (${response.statusCode}).';
          _geocoding = false;
        });
        return;
      }
      final results = jsonDecode(response.body) as List;
      if (results.isEmpty) {
        setState(() {
          _geocodeError =
              'Address not found. Try adding suburb, state or country.';
          _geocoding = false;
        });
        return;
      }
      final place = results.first as Map<String, dynamic>;
      setState(() {
        _latitude = double.tryParse(place['lat'] as String? ?? '');
        _longitude = double.tryParse(place['lon'] as String? ?? '');
        _address = place['display_name'] as String? ?? addr;
        _geocoding = false;
      });
    } catch (e) {
      setState(() {
        _geocodeError = 'Geocoding failed: $e';
        _geocoding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_latitude != null && _longitude != null) {
      return Row(
        children: [
          Expanded(
            child: LogLocationDisplay(
              latitude: _latitude!,
              longitude: _longitude!,
              address: _address,
              cs: cs,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_location_outlined,
              color: cs.onSurfaceVariant,
            ),
            tooltip: 'Clear and enter manually',
            onPressed: () => setState(() {
              _latitude = null;
              _longitude = null;
              _address = null;
              _manualAddress.clear();
            }),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _manualAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Enter address to geocode...',
                  prefixIcon:
                      Icon(Icons.location_on_outlined, size: 18),
                ),
                onSubmitted: (_) => _geocode(),
              ),
            ),
            const Gap(8),
            FilledButton.tonal(
              onPressed: _geocoding ? null : _geocode,
              child: _geocoding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Find'),
            ),
          ],
        ),
        if (_geocodeError != null) ...[
          const Gap(6),
          Text(
            _geocodeError!,
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
