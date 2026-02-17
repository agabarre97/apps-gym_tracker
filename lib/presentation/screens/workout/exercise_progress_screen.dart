import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/domain/services/exercise_progress_calculator.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Displays historical progress for a single exercise within a specific
/// routine + day.
///
/// Features:
/// - Period selector (1, 3, 6, 12 months).
/// - Metric selector (volume, max weight, total reps).
/// - Line chart by training date.
/// - Summary block: first vs last record, min vs max value.
/// - Heaviest single-set summary (independent of period/metric).
/// - 2-day comparison bar chart (per-set, overlapping bars with touch highlighting).
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

  /// The two dates currently selected for comparison (newest first).
  List<DateTime> _comparedDates = [];

  /// Which day is highlighted in the comparison chart (-1 = none, 0 = day 1, 1 = day 2).
  int _highlightedDayIndex = -1;

  /// Currently touched bar group and rod for manual tooltip display.
  int _touchedGroupIdx = -1;
  int _touchedRodIdx = -1;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await widget.workoutSessionPort.loadSessions();
    if (!mounted) return;

    // Initialize compared dates to the latest 2 available
    final dates = ExerciseProgressCalculator.availableDates(
      sessions: sessions,
      routineId: widget.routineId,
      routineDayIndex: widget.routineDayIndex,
      exerciseKey: widget.exerciseKey,
    );
    setState(() {
      _sessions = sessions;
      _comparedDates =
          dates.length >= 2 ? [dates[0], dates[1]] : List.of(dates);
    });
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
    // Show up to 2 decimals, trimming trailing zeros
    final s = v.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _formatDateFull(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
                // ── Heaviest set summary (always visible if data exists) ──
                _buildHeaviestSetCard(l10n),
                const SizedBox(height: 16),

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

                const SizedBox(height: 32),

                // ── 2-day comparison section ──
                _buildComparisonSection(l10n),
              ],
            ),
    );
  }

  // ── Heaviest set card ──

  Widget _buildHeaviestSetCard(AppLocalizations l10n) {
    if (_sessions == null) return const SizedBox.shrink();

    final heaviest = ExerciseProgressCalculator.computeHeaviestSet(
      sessions: _sessions!,
      routineId: widget.routineId,
      routineDayIndex: widget.routineDayIndex,
      exerciseKey: widget.exerciseKey,
    );

    if (heaviest == null) return const SizedBox.shrink();

    final weightStr = heaviest.weight == heaviest.weight.truncateToDouble()
        ? heaviest.weight.toInt().toString()
        : heaviest.weight
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');

    return Card(
      color:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade400, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.progressHeaviestSet,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${weightStr}kg x ${heaviest.reps} reps',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              _formatDateFull(heaviest.date),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
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
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: _calculateYInterval(result),
                getTitlesWidget: (value, meta) {
                  if (value <
                          (result.minValue > 0 ? result.minValue * 0.9 : 0) ||
                      value > result.maxValue * 1.1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatValue(value),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white54),
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
                      style:
                          const TextStyle(fontSize: 9, color: Colors.white54),
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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
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
    final minY = result.minValue > 0 ? result.minValue * 0.9 : 0.0;
    final maxY = result.maxValue * 1.1;
    final range = maxY - minY;
    if (range <= 0) return 1;

    final raw = range / 3;

    const steps = [
      1,
      2,
      5,
      10,
      20,
      25,
      50,
      100,
      200,
      250,
      500,
      1000,
      2000,
      5000
    ];
    for (final s in steps) {
      if (s >= raw) return s.toDouble();
    }
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

  // ── 2-Day comparison section ──

  Widget _buildComparisonSection(AppLocalizations l10n) {
    if (_sessions == null) return const SizedBox.shrink();

    final allDates = ExerciseProgressCalculator.availableDates(
      sessions: _sessions!,
      routineId: widget.routineId,
      routineDayIndex: widget.routineDayIndex,
      exerciseKey: widget.exerciseKey,
    );

    if (allDates.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.progressCompareTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Day selectors
        Row(
          children: [
            Expanded(
              child: _DaySelector(
                label: l10n.progressDay1,
                selected: _comparedDates.isNotEmpty ? _comparedDates[0] : null,
                availableDates: allDates,
                color: Theme.of(context).colorScheme.primary,
                formatDate: _formatDateFull,
                onChanged: (d) {
                  setState(() {
                    if (_comparedDates.isEmpty) {
                      _comparedDates = [d];
                    } else {
                      _comparedDates = [d, ..._comparedDates.skip(1)];
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DaySelector(
                label: l10n.progressDay2,
                selected: _comparedDates.length >= 2 ? _comparedDates[1] : null,
                availableDates: allDates,
                color: Colors.orangeAccent,
                formatDate: _formatDateFull,
                onChanged: (d) {
                  setState(() {
                    if (_comparedDates.length < 2) {
                      _comparedDates = [..._comparedDates, d];
                    } else {
                      _comparedDates = [_comparedDates[0], d];
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Comparison bar chart
        _buildComparisonChart(l10n),
      ],
    );
  }

  Widget _buildComparisonChart(AppLocalizations l10n) {
    if (_sessions == null || _comparedDates.length < 2) {
      return const SizedBox.shrink();
    }

    final data1 = ExerciseProgressCalculator.setsForDate(
      sessions: _sessions!,
      routineId: widget.routineId,
      routineDayIndex: widget.routineDayIndex,
      exerciseKey: widget.exerciseKey,
      date: _comparedDates[0],
    );
    final data2 = ExerciseProgressCalculator.setsForDate(
      sessions: _sessions!,
      routineId: widget.routineId,
      routineDayIndex: widget.routineDayIndex,
      exerciseKey: widget.exerciseKey,
      date: _comparedDates[1],
    );

    if (data1 == null && data2 == null) {
      return Center(
        child: Text(l10n.progressNoData,
            style: const TextStyle(color: Colors.white54)),
      );
    }

    final sets1 = data1?.sets ?? <ExerciseSet>[];
    final sets2 = data2?.sets ?? <ExerciseSet>[];

    // Group sets by weight for each day
    final day1ByWeight = _groupSetsByWeight(sets1);
    final day2ByWeight = _groupSetsByWeight(sets2);

    final allWeights =
        <double>{...day1ByWeight.keys, ...day2ByWeight.keys}.toList()..sort();
    if (allWeights.isEmpty) return const SizedBox.shrink();

    final primaryColor = Theme.of(context).colorScheme.primary;
    const secondaryColor = Colors.orangeAccent;

    // Day 1 wider (behind), Day 2 narrower (front), centered overlap.
    const widthDay1 = 28.0;
    const widthDay2 = 18.0;
    const barsSpace = -(widthDay1 + widthDay2) / 2;

    double maxY = 0;
    final barGroups = <BarChartGroupData>[];
    // Per-group metadata for tooltip
    final groupMeta = <(List<ExerciseSet>, List<ExerciseSet>)>[];

    for (var i = 0; i < allWeights.length; i++) {
      final w = allWeights[i];
      final setsD1 = day1ByWeight[w] ?? <ExerciseSet>[];
      final setsD2 = day2ByWeight[w] ?? <ExerciseSet>[];
      groupMeta.add((setsD1, setsD2));

      final totalR1 = setsD1.fold<double>(0, (sum, s) => sum + s.reps);
      final totalR2 = setsD2.fold<double>(0, (sum, s) => sum + s.reps);
      maxY = math.max(maxY, math.max(totalR1, totalR2));

      final alpha1 = _highlightedDayIndex == -1
          ? 0.85
          : _highlightedDayIndex == 0
              ? 1.0
              : 0.2;
      final alpha2 = _highlightedDayIndex == -1
          ? 0.85
          : _highlightedDayIndex == 1
              ? 1.0
              : 0.2;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: barsSpace,
          showingTooltipIndicators: _touchedGroupIdx == i && _touchedRodIdx >= 0
              ? [_touchedRodIdx]
              : [],
          barRods: [
            _buildStackedRod(setsD1, primaryColor, alpha1, widthDay1),
            _buildStackedRod(setsD2, secondaryColor, alpha2, widthDay2),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(primaryColor, _formatDateFull(_comparedDates[0])),
            const SizedBox(width: 16),
            _legendDot(secondaryColor, _formatDateFull(_comparedDates[1])),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.25,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _niceInterval(maxY * 1.25),
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: Colors.white12,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.progressCompareYLabel,
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: _niceInterval(maxY * 1.25),
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.progressCompareXLabel,
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= allWeights.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatWeight(allWeights[idx]),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white54),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      _highlightedDayIndex = -1;
                      _touchedGroupIdx = -1;
                      _touchedRodIdx = -1;
                    } else {
                      final spot = response.spot!;
                      _highlightedDayIndex = spot.touchedRodDataIndex;
                      _touchedGroupIdx = spot.touchedBarGroupIndex;
                      _touchedRodIdx = spot.touchedRodDataIndex;
                    }
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIdx, rod, rodIdx) {
                    if (groupIdx >= groupMeta.length) return null;
                    final (d1Sets, d2Sets) = groupMeta[groupIdx];
                    final sets = rodIdx == 0 ? d1Sets : d2Sets;
                    if (sets.isEmpty) return null;
                    final date = rodIdx == 0
                        ? _formatDate(_comparedDates[0])
                        : _formatDate(_comparedDates[1]);
                    final total = sets.fold<int>(0, (sum, s) => sum + s.reps);
                    if (sets.length == 1) {
                      return BarTooltipItem(
                        '$date\n${sets[0].reps} reps',
                        const TextStyle(fontSize: 11, color: Colors.white),
                      );
                    }
                    final breakdown = sets.map((s) => '${s.reps}').join(' + ');
                    return BarTooltipItem(
                      '$date\n$breakdown = $total reps',
                      const TextStyle(fontSize: 11, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Groups exercise sets by weight value.
  Map<double, List<ExerciseSet>> _groupSetsByWeight(List<ExerciseSet> sets) {
    final map = <double, List<ExerciseSet>>{};
    for (final s in sets) {
      if (s.weight <= 0 && s.reps <= 0) continue;
      map.putIfAbsent(s.weight, () => []).add(s);
    }
    return map;
  }

  /// Builds a stacked bar rod where each set is a segment with a distinct shade.
  BarChartRodData _buildStackedRod(
    List<ExerciseSet> sets,
    Color baseColor,
    double alpha,
    double width,
  ) {
    if (sets.isEmpty) {
      return BarChartRodData(
        toY: 0,
        color: baseColor.withValues(alpha: alpha),
        width: width,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      );
    }

    final totalReps = sets.fold<double>(0, (sum, s) => sum + s.reps);
    final stackItems = <BarChartRodStackItem>[];
    double cumY = 0;

    for (var i = 0; i < sets.length; i++) {
      final reps = sets[i].reps.toDouble();
      // Alternate between full and lighter shade for visual separation
      final segAlpha = alpha * (i.isEven ? 1.0 : 0.65);
      stackItems.add(BarChartRodStackItem(
        cumY,
        cumY + reps,
        baseColor.withValues(alpha: segAlpha),
        const BorderSide(color: Colors.black38, width: 0.5),
      ));
      cumY += reps;
    }

    return BarChartRodData(
      toY: totalReps,
      rodStackItems: stackItems,
      color: baseColor.withValues(alpha: alpha),
      width: width,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    );
  }

  /// Formats weight as a clean string (no trailing zeros).
  String _formatWeight(double w) {
    if (w == w.truncateToDouble()) return w.toInt().toString();
    return w
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _niceInterval(double maxVal) {
    if (maxVal <= 0) return 1;
    final raw = maxVal / 4;
    const steps = [1, 2, 5, 10, 20, 25, 50, 100];
    for (final s in steps) {
      if (s >= raw) return s.toDouble();
    }
    return (raw / 10).ceilToDouble() * 10;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

// ── Day selector widget ──────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.label,
    required this.selected,
    required this.availableDates,
    required this.color,
    required this.formatDate,
    required this.onChanged,
  });

  final String label;
  final DateTime? selected;
  final List<DateTime> availableDates;
  final Color color;
  final String Function(DateTime) formatDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () async {
        final picked = await showModalBottomSheet<DateTime>(
          context: context,
          builder: (ctx) => _DatePickerSheet(
            dates: availableDates,
            selected: selected,
            formatDate: formatDate,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Column(
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          const SizedBox(height: 2),
          Text(
            selected != null ? formatDate(selected!) : '–',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _DatePickerSheet extends StatelessWidget {
  const _DatePickerSheet({
    required this.dates,
    required this.selected,
    required this.formatDate,
  });

  final List<DateTime> dates;
  final DateTime? selected;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dates.length,
              itemBuilder: (ctx, i) {
                final d = dates[i];
                final isSelected = selected != null && _sameDay(d, selected!);
                return ListTile(
                  title: Text(formatDate(d)),
                  trailing:
                      isSelected ? const Icon(Icons.check, size: 20) : null,
                  onTap: () => Navigator.pop(ctx, d),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
