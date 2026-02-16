import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extension on [WidgetTester] providing standardized scrolling helpers
/// for widget and E2E tests.
///
/// These helpers prevent fragile scroll code by always specifying an explicit
/// [Scrollable] target (instead of relying on the implicit first-found one,
/// which can be unstable when nested scrollables like [ListWheelScrollView]
/// are present).
extension ScrollHelpers on WidgetTester {
  /// Default scroll delta used by helpers (px per scroll attempt).
  static const double _defaultDelta = 200;

  /// Scrolls the primary (first) [Scrollable] until [finder] becomes visible.
  ///
  /// Use this when the target widget is inside the main [ListView] or
  /// [SingleChildScrollView] and may be below the visible fold.
  Future<void> scrollDownTo(
    Finder finder, {
    double delta = _defaultDelta,
  }) async {
    await scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpAndSettle();
  }

  /// Scrolls the last [Scrollable] (typically a nested list inside a parent
  /// layout) until [finder] becomes visible.
  ///
  /// Use this when the target widget lives inside a nested scrollable that is
  /// **not** the outermost one (e.g. an exercise list inside a screen that
  /// also has other scrollables).
  Future<void> scrollDownToInNestedList(
    Finder finder, {
    double delta = _defaultDelta,
  }) async {
    await scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).last,
    );
    await pumpAndSettle();
  }

  /// Scrolls to [finder] in the primary scrollable, then taps it.
  Future<void> scrollToAndTap(
    Finder finder, {
    double delta = _defaultDelta,
  }) async {
    await scrollDownTo(finder, delta: delta);
    await tap(finder);
    await pumpAndSettle();
  }
}
