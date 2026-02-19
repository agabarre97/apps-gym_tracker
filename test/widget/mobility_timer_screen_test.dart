import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/presentation/screens/mobility/mobility_timer_screen.dart';

import '../helpers/test_helpers.dart';

const _testRoutine = MobilityRoutine(
  key: 'test_routine',
  nameKey: 'test',
  totalDurationMinutes: 5,
  exercises: [
    MobilityExercise(key: 'stretch_a', durationSeconds: 30, bilateral: true),
    MobilityExercise(key: 'stretch_b', durationSeconds: 20, bilateral: false),
  ],
);

void main() {
  group('MobilityTimerScreen', () {
    testWidgets('without autoStart shows preview with Comenzar button',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MobilityTimerScreen(
            routine: _testRoutine,
            mobilitySessionPort: FakeMobilitySessionPort(),
            routineName: 'Test Mobility',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preview phase: start button visible
      expect(find.text('Comenzar'), findsOneWidget);
    });

    testWidgets('with autoStart skips preview and enters countdown',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MobilityTimerScreen(
            routine: _testRoutine,
            mobilitySessionPort: FakeMobilitySessionPort(),
            routineName: 'Test Mobility',
            autoStart: true,
          ),
        ),
      );

      // After first frame, autoStart triggers the countdown
      await tester.pump();
      await tester.pump();

      // Countdown phase: "¡Prepárate!" (Spanish) — no manual tap needed
      expect(find.text('¡Prepárate!'), findsOneWidget);

      // The preview "Comenzar" button should no longer be visible
      expect(find.text('Comenzar'), findsNothing);
    });

    testWidgets(
        'finish early from top saves session and returns success result',
        (tester) async {
      final mobilityPort = FakeMobilitySessionPort();

      await tester.pumpWidget(
        buildTestableWidget(
          _MobilityTimerRouteHost(
            mobilitySessionPort: mobilityPort,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await tester.tap(find.text('Finalizar').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Finalizar'),
            )
            .last,
      );
      await tester.pumpAndSettle();

      final sessions = await mobilityPort.loadSessions();
      expect(sessions, hasLength(1));
      expect(find.text('result:true'), findsOneWidget);
    });
  });
}

class _MobilityTimerRouteHost extends StatefulWidget {
  const _MobilityTimerRouteHost({required this.mobilitySessionPort});

  final FakeMobilitySessionPort mobilitySessionPort;

  @override
  State<_MobilityTimerRouteHost> createState() =>
      _MobilityTimerRouteHostState();
}

class _MobilityTimerRouteHostState extends State<_MobilityTimerRouteHost> {
  bool _opened = false;
  bool? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MobilityTimerScreen(
            routine: _testRoutine,
            mobilitySessionPort: widget.mobilitySessionPort,
            routineName: 'Test Mobility',
          ),
        ),
      );
      if (!mounted) return;
      setState(() => _result = result);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Text('result:${_result ?? 'null'}'),
        ),
      );
}
