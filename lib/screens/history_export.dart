/// History import/export helpers for KonaPod.
///
// Time-stamp: <Thursday 2026-04-23 10:00:00 +1100 Graham Williams>
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
// this program.  If not, see <https://opensource.org/licenses/GPL-3.0>.
///
/// Authors: Claude, Graham Williams

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

import 'package:konapod/services/pod_service.dart';

class HistoryExport {
  HistoryExport._();

  // ── JSON export ──────────────────────────────────────────────────────────

  /// Loads all snapshots from the Pod and saves them as a single JSON bundle.

  static Future<void> exportJson(
    BuildContext context,
    List<String> files,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Load each snapshot's data from the Pod.
      final snapshots = <Map<String, dynamic>>[];
      for (final f in files) {
        final data = await PodService.loadStatusFile(f);
        if (data != null) {
          snapshots.add({'filename': f, 'data': data});
        }
      }
      final bundle = {
        'exported_at': DateTime.now().toIso8601String(),
        'count': snapshots.length,
        'snapshots': snapshots,
      };
      final json = const JsonEncoder.withIndent('  ').convert(bundle);
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'konapod_history_$stamp.json';

      if (kIsWeb) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('JSON export not supported on web.'),
          ),
        );
        return;
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save History as JSON',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsString(json);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved ${snapshots.length} snapshots to $savePath'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  // ── JSON import ──────────────────────────────────────────────────────────

  /// Reads a history JSON bundle and restores each snapshot to the Pod,
  /// preserving the original filenames and skipping any that already exist.

  static Future<void> importJson(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select History JSON file',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
        return;
      }
      final bundle = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final snapshots =
          (bundle['snapshots'] as List).cast<Map<String, dynamic>>();
      int restored = 0;
      int skipped = 0;
      for (final s in snapshots) {
        final filename = s['filename'] as String;
        final data = s['data'] as Map<String, dynamic>;
        final error = await PodService.restoreSnapshot(filename, data);
        if (error == null) {
          restored++;
        } else {
          skipped++;
        }
      }
      if (!context.mounted) return;
      final msg = skipped == 0
          ? 'Restored $restored snapshot${restored == 1 ? '' : 's'} to Pod.'
          : 'Restored $restored, skipped $skipped (already exist).';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  // ── PDF export ───────────────────────────────────────────────────────────

  /// Generates a PDF listing all snapshot timestamps.

  static Future<void> exportPdf(
    BuildContext context,
    List<String> files,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd MMMM yyyy').format(now);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => [
            pw.Text(
              'KonaPod - Vehicle Status History',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated $dateStr  |  ${files.length} snapshots',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            ...files.map(
              (f) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '- ',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _formatTitle(f),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            f,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

      final stamp = DateFormat('yyyyMMdd_HHmm').format(now);
      final fileName = 'konapod_history_$stamp.pdf';
      final pdfBytes = await doc.save();

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: fileName,
        );
        if (!context.mounted) return;
        return;
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save History as PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(pdfBytes);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Saved to $savePath')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _formatTitle(String filename) {
    final match = RegExp(
      r'(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})',
    ).firstMatch(filename);
    if (match == null) return filename;
    final dt = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    return '${DateFormat('EEEE d MMMM yyyy').format(dt)}'
        ' at ${DateFormat('HH:mm:ss').format(dt)}';
  }
}
