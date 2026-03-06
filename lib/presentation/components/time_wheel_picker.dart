import 'package:flutter/material.dart';

import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// A compact vertical scroll-wheel picker for time values in seconds.
///
/// Values range from [minSeconds] to [maxSeconds] in [stepSeconds] increments.
/// The wheel snaps to the nearest value and provides a "roulette" scrolling feel.
class TimeWheelPicker extends StatefulWidget {
  const TimeWheelPicker({
    super.key,
    required this.minSeconds,
    required this.maxSeconds,
    this.stepSeconds = 5,
    required this.selectedSeconds,
    required this.onChanged,
    this.height = 120,
    this.width = 90,
  });

  final int minSeconds;
  final int maxSeconds;
  final int stepSeconds;
  final int selectedSeconds;
  final ValueChanged<int> onChanged;
  final double height;
  final double width;

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  late FixedExtentScrollController _controller;
  late List<int> _values;

  static const double _itemExtent = 36;

  @override
  void initState() {
    super.initState();
    _values = _generateValues();
    _controller = FixedExtentScrollController(
      initialItem: _closestIndex(widget.selectedSeconds),
    );
  }

  @override
  void didUpdateWidget(TimeWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minSeconds != widget.minSeconds ||
        oldWidget.maxSeconds != widget.maxSeconds ||
        oldWidget.stepSeconds != widget.stepSeconds) {
      _values = _generateValues();
    }
    final targetIndex = _closestIndex(widget.selectedSeconds);
    if (_controller.selectedItem != targetIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToItem(targetIndex);
        }
      });
    }
  }

  List<int> _generateValues() {
    final result = <int>[];
    for (var v = widget.minSeconds;
        v <= widget.maxSeconds;
        v += widget.stepSeconds) {
      result.add(v);
    }
    return result;
  }

  int _closestIndex(int seconds) {
    if (_values.isEmpty) return 0;
    int bestIndex = 0;
    int bestDiff = (seconds - _values[0]).abs();
    for (var i = 1; i < _values.length; i++) {
      final diff = (seconds - _values[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  /// Formats seconds into a compact human-readable label.
  static String formatSeconds(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '${m}m';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0.0, 0.25, 0.75, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: Stack(
          children: [
            // Selection highlight behind the center item
            Center(
              child: Container(
                height: _itemExtent + 4,
                decoration: BoxDecoration(
                  color: context.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.dividerSubtle, width: 0.5),
                ),
              ),
            ),
            // Scrollable wheel
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: _itemExtent,
              diameterRatio: 1.3,
              perspective: 0.004,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                widget.onChanged(_values[index]);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index >= _values.length) return null;
                  return Center(
                    child: Text(
                      formatSeconds(_values[index]),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  );
                },
                childCount: _values.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
