import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/circular_timer_painter.dart';
import 'package:gym_tracker/presentation/components/time_wheel_picker.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

/// Full-screen HIIT timer with preview, countdown, exercise/rest phases,
/// set rest, and completion.
class HiitTimerScreen extends StatefulWidget {
  const HiitTimerScreen({
    super.key,
    required this.exercises,
    required this.routineName,
    required this.sets,
    required this.workSeconds,
    required this.restSeconds,
    required this.setRestSeconds,
    required this.hiitSessionPort,
  });

  final List<HiitExercise> exercises;
  final String routineName;
  final int sets;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;
  final HiitSessionPort hiitSessionPort;

  @override
  State<HiitTimerScreen> createState() => _HiitTimerScreenState();
}

enum _Phase { preview, countdown, exercise, exerciseRest, setRest, complete }

class _HiitTimerScreenState extends State<HiitTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _countdownDuration = 5;

  // Configurable settings (can be adjusted in preview)
  late int _sets;
  late int _workSeconds;
  late int _restSeconds;
  late int _setRestSeconds;
  bool _soundEnabled = true;

  // Timer state
  int _setIndex = 0;
  int _exerciseIndex = 0;
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
    _sets = widget.sets;
    _workSeconds = widget.workSeconds;
    _restSeconds = widget.restSeconds;
    _setRestSeconds = widget.setRestSeconds;
    _animController = AnimationController(vsync: this);
    _progressAnim =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  HiitExercise get _currentExercise => widget.exercises[_exerciseIndex];

  HiitExercise? get _nextExercise {
    final nextIdx = _exerciseIndex + 1;
    if (nextIdx < widget.exercises.length) {
      return widget.exercises[nextIdx];
    }
    return null;
  }

  int get _totalDurationSeconds {
    final exerciseCount = widget.exercises.length;
    final workPerSet = exerciseCount * _workSeconds;
    final restPerSet = (exerciseCount - 1) * _restSeconds;
    final setRest = (_sets - 1) * _setRestSeconds;
    return _sets * (workPerSet + restPerSet) + setRest;
  }

  String _formatDuration(int totalSeconds) =>
      TimeFormatter.duration(totalSeconds);

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
      case _Phase.exerciseRest:
        _advanceToNextExercise();
      case _Phase.setRest:
        _advanceToNextSet();
      default:
        break;
    }
  }

  void _startFirstExercise() {
    setState(() {
      _setIndex = 0;
      _exerciseIndex = 0;
      _phase = _Phase.exercise;
      _paused = false;
    });
    _beginPhase(_workSeconds);
  }

  void _advanceAfterExercise() {
    // After an exercise: either rest between exercises, set rest, or complete
    if (_exerciseIndex < widget.exercises.length - 1) {
      // More exercises in this set → exercise rest
      if (_restSeconds > 0) {
        setState(() {
          _phase = _Phase.exerciseRest;
          _paused = false;
        });
        _beginPhase(_restSeconds);
      } else {
        _advanceToNextExercise();
      }
    } else if (_setIndex < _sets - 1) {
      // Last exercise of set, more sets to go → set rest
      if (_setRestSeconds > 0) {
        setState(() {
          _phase = _Phase.setRest;
          _paused = false;
        });
        _beginPhase(_setRestSeconds);
      } else {
        _advanceToNextSet();
      }
    } else {
      // All sets done
      _onRoutineComplete();
    }
  }

  void _advanceToNextExercise() {
    setState(() {
      _exerciseIndex++;
      _phase = _Phase.exercise;
      _paused = false;
    });
    _beginPhase(_workSeconds);
  }

  void _advanceToNextSet() {
    setState(() {
      _setIndex++;
      _exerciseIndex = 0;
      _phase = _Phase.exercise;
      _paused = false;
    });
    _beginPhase(_workSeconds);
  }

  Future<void> _onRoutineComplete() async {
    _timer?.cancel();
    _animController.stop();
    setState(() => _phase = _Phase.complete);

    final session = HiitSession(
      id: const Uuid().v4(),
      routineName: widget.routineName,
      date: DateTime.now(),
      startTime: _sessionStartTime,
      endTime: DateTime.now(),
    );

    final existing = await widget.hiitSessionPort.loadSessions();
    await widget.hiitSessionPort.saveSessions([...existing, session]);
  }

  // ── Finish early ──────────────────────────────────────────────

  Future<void> _confirmFinishEarly() async {
    final l10n = AppLocalizations.of(context)!;

    final wasPaused = _paused;
    if (!_paused) _togglePause();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hiitFinishEarly),
        content: Text(l10n.hiitFinishEarlyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.sharedCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.hiitFinishEarly),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer?.cancel();
      _animController.stop();
      if (!mounted) return;
      Navigator.of(context).pop(false);
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
      final fraction = _totalPhaseSeconds > 0
          ? _remainingSeconds / _totalPhaseSeconds
          : 0.0;
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.hiitConfig,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Work duration
                      _buildSettingsTimeRow(
                        label: l10n.hiitWorkDuration,
                        value: _workSeconds,
                        min: HiitConfig.minWorkSeconds,
                        max: HiitConfig.maxWorkSeconds,
                        onChanged: (v) {
                          setSheetState(() => _workSeconds = v);
                          setState(() {});
                        },
                      ),
                      // Rest between exercises
                      _buildSettingsTimeRow(
                        label: l10n.hiitRestDuration,
                        value: _restSeconds,
                        min: HiitConfig.minRestSeconds,
                        max: HiitConfig.maxRestSeconds,
                        onChanged: (v) {
                          setSheetState(() => _restSeconds = v);
                          setState(() {});
                        },
                      ),
                      // Rest between sets
                      _buildSettingsTimeRow(
                        label: l10n.hiitSetRestDuration,
                        value: _setRestSeconds,
                        min: HiitConfig.minSetRestSeconds,
                        max: HiitConfig.maxSetRestSeconds,
                        onChanged: (v) {
                          setSheetState(() => _setRestSeconds = v);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
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

    final showSettings = _phase == _Phase.preview;
    final showFinish = _phase == _Phase.exercise ||
        _phase == _Phase.exerciseRest ||
        _phase == _Phase.setRest ||
        _phase == _Phase.countdown;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineName),
        actions: [
          if (showFinish)
            TextButton(
              onPressed: _confirmFinishEarly,
              child: Text(
                l10n.hiitFinishEarly,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettings,
              tooltip: l10n.hiitConfig,
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
    return Column(
      children: [
        // Total duration header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                '${l10n.hiitTotalDuration}: ${_formatDuration(_totalDurationSeconds)}',
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
        ),
        // Config summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.repeat, size: 16),
                label: Text(l10n.hiitSetCount('$_sets')),
              ),
              Chip(
                avatar: const Icon(Icons.fitness_center, size: 16),
                label: Text(l10n.hiitSeconds('$_workSeconds')),
              ),
              Chip(
                avatar: const Icon(Icons.pause, size: 16),
                label: Text(l10n.hiitSeconds('$_restSeconds')),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: widget.exercises.length,
            itemBuilder: (context, index) {
              final exercise = widget.exercises[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white12,
                  child: Text('${index + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ),
                title: Text(exercise.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(exercise.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white38)),
              );
            },
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

  // ── Countdown ─────────────────────────────────────────────────

  Widget _buildCountdown(AppLocalizations l10n) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.hiitGetReady,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentExercise.name,
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

  // ── Timer view (exercise, exerciseRest, setRest) ──────────────

  Widget _buildTimerView(AppLocalizations l10n) {
    final isExercise = _phase == _Phase.exercise;
    final isExerciseRest = _phase == _Phase.exerciseRest;
    final isSetRest = _phase == _Phase.setRest;

    String title;
    String subtitle;
    Color timerColor;

    if (isExercise) {
      title = _currentExercise.name;
      subtitle = l10n.hiitSetOf('${_setIndex + 1}', '$_sets');
      timerColor = Colors.greenAccent;
    } else if (isExerciseRest) {
      title = l10n.hiitRest;
      subtitle = l10n.hiitExerciseOf(
          '${_exerciseIndex + 1}', '${widget.exercises.length}');
      timerColor = Colors.orangeAccent;
    } else {
      title = l10n.hiitSetComplete;
      subtitle = l10n.hiitSetRest;
      timerColor = Colors.blueAccent;
    }

    final stepInfo = isExercise
        ? l10n.hiitExerciseOf(
            '${_exerciseIndex + 1}', '${widget.exercises.length}')
        : '';

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (stepInfo.isNotEmpty)
            Text(stepInfo,
                style: const TextStyle(fontSize: 14, color: Colors.white54)),
          if (stepInfo.isNotEmpty) const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isExercise ? Colors.white : timerColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          if (isExercise)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.hiitSetOf('${_setIndex + 1}', '$_sets'),
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600),
              ),
            ),

          // Circular timer
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
                        color: timerColor,
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
                        if (!isExercise)
                          Text(
                            isExerciseRest
                                ? l10n.hiitRest
                                : l10n.hiitSetRest,
                            style: TextStyle(
                                fontSize: 14, color: timerColor),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Next exercise info during rest phases
          if ((isExerciseRest && _nextExercise != null) || isSetRest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.skip_next, size: 18, color: Colors.white38),
                  const SizedBox(width: 6),
                  Text(
                    isSetRest
                        ? '${l10n.hiitSetOf('${_setIndex + 2}', '$_sets')} — ${widget.exercises.first.name}'
                        : _nextExercise!.name,
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
            const Icon(Icons.check_circle,
                size: 80, color: Colors.greenAccent),
            const SizedBox(height: 24),
            Text(l10n.hiitComplete,
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

  Widget _buildSettingsTimeRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          TimeWheelPicker(
            minSeconds: min,
            maxSeconds: max,
            stepSeconds: HiitConfig.stepSeconds,
            selectedSeconds: value,
            onChanged: onChanged,
            height: 100,
            width: 80,
          ),
        ],
      ),
    );
  }
}
