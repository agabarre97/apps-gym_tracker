import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/sync_port.dart';

/// [StoragePort] + [SyncPort] implementation that writes locally first (fast)
/// and synchronises with Cloud Firestore in the background (fire-and-forget).
///
/// Until [setUserId] is called, all operations are local-only.
class SyncedStorageDatasource implements StoragePort, SyncPort {
  SyncedStorageDatasource({
    required StoragePort local,
    required FirebaseFirestore firestore,
  })  : _local = local,
        _firestore = firestore;

  final StoragePort _local;
  final FirebaseFirestore _firestore;

  String? _userId;

  @override
  void setUserId(String? uid) => _userId = uid;

  /// Firestore document reference for a given key under the current user.
  DocumentReference? _docRef(String key) {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('storage')
        .doc(key);
  }

  // ── StoragePort implementation ────────────────────────────────

  @override
  Future<String?> get(String key) => _local.get(key);

  @override
  Future<void> set(String key, String value) async {
    await _local.set(key, value);
    _syncSet(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _local.remove(key);
    _syncRemove(key);
  }

  // ── Background sync helpers ───────────────────────────────────

  void _syncSet(String key, String value) {
    final ref = _docRef(key);
    if (ref == null) return;
    ref.set({'value': value}).catchError((Object e) {
      dev.log('Firestore sync set failed for "$key": $e');
    });
  }

  void _syncRemove(String key) {
    final ref = _docRef(key);
    if (ref == null) return;
    ref.delete().catchError((Object e) {
      dev.log('Firestore sync delete failed for "$key": $e');
    });
  }

  @override
  Future<void> pullFromCloud({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_userId == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('storage')
          .get()
          .timeout(timeout);
      for (final doc in snapshot.docs) {
        final value = doc.data()['value'];
        if (value is String) {
          await _local.set(doc.id, value);
        }
      }
      dev.log('pullFromCloud: synced ${snapshot.docs.length} keys');
    } catch (e) {
      dev.log('Firestore pullFromCloud failed (continuing offline): $e');
    }
  }

  @override
  Future<void> pushToCloud(List<String> keys) async {
    if (_userId == null) return;
    for (final key in keys) {
      final value = await _local.get(key);
      if (value != null) {
        _syncSet(key, value);
      }
    }
  }
}
