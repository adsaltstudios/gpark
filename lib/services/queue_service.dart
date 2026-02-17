import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/submission.dart';
import '../utils/constants.dart';

class QueueService {
  static const _queueKey = 'gpark_queue';

  /// Load all queue entries from local storage.
  Future<List<QueueEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get only pending (queued) entries that are ready for retry.
  Future<List<QueueEntry>> getPending() async {
    final all = await getAll();
    final now = DateTime.now();
    return all.where((entry) {
      if (entry.status != QueueStatus.queued) return false;
      if (entry.retryCount >= Constants.maxRetries) return false;
      if (entry.lastRetryAt == null) return true;
      final backoff = Constants.retryBackoffs[
          entry.retryCount.clamp(0, Constants.retryBackoffs.length - 1)];
      return now.isAfter(entry.lastRetryAt!.add(backoff));
    }).toList();
  }

  /// Add a submission to the offline queue.
  Future<void> enqueue(Submission submission) async {
    final entries = await getAll();
    if (entries.length >= Constants.maxQueueSize) {
      // Remove oldest submitted/failed entry to make room.
      final removable = entries.where(
        (e) => e.status == QueueStatus.submitted || e.status == QueueStatus.failed,
      );
      if (removable.isNotEmpty) {
        entries.remove(removable.first);
      } else {
        throw QueueFullException();
      }
    }
    entries.add(QueueEntry(payload: submission));
    await _save(entries);
  }

  /// Mark an entry as successfully submitted.
  Future<void> markSubmitted(String id) async {
    final entries = await getAll();
    final entry = entries.firstWhere((e) => e.id == id);
    entry.status = QueueStatus.submitted;
    await _save(entries);
  }

  /// Mark an entry as failed and increment retry count.
  Future<void> markFailed(String id) async {
    final entries = await getAll();
    final entry = entries.firstWhere((e) => e.id == id);
    entry.retryCount++;
    entry.lastRetryAt = DateTime.now();
    if (entry.retryCount >= Constants.maxRetries) {
      entry.status = QueueStatus.failed;
    }
    await _save(entries);
  }

  /// Remove a specific entry by ID.
  Future<void> remove(String id) async {
    final entries = await getAll();
    entries.removeWhere((e) => e.id == id);
    await _save(entries);
  }

  /// Clear all entries.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Get count of items waiting to sync.
  Future<int> queuedCount() async {
    final all = await getAll();
    return all.where((e) => e.status == QueueStatus.queued).length;
  }

  Future<void> _save(List<QueueEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_queueKey, json);
  }
}

class QueueFullException implements Exception {
  @override
  String toString() =>
      'Queue is full. Please use the Google Form to submit your validation.';
}
