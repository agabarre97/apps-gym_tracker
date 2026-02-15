import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/components/language_selector.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('LanguageSelector', () {
    testWidgets('renders a globe icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            appBar: AppBar(
              actions: [
                LanguageSelector(
                  onLocaleChanged: (_) {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('tapping toggles from ES to EN', (tester) async {
      Locale? received;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            appBar: AppBar(
              actions: [
                LanguageSelector(
                  onLocaleChanged: (l) => received = l,
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pump();

      expect(received, const Locale('en'));
    });

    testWidgets('tapping toggles from EN to ES', (tester) async {
      Locale? received;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            appBar: AppBar(
              actions: [
                LanguageSelector(
                  onLocaleChanged: (l) => received = l,
                ),
              ],
            ),
            body: const SizedBox(),
          ),
          locale: const Locale('en'),
        ),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pump();

      expect(received, const Locale('es'));
    });
  });

  group('LocaleStorage', () {
    test('load() returns ES when no locale saved', () async {
      final storage = FakeStoragePort();
      final localeStorage = LocaleStorage(storage);

      final locale = await localeStorage.load();
      expect(locale, const Locale('es'));
    });

    test('save() then load() returns the saved locale', () async {
      final storage = FakeStoragePort();
      final localeStorage = LocaleStorage(storage);

      await localeStorage.save(const Locale('en'));
      final loaded = await localeStorage.load();
      expect(loaded, const Locale('en'));
    });

    test('save() persists the language code to storage', () async {
      final storage = FakeStoragePort();
      final localeStorage = LocaleStorage(storage);

      await localeStorage.save(const Locale('en'));
      expect(await storage.get('app_locale'), 'en');
    });
  });
}
