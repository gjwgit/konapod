/// LogEntryEdit — dialog to add or edit a log book entry.
///
// Time-stamp: <Friday 2026-03-27 18:00:00 +1100 Graham Williams>
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
import 'package:uuid/uuid.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/pages/log_entry_widgets.dart';

const _uuid = Uuid();

class LogEntryEdit extends StatefulWidget {
  /// Existing entry to edit, or null to create a new one.
  final LogEntry? entry;

  /// Current vehicle — used to pre-populate fields for new entries.
  final Vehicle? vehicle;

  const LogEntryEdit({super.key, this.entry, this.vehicle});

  @override
  State<LogEntryEdit> createState() => _LogEntryEditState();
}

class _LogEntryEditState extends State<LogEntryEdit> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _odometer;
  late DateTime _timestamp;
  late double? _batteryLevel;
  late double? _evRange;
  late double? _batteryRemainKwh;
  late double? _latitude;
  late double? _longitude;
  late String? _locationAddress;
  late final TextEditingController _manualAddress;
  bool _geocoding = false;
  String? _geocodeError;

  bool get _isNew => widget.entry == null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final v = widget.vehicle;

    _timestamp = e?.timestamp ?? DateTime.now();

    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');

    // Pre-populate vehicle readings for new entries.
    final odo = e?.odometerKm ?? v?.odometerKm;
    _odometer = TextEditingController(
      text: odo != null ? odo.toStringAsFixed(1) : '',
    );

    _batteryLevel = e?.batteryLevelPercent ?? v?.batteryLevelPercent;
    _evRange = e?.evRangeKm ?? v?.evRangeKm;
    _batteryRemainKwh = e?.batteryRemainKwh ?? v?.batteryRemainKwh;
    _latitude = e?.latitude ?? v?.latitude;
    _longitude = e?.longitude ?? v?.longitude;
    _locationAddress = e?.locationAddress ?? v?.locationAddress;
    _manualAddress = TextEditingController(
      text: (_latitude == null && e?.locationAddress != null)
          ? e!.locationAddress
          : '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _odometer.dispose();
    _manualAddress.dispose();
    super.dispose();
  }

  LogEntry _buildEntry() => LogEntry(
        id: widget.entry?.id ?? _uuid.v4(),
        timestamp: _timestamp,
        title: _title.text.trim(),
        note: _note.text.trim(),
        odometerKm: double.tryParse(_odometer.text.trim()),
        batteryLevelPercent: _batteryLevel,
        evRangeKm: _evRange,
        batteryRemainKwh: _batteryRemainKwh,
        latitude: _latitude,
        longitude: _longitude,
        locationAddress: _locationAddress,
      );

  Future<void> _geocodeAddress() async {
    final addr = _manualAddress.text.trim();
    if (addr.isEmpty) return;
    setState(() {
      _geocoding = true;
      _geocodeError = null;
    });
    try {
      // Use OpenStreetMap Nominatim — no API key required, works on all
      // platforms including Linux desktop.
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': addr,
          'format': 'json',
          'limit': '1',
        },
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KonaPod/1.0 (konapod@togaware.com)'},
      );
      if (response.statusCode != 200) {
        setState(() {
          _geocodeError = 'Geocoding request failed (${response.statusCode}).';
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
        _locationAddress = place['display_name'] as String? ?? addr;
        _geocoding = false;
      });
    } catch (e) {
      setState(() {
        _geocodeError = 'Geocoding failed: $e';
        _geocoding = false;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null) return;
    setState(() {
      _timestamp = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 60 : 12,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Text(
                    _isNew ? 'New Log Entry' : 'Edit Log Entry',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ── Form ────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & time
                    _SectionLabel('Date & Time', cs),
                    const Gap(8),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: Icon(Icons.schedule_outlined, size: 18),
                        ),
                        child: Text(_fmtDateTime(_timestamp)),
                      ),
                    ),
                    const Gap(16),
                    // Title
                    _SectionLabel('Title', cs),
                    const Gap(8),
                    TextField(
                      controller: _title,
                      autofocus: _isNew,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'e.g. Charged at shopping centre',
                      ),
                    ),
                    const Gap(16),
                    // Odometer
                    _SectionLabel('Odometer (km)', cs),
                    const Gap(8),
                    TextField(
                      controller: _odometer,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: 'km',
                      ),
                    ),
                    const Gap(16),
                    // Vehicle readings (read-only display, editable via
                    // the odometer field above; others come from Bluelink)
                    _SectionLabel('Vehicle Readings', cs),
                    const Gap(8),
                    LogReadingsRow(
                      batteryLevel: _batteryLevel,
                      evRange: _evRange,
                      batteryRemainKwh: _batteryRemainKwh,
                      cs: cs,
                    ),
                    // Location
                    const Gap(16),
                    _SectionLabel('Location', cs),
                    const Gap(8),
                    if (_latitude != null && _longitude != null)
                      Row(
                        children: [
                          Expanded(
                            child: LogLocationDisplay(
                              latitude: _latitude!,
                              longitude: _longitude!,
                              address: _locationAddress,
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
                              _locationAddress = null;
                              _manualAddress.clear();
                            }),
                          ),
                        ],
                      )
                    else ...[
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
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                ),
                              ),
                              onSubmitted: (_) => _geocodeAddress(),
                            ),
                          ),
                          const Gap(8),
                          FilledButton.tonal(
                            onPressed: _geocoding ? null : _geocodeAddress,
                            child: _geocoding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Find'),
                          ),
                        ],
                      ),
                      if (_geocodeError != null) ...[
                        const Gap(6),
                        Text(
                          _geocodeError!,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                    const Gap(16),
                    // Note
                    _SectionLabel('Notes', cs),
                    const Gap(8),
                    TextField(
                      controller: _note,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Details, observations, reminders...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const Gap(8),
                  ],
                ),
              ),
            ),
            // ── Actions ─────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_title.text.trim().isEmpty) return;
                      Navigator.of(context).pop(_buildEntry());
                    },
                    child: Text(_isNew ? 'Add Entry' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _SectionLabel(this.text, this.cs);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      );
}
