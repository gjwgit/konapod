/// Logbook import/export helpers for KonaPod.
///
// Time-stamp: <Wednesday 2026-04-22 08:46:35 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/services/app_provider.dart';

class LogbookExport {
  LogbookExport._();

  // ── JSON export ──────────────────────────────────────────────────────────

  static Future<void> exportJson(
    BuildContext context,
    List<LogEntry> entries,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = jsonEncode(entries.map((e) => e.toJson()).toList());
      final now = DateTime.now();
      final stamp = DateFormat('yyyyMMdd_HHmm').format(now);
      final fileName = 'konapod_logbook_$stamp.json';

      if (kIsWeb) {
        messenger.showSnackBar(
          const SnackBar(content: Text('JSON export not supported on web.')),
        );
        return;
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save Log Book as JSON',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(utf8.encode(json));
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Saved to $savePath')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  // ── JSON import ──────────────────────────────────────────────────────────

  static Future<void> importJson(
    BuildContext context,
    AppProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select Log Book JSON file',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
        return;
      }

      final List<dynamic> raw = jsonDecode(utf8.decode(bytes));
      final imported =
          raw.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList();

      var added = 0;
      for (final e in imported) {
        if (!provider.logEntries.any((x) => x.id == e.id)) {
          provider.addLogEntry(e);
          added++;
        }
      }
      await provider.saveLogToPod();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'No new entries — all already exist.'
                : 'Imported $added new entr${added == 1 ? 'y' : 'ies'}.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  // ── PDF export ───────────────────────────────────────────────────────────

  static Future<void> exportPdf(
    BuildContext context,
    List<LogEntry> entries,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd MMMM yyyy').format(now);
      final countStr = '${entries.length} entries';

      // Helper: strip markdown syntax for plain-text PDF paragraphs
      // then render each line, bolding lines that start with **.
      List<pw.Widget> noteWidgets(String note) {
        if (note.isEmpty) return [];
        return note.split('\n').where((l) => l.isNotEmpty).map((line) {
          final trimmed = line.trim();
          final isBullet = trimmed.startsWith('+ ') || trimmed == '+';
          final isBold = trimmed.startsWith('**') && trimmed.endsWith('**') ||
              trimmed.startsWith('## ') ||
              trimmed.startsWith('# ');
          var text = trimmed
              .replaceAll(RegExp(r'^\*\*|\*\*$'), '')
              .replaceAll(RegExp(r'^#{1,3} '), '');
          if (isBullet) text = "- ${text.replaceFirst(RegExp(r"^\+ ?"), "")}";
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.grey700,
              ),
            ),
          );
        }).toList();
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Kona Pod - Log Book',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated $dateStr  ($countStr)',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (_) => entries.map((e) {
            final ts = DateFormat('EEE d MMM yyyy HH:mm').format(e.timestamp);

            // Heading: timestamp | title | odo | +% | +range | elapsed
            final rangeAdded = (e.startEvRangeKm != null && e.evRangeKm != null)
                ? '+${(e.evRangeKm! - e.startEvRangeKm!).toStringAsFixed(0)} km'
                : '';
            final elapsed = e.chargeDurationMinutes != null
                ? _fmtDuration(e.chargeDurationMinutes!)
                : '';

            // Battery delta for headline.
            final startBatt = e.startBatteryLevelPercent;
            final endBatt = e.batteryLevelPercent;
            final battDelta = (startBatt != null && endBatt != null)
                ? '+${(endBatt - startBatt).toStringAsFixed(0)} %'
                : '';

            final heading = [
              ts,
              if (e.title.isNotEmpty) e.title,
              if (e.odometerKm != null)
                '${e.odometerKm!.toStringAsFixed(0)} km',
              if (rangeAdded.isNotEmpty) rangeAdded,
              if (battDelta.isNotEmpty) battDelta,
              if (elapsed.isNotEmpty) elapsed,
            ].join('  |  ');

            // Start/end readings: battery % and range (no odo).
            final startRange = e.startEvRangeKm;
            final endRange = e.evRangeKm;
            final startParts = [
              if (startBatt != null) '${startBatt.toStringAsFixed(0)} %',
              if (startRange != null) '${startRange.toStringAsFixed(0)} km',
            ].join('  ');
            final endParts = [
              if (endBatt != null) '${endBatt.toStringAsFixed(0)} %',
              if (endRange != null) '${endRange.toStringAsFixed(0)} km',
            ].join('  ');
            final readingParts = [
              if (startParts.isNotEmpty) 'Start: $startParts',
              if (endParts.isNotEmpty) 'End: $endParts',
            ].join('    ');

            // Charge details line: Tesla | 58.0 kW | 25.7 kWh x 0.51/kWh = $13.10
            final chargeEnergy = e.chargeEnergyKwh != null
                ? '${e.chargeEnergyKwh!.toStringAsFixed(1)} kWh'
                : '';
            final chargeCost = (e.chargeEnergyKwh != null &&
                    e.chargeCostPerKwh != null)
                ? '${e.chargeEnergyKwh!.toStringAsFixed(1)} kWh'
                    ' x ${e.chargeCostPerKwh!.toStringAsFixed(2)}/kWh'
                    '${e.chargeTotalCost != null ? " = \$${e.chargeTotalCost!.toStringAsFixed(2)}" : ""}'
                : chargeEnergy;
            final vendorRate = [
              if (e.chargeVendor != null && e.chargeVendor!.isNotEmpty)
                e.chargeVendor!,
              if (e.chargeRateKwh != null)
                '${e.chargeRateKwh!.toStringAsFixed(1)}kW',
            ].join(' @ ');
            final chargeParts = [
              if (vendorRate.isNotEmpty) vendorRate,
              if (chargeCost.isNotEmpty) chargeCost,
            ].join('  |  ');

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  heading,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (readingParts.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      readingParts,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                if (chargeParts.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      chargeParts,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                if (e.locationAddress != null && e.locationAddress!.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      e.locationAddress!,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  )
                else if (e.latitude != null && e.longitude != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      '${e.latitude!.toStringAsFixed(5)}, '
                      '${e.longitude!.toStringAsFixed(5)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ...noteWidgets(e.note).map(
                  (w) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8),
                    child: w,
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
            );
          }).toList(),
        ),
      );

      final stamp = DateFormat('yyyyMMdd_HHmm').format(now);
      final fileName = 'konapod_logbook_$stamp.pdf';
      final pdfBytes = await doc.save();

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: fileName,
        );
        return;
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save Log Book as PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(pdfBytes);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Saved to $savePath')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  static String _fmtDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
