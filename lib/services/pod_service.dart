import 'dart:convert';
import 'dart:developer' as dev;

import 'package:solidpod/solidpod.dart';

import '../constants/app.dart';
import '../utils/pod_utils.dart';

/// Service for reading and writing vehicle status to a Solid Pod.

class PodService {
  /// Saves a vehicle data map to the pod as a timestamped JSON file.
  static Future<bool> saveStatus(Map<String, dynamic> data) async {
    try {
      final filename = makeStatusFilename();
      final path = '$podStatusPath$filename';
      final content = vehicleMapToJson(data);
      await writePod(path, content);
      dev.log('[Pod] Saved status to $path', name: 'PodService');
      return true;
    } catch (e) {
      dev.log('[Pod] Save error: $e', name: 'PodService');
      return false;
    }
  }

  /// Lists all status files on the pod, sorted newest first.
  static Future<List<String>> listStatusFiles() async {
    try {
      // List files in the konapod directory
      final listing = await readPod('$podStatusPath.acl');
      // Parse the turtle listing to extract filenames
      // solidpod returns a resource listing; filter for our status files
      // Since solidpod doesn't expose a direct listDir, we use a workaround:
      // we maintain an index file, or list known files.
      // For now return empty — populate from index file approach below.
      dev.log('[Pod] listStatusFiles placeholder', name: 'PodService');
      return [];
    } catch (e) {
      dev.log('[Pod] List error: $e', name: 'PodService');
      return [];
    }
  }

  /// Loads the latest status file from the pod.
  static Future<Map<String, dynamic>?> loadLatestStatus() async {
    try {
      // Try to read the index file which lists available snapshots
      final indexContent = await readPod('${podStatusPath}index.json');
      if (indexContent.isNotEmpty) {
        final index = jsonDecode(indexContent) as List;
        if (index.isNotEmpty) {
          // Sort by filename (timestamp embedded) desc
          final sorted = List<String>.from(index)
            ..sort((a, b) => b.compareTo(a));
          return loadStatusFile(sorted.first);
        }
      }
    } catch (_) {}

    // Fall back: try to read a file named 'latest.json'
    try {
      final content = await readPod('${podStatusPath}latest.json');
      if (content.isNotEmpty) {
        return vehicleMapFromJson(content);
      }
    } catch (_) {}
    return null;
  }

  /// Loads a specific status file from the pod by filename.
  static Future<Map<String, dynamic>?> loadStatusFile(String filename) async {
    try {
      final path = '$podStatusPath$filename';
      final content = await readPod(path);
      if (content.isNotEmpty) {
        return vehicleMapFromJson(content);
      }
    } catch (e) {
      dev.log('[Pod] Load error: $e', name: 'PodService');
    }
    return null;
  }

  /// Saves status and also updates the index + latest.json.
  static Future<bool> saveStatusWithIndex(Map<String, dynamic> data) async {
    try {
      final filename = makeStatusFilename();
      final path = '$podStatusPath$filename';
      final content = vehicleMapToJson(data);

      // Write the timestamped file
      await writePod(path, content);

      // Write/overwrite latest.json
      await writePod('${podStatusPath}latest.json', content);

      // Update index.json
      String indexContent = '[]';
      try {
        indexContent = await readPod('${podStatusPath}index.json') ?? '[]';
      } catch (_) {}
      final index = List<String>.from(jsonDecode(indexContent) as List? ?? []);
      if (!index.contains(filename)) {
        index.add(filename);
        index.sort((a, b) => b.compareTo(a)); // newest first
      }
      await writePod(
        '${podStatusPath}index.json',
        jsonEncode(index),
      );

      dev.log('[Pod] Saved $filename and updated index', name: 'PodService');
      return true;
    } catch (e) {
      dev.log('[Pod] Save error: $e', name: 'PodService');
      return false;
    }
  }
}
