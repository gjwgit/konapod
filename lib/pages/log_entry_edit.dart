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
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/pages/log_charge_section.dart';
import 'package:konapod/pages/log_entry_widgets.dart';
import 'package:konapod/pages/log_location_section.dart';
import 'package:konapod/services/app_provider.dart';
import 'package:konapod/widgets/emacs_text_field.dart';

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
  late final TextEditingController _startOdometer;
  late final TextEditingController _odometer;
  late final TextEditingController _startBatteryLevelCtrl;
  late final TextEditingController _startEvRangeCtrl;
  late final TextEditingController _startBatteryRemainCtrl;
  final _chargeKey = GlobalKey<LogChargeSectionState>();
  late DateTime _timestamp;
  late final TextEditingController _batteryLevelCtrl;
  late final TextEditingController _evRangeCtrl;
  late final TextEditingController _batteryRemainCtrl;
  final _locationKey = GlobalKey<LogLocationSectionState>();
  bool _fetchingEnd = false;

  bool get _isNew => widget.entry == null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final v = widget.vehicle;

    _timestamp = e?.timestamp ?? DateTime.now();

    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');

    // ── Start readings ────────────────────────────────────────────────────────
    // For new entries: pre-fill from current vehicle state.
    // For existing entries: use only what was saved — if the user cleared a
    // field it must stay empty (never fall back to the live vehicle value).
    final isNew = e == null;
    final startOdo = e?.startOdometerKm ?? (isNew ? v?.odometerKm : null);
    _startOdometer = TextEditingController(
      text: startOdo != null ? startOdo.round().toString() : '',
    );
    final startBatt =
        e?.startBatteryLevelPercent ?? (isNew ? v?.batteryLevelPercent : null);
    _startBatteryLevelCtrl = TextEditingController(
      text: startBatt != null ? startBatt.toStringAsFixed(0) : '',
    );
    final startRange = e?.startEvRangeKm ?? (isNew ? v?.evRangeKm : null);
    _startEvRangeCtrl = TextEditingController(
      text: startRange != null ? startRange.toStringAsFixed(0) : '',
    );
    final startRemain =
        e?.startBatteryRemainKwh ?? (isNew ? v?.batteryRemainKwh : null);
    _startBatteryRemainCtrl = TextEditingController(
      text: startRemain != null ? (startRemain / 3600).toStringAsFixed(1) : '',
    );

    // ── End readings — blank for new entries, populated when editing ─────────
    final odo = e?.odometerKm;
    _odometer = TextEditingController(
      text: odo != null ? odo.round().toString() : '',
    );
    final batt = e?.batteryLevelPercent;
    _batteryLevelCtrl = TextEditingController(
      text: batt != null ? batt.toStringAsFixed(0) : '',
    );
    final range = e?.evRangeKm;
    _evRangeCtrl = TextEditingController(
      text: range != null ? range.toStringAsFixed(0) : '',
    );
    final remain = e?.batteryRemainKwh;
    _batteryRemainCtrl = TextEditingController(
      text: remain != null ? (remain / 3600).toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _startOdometer.dispose();
    _odometer.dispose();
    _startBatteryLevelCtrl.dispose();
    _startEvRangeCtrl.dispose();
    _startBatteryRemainCtrl.dispose();
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
        startOdometerKm: double.tryParse(_startOdometer.text.trim()),
        odometerKm: double.tryParse(_odometer.text.trim()),
        startBatteryLevelPercent:
            double.tryParse(_startBatteryLevelCtrl.text.trim()),
        startEvRangeKm: double.tryParse(_startEvRangeCtrl.text.trim()),
        startBatteryRemainKwh:
            double.tryParse(_startBatteryRemainCtrl.text.trim()) != null
                ? double.parse(_startBatteryRemainCtrl.text.trim()) * 3600
                : null,
        batteryLevelPercent: double.tryParse(_batteryLevelCtrl.text.trim()),
        evRangeKm: double.tryParse(_evRangeCtrl.text.trim()),
        batteryRemainKwh:
            double.tryParse(_batteryRemainCtrl.text.trim()) != null
                ? double.parse(_batteryRemainCtrl.text.trim()) * 3600
                : null,
        latitude: _locationKey.currentState!.currentValues.latitude,
        longitude: _locationKey.currentState!.currentValues.longitude,
        locationAddress: _locationKey.currentState!.currentValues.address,
        chargeVendor: _chargeKey.currentState!.currentValues.vendor,
        chargeRateKwh: _chargeKey.currentState!.currentValues.rateKwh,
        chargeEnergyKwh: _chargeKey.currentState!.currentValues.energyKwh,
        chargeDurationMinutes:
            _chargeKey.currentState!.currentValues.durationMinutes,
        chargeCostPerKwh: _chargeKey.currentState!.currentValues.costPerKwh,
        chargeTotalCost: _chargeKey.currentState!.currentValues.totalCost,
      );

  /// Refresh from Bluelink and populate end readings with current vehicle state.
  Future<void> _fetchEndReadings() async {
    setState(() => _fetchingEnd = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.refresh();
      if (!mounted) return;
      final v = provider.selectedVehicle;
      if (v == null) return;
      _odometer.text =
          v.odometerKm != null ? v.odometerKm!.round().toString() : '';
      final endBatt = v.batteryLevelPercent;
      _batteryLevelCtrl.text =
          endBatt != null ? endBatt.toStringAsFixed(0) : '';
      _batteryRemainCtrl.text = v.batteryRemainKwh != null
          ? (v.batteryRemainKwh! / 3600).toStringAsFixed(1)
          : '';
      _evRangeCtrl.text =
          v.evRangeKm != null ? v.evRangeKm!.toStringAsFixed(0) : '';

      // ── Derived charge values ──────────────────────────────────────────────

      // Duration: from entry timestamp to now.
      final now = DateTime.now();
      final durationMin = now.difference(_timestamp).inMinutes.clamp(0, 9999);

      // Energy delivered: end remaining kWh − start remaining kWh.
      // Use the directly measured remaining values — more accurate than
      // deriving from battery percentage × capacity.
      final startRemain = double.tryParse(_startBatteryRemainCtrl.text.trim());
      final endRemain =
          v.batteryRemainKwh != null ? v.batteryRemainKwh! / 3600 : null;
      double? energyKwh;
      double? totalCost;
      if (endRemain != null && startRemain != null) {
        final delta = endRemain - startRemain;
        if (delta > 0) {
          energyKwh = delta;

          // Total cost: energy × cost per kWh if available.
          final costPerKwh = _chargeKey.currentState?.costPerKwh;
          if (costPerKwh != null && costPerKwh > 0) {
            totalCost = energyKwh * costPerKwh;
          }
        }
      }

      _chargeKey.currentState?.populateFromBluelink(
        durationMinutes: durationMin,
        energyKwh: energyKwh,
        totalCost: totalCost,
      );
    } finally {
      if (mounted) setState(() => _fetchingEnd = false);
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
                    // Location
                    LogSectionLabel('Location', cs),
                    const Gap(8),
                    LogLocationSection(
                      key: _locationKey,
                      entry: widget.entry,
                      initialLatitude: widget.vehicle?.latitude,
                      initialLongitude: widget.vehicle?.longitude,
                      initialAddress: widget.vehicle?.locationAddress,
                    ),
                    const Gap(16),
                    const Gap(16),
                    // ── Start readings ───────────────────────────────────
                    LogSectionLabel('Start Readings', cs),
                    const Gap(8),
                    LogReadingsGrid(
                      odoCtrl: _startOdometer,
                      battCtrl: _startBatteryLevelCtrl,
                      remainCtrl: _startBatteryRemainCtrl,
                      rangeCtrl: _startEvRangeCtrl,
                    ),
                    // Charging session + end readings
                    const Gap(16),
                    LogChargeSection(
                      key: _chargeKey,
                      entry: widget.entry,
                      endReadingsContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(12),
                          Row(
                            children: [
                              LogSectionLabel('End Readings', cs),
                              const Spacer(),
                              // Fetch from Bluelink button
                              if (context.watch<AppProvider>().isAuthenticated)
                                TextButton.icon(
                                  icon: _fetchingEnd
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.cloud_download_outlined,
                                          size: 16,
                                        ),
                                  label: const Text('From Bluelink'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed:
                                      _fetchingEnd ? null : _fetchEndReadings,
                                ),
                            ],
                          ),
                          const Gap(8),
                          LogReadingsGrid(
                            odoCtrl: _odometer,
                            battCtrl: _batteryLevelCtrl,
                            remainCtrl: _batteryRemainCtrl,
                            rangeCtrl: _evRangeCtrl,
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    // Note
                    LogSectionLabel('Notes', cs),
                    const Gap(8),
                    EmacsTextField(
                      controller: _note,
                      minLines: 3,
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
