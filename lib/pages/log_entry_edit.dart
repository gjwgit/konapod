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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/pages/log_charge_section.dart';
import 'package:konapod/pages/log_location_section.dart';
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
  final _chargeKey = GlobalKey<LogChargeSectionState>();
  late DateTime _timestamp;
  late double? _batteryLevel;
  late double? _evRange;
  late double? _batteryRemainKwh;
  late final TextEditingController _batteryLevelCtrl;
  late final TextEditingController _evRangeCtrl;
  late final TextEditingController _batteryRemainCtrl;
  final _locationKey = GlobalKey<LogLocationSectionState>();

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

    // batteryRemainKwh is stored in kJ — display as kWh (÷3600).
    _batteryLevelCtrl = TextEditingController(
      text: _batteryLevel != null
          ? _batteryLevel!.toStringAsFixed(0)
          : '',
    );
    _evRangeCtrl = TextEditingController(
      text: _evRange != null ? _evRange!.toStringAsFixed(0) : '',
    );
    _batteryRemainCtrl = TextEditingController(
      text: _batteryRemainKwh != null
          ? (_batteryRemainKwh! / 3600).toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _odometer.dispose();
    _batteryLevelCtrl.dispose();
    _evRangeCtrl.dispose();
    _batteryRemainCtrl.dispose();
    super.dispose();
  }

  LogEntry _buildEntry() => LogEntry(
        id: widget.entry?.id ?? _uuid.v4(),
        timestamp: _timestamp,
        title: _title.text.trim(),
        note: _note.text.trim(),
        odometerKm: double.tryParse(_odometer.text.trim()),
        batteryLevelPercent:
            double.tryParse(_batteryLevelCtrl.text.trim()),
        evRangeKm: double.tryParse(_evRangeCtrl.text.trim()),
        // batteryRemainKwh stored in kJ — multiply entered kWh by 3600.
        batteryRemainKwh: double.tryParse(_batteryRemainCtrl.text.trim()) != null
            ? double.parse(_batteryRemainCtrl.text.trim()) * 3600
            : null,
        latitude: _locationKey.currentState!.currentValues.latitude,
        longitude: _locationKey.currentState!.currentValues.longitude,
        locationAddress: _locationKey.currentState!.currentValues.address,
        chargeVendor: _chargeKey.currentState!.currentValues.vendor,
        chargeRateKwh: _chargeKey.currentState!.currentValues.rateKwh,
        chargeEnergyKwh: _chargeKey.currentState!.currentValues.energyKwh,
        chargeDurationMinutes: _chargeKey.currentState!.currentValues.durationMinutes,
        chargeCostPerKwh: _chargeKey.currentState!.currentValues.costPerKwh,
        chargeTotalCost: _chargeKey.currentState!.currentValues.totalCost,
      );
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
                    LogSectionLabel('Date & Time', cs),
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
                    LogSectionLabel('Title', cs),
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
                    LogSectionLabel('Odometer (km)', cs),
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
                    // Vehicle readings — pre-filled from Bluelink, editable.
                    LogSectionLabel('Vehicle Readings', cs),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _batteryLevelCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Battery',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: '%',
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: TextField(
                            controller: _batteryRemainCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Remaining',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'kWh',
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: TextField(
                            controller: _evRangeCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'EV Range',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'km',
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Location
                    const Gap(16),
                    LogSectionLabel('Location', cs),
                    const Gap(8),
                    LogLocationSection(
                      key: _locationKey,
                      entry: widget.entry,
                      initialLatitude: widget.vehicle?.latitude,
                      initialLongitude: widget.vehicle?.longitude,
                      initialAddress: widget.vehicle?.locationAddress,
                    ),
                    // Charging session
                    const Gap(16),
                    LogChargeSection(
                      key: _chargeKey,
                      entry: widget.entry,
                    ),
                    const Gap(16),
                    // Note
                    LogSectionLabel('Notes', cs),
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
