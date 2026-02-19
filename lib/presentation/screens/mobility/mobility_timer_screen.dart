import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/circular_timer_painter.dart';
import 'package:gym_tracker/presentation/components/mobility_exercise_tile.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

/// Full-screen mobility timer with preview, countdown, circular timer,
/// rest periods, beeps, and early finish support.
class MobilityTimerScreen extends StatefulWidget {
  const MobilityTimerScreen({
    super.key,
    required this.routine,
    required this.mobilitySessionPort,
    required this.routineName,
    this.autoStart = false,
  });

  final MobilityRoutine routine;
  final MobilitySessionPort mobilitySessionPort;
  final String routineName;

  /// When true, the countdown starts automatically on first frame,
  /// skipping the manual "Comenzar" tap in the preview phase.
  final bool autoStart;

  @override
  State<MobilityTimerScreen> createState() => _MobilityTimerScreenState();
}

enum _Phase { preview, countdown, exercise, rest, complete }

class _MobilityTimerScreenState extends State<MobilityTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _countdownDuration = 5;

  // Settings
  int _restSeconds = 5;
  bool _soundEnabled = true;

  // Timer state
  int _exerciseIndex = 0;
  bool _isLeftSide = true;
  _Phase _phase = _Phase.preview;
  int _remainingSeconds = 0;
  int _totalPhaseSeconds = 0;
  Timer? _timer;
  bool _paused = false;

  // Smooth animation
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _progressAnim =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animController);

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onStartPressed();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  MobilityExercise get _currentExercise =>
      widget.routine.exercises[_exerciseIndex];

  MobilityExercise? get _nextExercise {
    final nextIdx = _exerciseIndex + 1;
    if (nextIdx < widget.routine.exercises.length) {
      return widget.routine.exercises[nextIdx];
    }
    return null;
  }

  int get _totalExerciseSteps {
    int count = 0;
    for (final ex in widget.routine.exercises) {
      count += ex.bilateral ? 1 : 2;
    }
    return count;
  }

  int get _currentStepNumber {
    int count = 0;
    for (int i = 0; i < _exerciseIndex; i++) {
      count += widget.routine.exercises[i].bilateral ? 1 : 2;
    }
    if (!_currentExercise.bilateral && !_isLeftSide) count++;
    return count + 1;
  }

  // ── Start / Phases ────────────────────────────────────────────

  void _onStartPressed() {
    setState(() {
      _sessionStartTime = DateTime.now();
      _phase = _Phase.countdown;
    });
    _beginPhase(_countdownDuration);
  }

  void _beginPhase(int seconds) {
    _remainingSeconds = seconds;
    _totalPhaseSeconds = seconds;

    _animController.duration = Duration(seconds: seconds);
    _animController.forward(from: 0.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() => _remainingSeconds--);

      if (_remainingSeconds <= 3 && _remainingSeconds > 0 && _soundEnabled) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      }

      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        if (_soundEnabled) {
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
        }
        _onPhaseComplete();
      }
    });
  }

  void _onPhaseComplete() {
    switch (_phase) {
      case _Phase.countdown:
        _startFirstExercise();
      case _Phase.exercise:
        _advanceAfterExercise();
      case _Phase.rest:
        _advanceToNextExercise();
      default:
        break;
    }
  }

  void _startFirstExercise() {
    setState(() {
      _phase = _Phase.exercise;
      _paused = false;
    });
    _beginPhase(_currentExercise.durationSeconds);
  }

  void _advanceAfterExercise() {
    final ex = _currentExercise;
    if (!ex.bilateral && _isLeftSide) {
      setState(() => _isLeftSide = false);
      _beginPhase(ex.durationSeconds);
      return;
    }
    if (_exerciseIndex < widget.routine.exercises.length - 1) {
      _startRest();
    } else {
      _onRoutineComplete();
    }
  }

  void _startRest() {
    if (_restSeconds == 0) {
      _advanceToNextExercise();
      return;
    }
    setState(() {
      _phase = _Phase.rest;
      _paused = false;
    });
    _beginPhase(_restSeconds);
  }

  void _advanceToNextExercise() {
    setState(() {
      _exerciseIndex++;
      _isLeftSide = true;
      _phase = _Phase.exercise;
      _paused = false;
    });
    _beginPhase(_currentExercise.durationSeconds);
  }

  Future<void> _onRoutineComplete() async {
    _timer?.cancel();
    _animController.stop();
    setState(() => _phase = _Phase.complete);
    await _saveCompletedSession();
  }

  Future<void> _saveCompletedSession() async {
    final session = MobilitySession(
      id: const Uuid().v4(),
      routineKey: widget.routine.key,
      date: DateTime.now(),
      startTime: _sessionStartTime,
      endTime: DateTime.now(),
    );

    final existing = await widget.mobilitySessionPort.loadSessions();
    await widget.mobilitySessionPort.saveSessions([...existing, session]);
  }

  // ── Finish early ──────────────────────────────────────────────

  Future<void> _confirmFinishEarly() async {
    final l10n = AppLocalizations.of(context)!;

    // Pause while the dialog is open
    final wasPaused = _paused;
    if (!_paused) _togglePause();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mobilityFinishEarly),
        content: Text(l10n.mobilityFinishEarlyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sharedCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.mobilityFinishEarly),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer?.cancel();
      _animController.stop();
      await _saveCompletedSession();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else if (!wasPaused) {
      _togglePause();
    }
  }

  // ── Pause / Resume ────────────────────────────────────────────

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _animController.stop();
    } else {
      final fraction =
          _totalPhaseSeconds > 0 ? _remainingSeconds / _totalPhaseSeconds : 0.0;
      _animController.duration = Duration(seconds: _remainingSeconds);
      _animController.forward(from: 1.0 - fraction);
    }
  }

  void _showSettings() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mobilitySettings,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(l10n.mobilityRestDuration,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                            value: 0, label: Text(l10n.mobilityRestOff)),
                        ButtonSegment(
                            value: 5,
                            label: Text(l10n.mobilityRestSeconds('5'))),
                        ButtonSegment(
                            value: 10,
                            label: Text(l10n.mobilityRestSeconds('10'))),
                      ],
                      selected: {_restSeconds},
                      onSelectionChanged: (val) {
                        setSheetState(() => _restSeconds = val.first);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.mobilitySound),
                      value: _soundEnabled,
                      onChanged: (val) {
                        setSheetState(() => _soundEnabled = val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final showSettings = _phase != _Phase.complete && _phase != _Phase.preview;
    final showFinish = _phase == _Phase.exercise ||
        _phase == _Phase.rest ||
        _phase == _Phase.countdown;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineName),
        actions: [
          if (showFinish)
            TextButton(
              onPressed: _confirmFinishEarly,
              child: Text(
                l10n.mobilityFinishEarly,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettings,
              tooltip: l10n.mobilitySettings,
            ),
        ],
      ),
      body: switch (_phase) {
        _Phase.preview => _buildPreview(l10n),
        _Phase.countdown => _buildCountdown(l10n),
        _Phase.complete => _buildCompleteView(l10n),
        _ => _buildTimerView(l10n),
      },
    );
  }

  // ── Preview ───────────────────────────────────────────────────

  Widget _buildPreview(AppLocalizations l10n) {
    final exercises = widget.routine.exercises;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: exercises.length,
            itemBuilder: (context, index) => MobilityExerciseTile(
              exercise: exercises[index],
              index: index,
              l10n: l10n,
              variant: MobilityExerciseTileVariant.compact,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _onStartPressed,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.sharedStart),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Countdown (Get ready!) ────────────────────────────────────

  Widget _buildCountdown(AppLocalizations l10n) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.mobilityGetReady,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mobilityExerciseDisplayName(_currentExercise.key, l10n),
              style: const TextStyle(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CircularTimerPainter(
                      progress: 1.0 - _progressAnim.value,
                      color: Colors.amberAccent,
                      backgroundColor: Colors.white12,
                      strokeWidth: 10,
                    ),
                    child: child,
                  );
                },
                child: Center(
                  child: Text(
                    '$_remainingSeconds',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timer ─────────────────────────────────────────────────────

  Widget _buildTimerView(AppLocalizations l10n) {
    final isRest = _phase == _Phase.rest;
    final exerciseName =
        mobilityExerciseDisplayName(_currentExercise.key, l10n);

    String sideLabel;
    if (isRest) {
      sideLabel = l10n.mobilityRest;
    } else if (_currentExercise.bilateral) {
      sideLabel = l10n.mobilityBothSides;
    } else {
      sideLabel = _isLeftSide ? l10n.mobilityLeftSide : l10n.mobilityRightSide;
    }

    final stepInfo = l10n.mobilityExerciseOf(
      '$_currentStepNumber',
      '$_totalExerciseSteps',
    );

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(stepInfo,
              style: const TextStyle(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              exerciseName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isRest ? Colors.white38 : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isRest ? Colors.orange.withAlpha(40) : Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sideLabel,
              style: TextStyle(
                fontSize: 14,
                color: isRest ? Colors.orangeAccent : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Circular timer with smooth animation
          Expanded(
            child: Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CircularTimerPainter(
                        progress: 1.0 - _progressAnim.value,
                        color:
                            isRest ? Colors.orangeAccent : Colors.greenAccent,
                        backgroundColor: Colors.white12,
                        strokeWidth: 10,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatSeconds(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                        if (isRest)
                          Text(l10n.mobilityRest,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.orangeAccent)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Next exercise info during rest
          if (isRest && _nextExercise != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.skip_next, size: 18, color: Colors.white38),
                  const SizedBox(width: 6),
                  Text(
                    mobilityExerciseDisplayName(_nextExercise!.key, l10n),
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),

          // Pause / Resume
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 16),
            child: IconButton.filled(
              iconSize: 48,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.all(16),
              ),
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
            ),
          ),
        ],
      ),
    );
  }

  // ── Complete ──────────────────────────────────────────────────

  Widget _buildCompleteView(AppLocalizations l10n) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 24),
            Text(l10n.mobilityComplete,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(widget.routineName,
                style: const TextStyle(fontSize: 16, color: Colors.white54)),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.sharedBack),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) => TimeFormatter.mmss(seconds);
}
