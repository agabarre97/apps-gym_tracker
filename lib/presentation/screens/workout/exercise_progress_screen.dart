import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/workout/exercise_progress_calculator.dart';

/// Displays historical progress for a single exercise within a specific
/// routine + day.
///
/// Features:
/// - Period selector (1, 3, 6, 12 months).
/// - Metric selector (volume, max weight, total reps).
/// - Line chart by training date.
/// - Summary block: first vs last record, min vs max value.
class ExerciseProgressScreen extends StatefulWidget {
  const ExerciseProgressScreen({
    super.key,
    required this.workoutSessionPort,
    required this.routineId,
    required this.routineDayIndex,
    required this.exerciseKey,
    required this.exerciseDisplayName,
  });

  final WorkoutSessionPort workoutSessionPort;
  final String routineId;
  final int routineDayIndex;
  final String exerciseKey;
  final String exerciseDisplayName;

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen> {
  List<WorkoutSession>? _sessions;
  int _periodMonths = 3;
  ProgressMetric _metric = ProgressMetric.volume;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await widget.workoutSessionPort.loadSessions();
    if (mounted) setState(() => _sessions = sessions);
  }

  ProgressResult _computeResult() {
    if (_sessions == null) return ProgressResult.empty;
    return ExerciseProgressCalculator.compute(
      sessions: _sessions!,
      routineId: widget.routineId,
      routineDayIndex: widget.routineDayIndex,
      exerciseKey: widget.exerciseKey,
      periodMonths: _periodMonths,
      metric: _metric,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String _metricLabel(AppLocalizations l10n, ProgressMetric m) {
    switch (m) {
      case ProgressMetric.volume:
        return l10n.progressMetricVolume;
      case ProgressMetric.maxWeight:
        return l10n.progressMetricMaxWeight;
      case ProgressMetric.totalReps:
        return l10n.progressMetricTotalReps;
    }
  }

  String _periodLabel(AppLocalizations l10n, int months) {
    switch (months) {
      case 1:
        return l10n.progressPeriod1m;
      case 3:
        return l10n.progressPeriod3m;
      case 6:
        return l10n.progressPeriod6m;
      case 12:
        return l10n.progressPeriod12m;
      default:
        return '$months';
    }
  }

  String _formatValue(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = _computeResult();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseDisplayName),
      ),
      body: _sessions == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Period selector ──
                _buildPeriodSelector(l10n),
                const SizedBox(height: 12),

                // ── Metric selector ──
                _buildMetricSelector(l10n),
                const SizedBox(height: 20),

                // ── Chart or empty state ──
                if (result.isEmpty)
                  _buildEmptyState(l10n)
                else ...[
                  _buildChart(result),
                  const SizedBox(height: 24),
                  _buildSummary(l10n, result),
                ],
              ],
            ),
    );
  }

  // ── Period chips ──

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    const periods = [1, 3, 6, 12];
    return Wrap(
      spacing: 8,
      children: periods.map((p) {
        final selected = p == _periodMonths;
        return ChoiceChip(
          label: Text(_periodLabel(l10n, p)),
          selected: selected,
          onSelected: (_) => setState(() => _periodMonths = p),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
        );
      }).toList(),
    );
  }

  // ── Metric segmented buttons ──

  Widget _buildMetricSelector(AppLocalizations l10n) {
    return SegmentedButton<ProgressMetric>(
      segments: ProgressMetric.values
          .map((m) => ButtonSegment<ProgressMetric>(
                value: m,
                label: Text(
                  _metricLabel(l10n, m),
                  style: const TextStyle(fontSize: 11),
                ),
              ))
          .toList(),
      selected: {_metric},
      onSelectionChanged: (s) => setState(() => _metric = s.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ── Empty state ──

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          l10n.progressNoData,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }

  // ── Line chart ──

  Widget _buildChart(ProgressResult result) {
    final spots = <FlSpot>[];
    final dateLabels = <int, String>{};

    for (var i = 0; i < result.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), result.points[i].value));
      dateLabels[i] = _formatDate(result.points[i].date);
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateYInterval(result),
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Colors.white12,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: _calculateYInterval(result),
                getTitlesWidget: (value, meta) {
                  // Hide labels that fall outside the visible range.
                  if (value < (result.minValue > 0 ? result.minValue * 0.9 : 0) ||
                      value > result.maxValue * 1.1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatValue(value),
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: _calculateXInterval(result),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= result.points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateLabels[idx] ?? '',
                      style: const TextStyle(fontSize: 9, color: Colors.white54),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final idx = s.spotIndex;
                final label = idx < result.points.length
                    ? _formatDate(result.points[idx].date)
                    : '';
                return LineTooltipItem(
                  '$label\n${_formatValue(s.y)}',
                  const TextStyle(fontSize: 12, color: Colors.white),
                );
              }).toList(),
            ),
          ),
          minY: result.minValue > 0 ? result.minValue * 0.9 : 0,
          maxY: result.maxValue * 1.1,
        ),
      ),
    );
  }

  double _calculateYInterval(ProgressResult result) {
    // Use the actual rendered range (including the 10% padding on both ends).
    final minY = result.minValue > 0 ? result.minValue * 0.9 : 0.0;
    final maxY = result.maxValue * 1.1;
    final range = maxY - minY;
    if (range <= 0) return 1;

    // Target only 3 gridlines so labels stay readable.
    final raw = range / 3;

    // Snap to a "nice" round number to avoid ugly decimal labels.
    const steps = [1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000, 5000];
    for (final s in steps) {
      if (s >= raw) return s.toDouble();
    }
    // Fallback for very large ranges: round up to nearest 1000.
    return (raw / 1000).ceilToDouble() * 1000;
  }

  double _calculateXInterval(ProgressResult result) {
    final count = result.points.length;
    if (count <= 6) return 1;
    return (count / 5).ceilToDouble();
  }

  // ── Summary block ──

  Widget _buildSummary(AppLocalizations l10n, ProgressResult result) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow(
              l10n.progressFirstRecord,
              _formatValue(result.firstValue),
              l10n.progressLastRecord,
              _formatValue(result.lastValue),
            ),
            const Divider(height: 24),
            _summaryRow(
              l10n.progressMinValue,
              _formatValue(result.minValue),
              l10n.progressMaxValue,
              _formatValue(result.maxValue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String leftLabel,
    String leftValue,
    String rightLabel,
    String rightValue,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
              const SizedBox(height: 4),
              Text(leftValue,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
              const SizedBox(height: 4),
              Text(rightValue,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
