import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/components/export_sheet.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Export sheet', () {
    testWidgets('shows PDF option when callback is provided', (tester) async {
      var pdfTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showExportSheet(
                    context,
                    jsonString: '{"name":"test"}',
                    onExportPdf: () async {
                      pdfTapped = true;
                    },
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Copiar al portapapeles'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
      expect(find.text('Exportar PDF'), findsOneWidget);

      await tester.tap(find.text('Exportar PDF'));
      await tester.pumpAndSettle();
      expect(pdfTapped, isTrue);
    });

    testWidgets('does not show PDF option when callback is omitted',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showExportSheet(
                    context,
                    jsonString: '{"name":"test"}',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Exportar PDF'), findsNothing);
    });
  });
}
