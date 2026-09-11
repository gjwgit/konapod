/// LogEntryEdit — dialog to add or edit a log book entry.
///
// Time-stamp: <Tuesday 2026-05-05 15:19:57 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import 'package:emacs_text_field/emacs_text_field.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'package:uuid/uuid.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/pages/log_charge_section.dart';
import 'package:konapod/pages/log_end_readings_section.dart';
import 'package:konapod/pages/log_entry_widgets.dart';
import 'package:konapod/pages/log_location_section.dart';
import 'package:konapod/pages/log_timestamp_field.dart';
import 'package:konapod/services/app_provider.dart';

const _uuid = Uuid();

class LogEntryEdit extends StatefulWidget {
  /// Existing entry to edit, or null to create a new one.
  final LogEntry? entry;

  /// Current vehicle — used to pre-populate fields for new entries.
  final Vehicle? vehicle;

  /// Called with the entry when the user saves. The caller updates the
  /// provider and writes to the Pod.
  ///
  /// Returns a future that completes when the Pod write is done. It MUST be
  /// awaited by the caller's implementation: closing the app window waits on
  /// this before quitting, so a fire-and-forget write would be killed
  /// mid-flight and the entry silently lost. And it must let a failure throw
  /// rather than swallow it, or the editor marks a lost entry as saved.
  final Future<void> Function(LogEntry)? onSave;

  const LogEntryEdit({super.key, this.entry, this.vehicle, this.onSave});

  @override
  State<LogEntryEdit> createState() => _LogEntryEditState();
}

class _LogEntryEditState extends State<LogEntryEdit> with UnsavedChangesMixin {
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
  // 20260724 gjw Validation message shown under the Title field.
  String? _titleError;
  bool _saving = false;
  // The entry id is fixed for the life of the editor so that a re-save of an
  // entry added from this dialog updates it rather than adding a duplicate,
  // and so [_hasChanges] is not fooled by a fresh uuid on every comparison.
  late final String _entryId;
  // The entry as last saved, used by [_hasChanges]. Taken after the first
  // frame, once the charge and location sections exist to be read.
  Map<String, dynamic>? _saved;

  bool get _isNew => widget.entry == null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final v = widget.vehicle;

    _entryId = e?.id ?? _uuid.v4();
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

    // The charge and location sections are separate States reached through
    // their GlobalKeys, so the baseline can only be read once they are built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapshotSavedState());
  }

  /// Record the current field values as the last-saved baseline.

  void _snapshotSavedState() {
    if (mounted) _saved = _buildEntry().toJson();
  }

  /// Whether the user has edits that saving would keep and quitting would
  /// lose. Compares what Save would write against the last-saved baseline,
  /// so it covers the charge and location sections too.

  bool get _hasChanges {
    final saved = _saved;
    // Before the first frame there is nothing the user can have typed.
    if (saved == null) return false;
    return !mapEquals(saved, _buildEntry().toJson());
  }

  // The window-close prompt comes from UnsavedChangesMixin, which needs to
  // know what counts as unsaved and how to save it.

  @override
  bool get hasUnsavedChanges => _hasChanges;

  @override
  bool get canSaveUnsavedChanges => _title.text.trim().isNotEmpty;

  /// Only `true` once the entry is actually on the Pod. The window is
  /// destroyed the moment this returns `true`, so a failed write has to keep
  /// the editor open with the entry intact instead.

  @override
  Future<bool> saveUnsavedChanges() => _save();

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
        id: _entryId,
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

  /// Hand the entry to [LogEntryEdit.onSave] and report whether it was saved.
  ///
  /// Never pops: on the window-close path the whole window is going away, not
  /// just this route. The Save button pops for itself once this succeeds.

  Future<bool> _save() async {
    // 20260724 gjw Explain that a title is required rather than silently
    // doing nothing.
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = 'A TITLE is required to add an entry.');
      return false;
    }
    setState(() => _saving = true);
    try {
      // Awaited so a window close waits for the Pod write to complete.
      await widget.onSave?.call(_buildEntry());
      // Snapshot only once the write has actually landed. Marking the entry
      // saved after a failed write would silence the window-close prompt and
      // lose the very entry the user asked to keep.
      _snapshotSavedState();
      return true;
    } catch (e) {
      SolidWriteFailures.report('Failed saving the log entry.\n\n$e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Save and, once the write has landed, close the dialog.

  Future<void> _saveAndClose() async {
    if (!await _save()) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

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

      // Duration: from entry timestamp to the charge end time. The API has no
      // charge-session history, but the car reports state to the server when
      // charging stops, so when not charging the snapshot's lastUpdated is
      // typically the charge-stop time — more accurate than now. Fall back to
      // now while still charging or if lastUpdated is missing/stale. 20260726 gjw
      final now = DateTime.now();
      var end = now;
      final reported = v.lastUpdated;
      if (v.isChargingOn != true &&
          reported != null &&
          reported.isAfter(_timestamp) &&
          reported.isBefore(now)) {
        end = reported;
      }
      final durationMin = end.difference(_timestamp).inMinutes.clamp(0, 9999);

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
                      onChanged: (_) {
                        // 20260724 gjw Clear the error once the user types.
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        hintText: 'e.g. Charged at shopping centre',
                        errorText: _titleError,
                      ),
                    ),
                    const Gap(16),
                    // Date & time
                    LogTimestampField(
                      cs: cs,
                      timestamp: _timestamp,
                      onTap: _pickDateTime,
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
                      startTimestamp: _timestamp,
                      startRemainCtrl: _startBatteryRemainCtrl,
                      endRemainCtrl: _batteryRemainCtrl,
                      endReadingsContent: LogEndReadingsSection(
                        cs: cs,
                        fetching: _fetchingEnd,
                        onFetch: context.watch<AppProvider>().isAuthenticated
                            ? _fetchEndReadings
                            : null,
                        odoCtrl: _odometer,
                        battCtrl: _batteryLevelCtrl,
                        remainCtrl: _batteryRemainCtrl,
                        rangeCtrl: _evRangeCtrl,
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
                    onPressed: _saving ? null : _saveAndClose,
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
}
