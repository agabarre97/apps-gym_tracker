import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/synced_storage_datasource.dart';

import '../../helpers/fake_firestore.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('SyncedStorageDatasource', () {
    late FakeStoragePort localStorage;
    late FakeFirebaseFirestore fakeFirestore;
    late SyncedStorageDatasource synced;

    setUp(() {
      localStorage = FakeStoragePort();
      fakeFirestore = FakeFirebaseFirestore();
      synced = SyncedStorageDatasource(
        local: localStorage,
        firestore: fakeFirestore,
      );
    });

    test('get reads from local storage', () async {
      await localStorage.set('key1', 'value1');
      expect(await synced.get('key1'), 'value1');
    });

    test('set writes to local storage immediately', () async {
      await synced.set('key1', 'value1');
      expect(await localStorage.get('key1'), 'value1');
    });

    test('set syncs to Firestore when userId is set', () async {
      synced.setUserId('user123');
      await synced.set('key1', 'value1');

      // Wait for fire-and-forget to complete
      await Future.delayed(Duration.zero);

      final doc = fakeFirestore
          .collection('users')
          .doc('user123')
          .collection('storage')
          .doc('key1');
      final snapshot = await doc.get();
      expect(snapshot.data()?['value'], 'value1');
    });

    test('set does not sync when userId is null', () async {
      await synced.set('key1', 'value1');
      await Future.delayed(Duration.zero);

      // No documents should be created in Firestore
      expect(fakeFirestore.collections.isEmpty, isTrue);
    });

    test('remove removes from local storage', () async {
      await localStorage.set('key1', 'value1');
      await synced.remove('key1');
      expect(await localStorage.get('key1'), isNull);
    });

    test('remove syncs deletion to Firestore when userId is set', () async {
      synced.setUserId('user123');
      // First set a value
      await synced.set('key1', 'value1');
      await Future.delayed(Duration.zero);

      // Then remove it
      await synced.remove('key1');
      await Future.delayed(Duration.zero);

      final doc = fakeFirestore
          .collection('users')
          .doc('user123')
          .collection('storage')
          .doc('key1');
      final snapshot = await doc.get();
      expect(snapshot.exists, isFalse);
    });

    test('pullFromCloud downloads Firestore data to local storage', () async {
      synced.setUserId('user123');

      // Simulate data in Firestore
      final collection = fakeFirestore
          .collection('users')
          .doc('user123')
          .collection('storage');
      await collection.doc('routines').set({'value': '{"data":"routines"}'});
      await collection.doc('profile').set({'value': '{"name":"Test"}'});

      await synced.pullFromCloud();

      expect(await localStorage.get('routines'), '{"data":"routines"}');
      expect(await localStorage.get('profile'), '{"name":"Test"}');
    });

    test('pullFromCloud does nothing when userId is null', () async {
      await synced.pullFromCloud();
      expect(localStorage.store.isEmpty, isTrue);
    });

    test('setUserId can be changed between users', () async {
      synced.setUserId('user1');
      await synced.set('key1', 'value_user1');
      await Future.delayed(Duration.zero);

      synced.setUserId('user2');
      await synced.set('key1', 'value_user2');
      await Future.delayed(Duration.zero);

      // User1's Firestore data
      final user1Doc = fakeFirestore
          .collection('users')
          .doc('user1')
          .collection('storage')
          .doc('key1');
      expect((await user1Doc.get()).data()?['value'], 'value_user1');

      // User2's Firestore data
      final user2Doc = fakeFirestore
          .collection('users')
          .doc('user2')
          .collection('storage')
          .doc('key1');
      expect((await user2Doc.get()).data()?['value'], 'value_user2');
    });

    test('pushToCloud uploads local data for given keys', () async {
      synced.setUserId('user123');
      await localStorage.set('routines', '[]');
      await localStorage.set('sessions', '{}');

      await synced.pushToCloud(['routines', 'sessions']);
      await Future.delayed(Duration.zero);

      final routinesDoc = fakeFirestore
          .collection('users')
          .doc('user123')
          .collection('storage')
          .doc('routines');
      expect((await routinesDoc.get()).data()?['value'], '[]');

      final sessionsDoc = fakeFirestore
          .collection('users')
          .doc('user123')
          .collection('storage')
          .doc('sessions');
      expect((await sessionsDoc.get()).data()?['value'], '{}');
    });
  });
}
