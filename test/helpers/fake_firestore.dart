// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight in-memory fake for [FirebaseFirestore] used in unit tests.
///
/// Only supports the subset of the Firestore API used by [SyncedStorageDatasource]:
/// - collection / doc / collection (subcollection) chaining
/// - set, get, delete on DocumentReference
/// - get on CollectionReference (returns all documents)
class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> _collections = {};

  Map<String, FakeCollectionReference> get collections => _collections;

  @override
  FakeCollectionReference collection(String path) {
    return _collections.putIfAbsent(path, () => FakeCollectionReference(path));
  }

  // ── Not implemented ──────────────────────────────────────────

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'FakeFirebaseFirestore: ${invocation.memberName}');
}

class FakeCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(this._path);

  final String _path;
  final Map<String, FakeDocumentReference> _docs = {};

  @override
  FakeDocumentReference doc([String? path]) {
    final id = path ?? 'auto_${_docs.length}';
    return _docs.putIfAbsent(id, () => FakeDocumentReference('$_path/$id'));
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final snapshots = <FakeDocumentSnapshot>[];
    for (final entry in _docs.entries) {
      if (entry.value._data != null) {
        snapshots.add(FakeDocumentSnapshot(
          entry.key,
          Map<String, dynamic>.from(entry.value._data!),
        ));
      }
    }
    return FakeQuerySnapshot(snapshots);
  }

  // ── Not implemented ──────────────────────────────────────────

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'FakeCollectionReference: ${invocation.memberName}');
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  FakeDocumentReference(this._path);

  final String _path;
  Map<String, dynamic>? _data;
  final Map<String, FakeCollectionReference> _subCollections = {};

  @override
  FakeCollectionReference collection(String path) {
    return _subCollections.putIfAbsent(
        path, () => FakeCollectionReference('$_path/$path'));
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _data = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> delete() async {
    _data = null;
  }

  @override
  Future<FakeDocumentSnapshot> get([GetOptions? options]) async {
    if (_data == null) {
      return FakeDocumentSnapshot(id, null);
    }
    return FakeDocumentSnapshot(id, Map<String, dynamic>.from(_data!));
  }

  @override
  String get id => _path.split('/').last;

  @override
  String get path => _path;

  // ── Not implemented ──────────────────────────────────────────

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'FakeDocumentReference: ${invocation.memberName}');
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot(this._id, this._data);

  final String _id;
  final Map<String, dynamic>? _data;

  @override
  String get id => _id;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  // ── Not implemented ──────────────────────────────────────────

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'FakeDocumentSnapshot: ${invocation.memberName}');
}

class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  FakeQuerySnapshot(this._docs);

  final List<FakeDocumentSnapshot> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      _docs.map((d) => FakeQueryDocumentSnapshot(d.id, d.data()!)).toList();

  @override
  int get size => _docs.length;

  // ── Not implemented ──────────────────────────────────────────

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeQuerySnapshot: ${invocation.memberName}');
}

class FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  FakeQueryDocumentSnapshot(this._id, this._data);

  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;

  // ── Not implemented ──────────────────────────────────────────

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'FakeQueryDocumentSnapshot: ${invocation.memberName}');
}
