import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('LocalStorageDatasource (via FakeStoragePort)', () {
    late FakeStoragePort storage;

    setUp(() {
      storage = FakeStoragePort();
    });

    test('get() returns null for missing key', () async {
      expect(await storage.get('missing'), isNull);
    });

    test('set() then get() returns the stored value', () async {
      await storage.set('name', 'Alice');
      expect(await storage.get('name'), 'Alice');
    });

    test('set() overwrites previous value', () async {
      await storage.set('count', '1');
      await storage.set('count', '2');
      expect(await storage.get('count'), '2');
    });

    test('remove() deletes a key', () async {
      await storage.set('temp', 'value');
      await storage.remove('temp');
      expect(await storage.get('temp'), isNull);
    });

    test('remove() on non-existent key does not throw', () async {
      expect(() => storage.remove('nope'), returnsNormally);
    });

    test('multiple keys coexist independently', () async {
      await storage.set('a', '1');
      await storage.set('b', '2');
      expect(await storage.get('a'), '1');
      expect(await storage.get('b'), '2');

      await storage.remove('a');
      expect(await storage.get('a'), isNull);
      expect(await storage.get('b'), '2');
    });
  });
}
