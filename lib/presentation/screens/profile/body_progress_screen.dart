import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/measurement_record.dart';
import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/measurement_record_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/profile/add_measurement_screen.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

enum BodyMetric {
  weightKg,
  bicepsPerimeterCm,
  chestPerimeterCm,
  waistPerimeterCm,
  quadPerimeterCm,
  calfPerimeterCm,
}

class _BodyPoint {
  const _BodyPoint(this.date, this.value);
  final DateTime date;
  final double value;
}

enum _BodyPeriodUnit { days, months, years }

/// Shows historical body-measurement trends with a chart and timeline.
class BodyProgressScreen extends StatefulWidget {
  const BodyProgressScreen({
    super.key,
    required this.measurementRecordPort,
    required this.profilePort,
    required this.profile,
  });

  final MeasurementRecordPort measurementRecordPort;
  final ProfilePort profilePort;
  final UserProfile profile;

  @override
  State<BodyProgressScreen> createState() => _BodyProgressScreenState();
}

class _BodyProgressScreenState extends State<BodyProgressScreen> {
  static const int _customPeriodSentinel = -1;

  List<MeasurementRecord>? _records;
  UserProfile _profile = const UserProfile(
    birthDate: '',
    sex: '',
    weightKg: 0,
    heightCm: 0,
    gymExperience: '',
    weightGoal: 'maintain',
  );
  int _periodMonths = 3;
  int _customPeriodValue = 30;
  _BodyPeriodUnit _customPeriodUnit = _BodyPeriodUnit.days;
  bool _hasCustomPeriod = false;
  BodyMetric _metric = BodyMetric.weightKg;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await widget.measurementRecordPort.loadRecords();
    records.sort((a, b) => a.date.compareTo(b.date));
    if (!mounted) return;
    setState(() => _records = records);
  }

  Future<void> _addRecord() async {
    final latest =
        _records != null && _records!.isNotEmpty ? _records!.last : null;
    final created = await Navigator.of(context).push<MeasurementRecord>(
      MaterialPageRoute(
        builder: (_) => AddMeasurementScreen(
          profile: _profile,
          latestRecord: latest,
        ),
      ),
    );
    if (created == null) return;

    await widget.measurementRecordPort.addRecord(created);
    final updatedProfile = _profileFromRecord(_profile, created);
    await widget.profilePort.saveProfile(updatedProfile);

    if (!mounted) return;
    setState(() {
      _profile = updatedProfile;
      _records = [...?_records, created]
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  UserProfile _profileFromRecord(
      UserProfile profile, MeasurementRecord record) {
    return UserProfile(
      birthDate: profile.birthDate,
      sex: profile.sex,
      weightKg: record.weightKg ?? profile.weightKg,
      heightCm: profile.heightCm,
      gymExperience: profile.gymExperience,
      armSpanCm: profile.armSpanCm,
      bicepsPerimeterCm: record.bicepsPerimeterCm ?? profile.bicepsPerimeterCm,
      chestPerimeterCm: record.chestPerimeterCm ?? profile.chestPerimeterCm,
      waistPerimeterCm: record.waistPerimeterCm ?? profile.waistPerimeterCm,
      quadPerimeterCm: record.quadPerimeterCm ?? profile.quadPerimeterCm,
      calfPerimeterCm: record.calfPerimeterCm ?? profile.calfPerimeterCm,
      weightGoal: profile.weightGoal,
      targetWeightKg: profile.targetWeightKg,
      kcalPerDay: profile.kcalPerDay,
    );
  }

  List<_BodyPoint> _pointsForMetric() {
    if (_records == null) return [];
    final threshold = _cutoffDate();
    final points = <_BodyPoint>[];

    for (final record in _records!) {
      if (record.date.isBefore(threshold)) continue;
      final value = _metricValue(record, _metric);
      if (value == null) continue;
      points.add(_BodyPoint(record.date, value));
    }

    return points;
  }

  DateTime _cutoffDate() {
    final now = DateTime.now();
    if (_periodMonths != _customPeriodSentinel) {
      return DateTime(now.year, now.month - _periodMonths, now.day);
    }
    switch (_customPeriodUnit) {
      case _BodyPeriodUnit.days:
        return now.subtract(Duration(days: _customPeriodValue));
      case _BodyPeriodUnit.months:
        return DateTime(now.year, now.month - _customPeriodValue, now.day);
      case _BodyPeriodUnit.years:
        return DateTime(now.year - _customPeriodValue, now.month, now.day);
    }
  }

  double? _metricValue(MeasurementRecord record, BodyMetric metric) {
    switch (metric) {
      case BodyMetric.weightKg:
        return record.weightKg;
      case BodyMetric.bicepsPerimeterCm:
        return record.bicepsPerimeterCm;
      case BodyMetric.chestPerimeterCm:
        return record.chestPerimeterCm;
      case BodyMetric.waistPerimeterCm:
        return record.waistPerimeterCm;
      case BodyMetric.quadPerimeterCm:
        return record.quadPerimeterCm;
      case BodyMetric.calfPerimeterCm:
        return record.calfPerimeterCm;
    }
  }

  String _metricLabel(AppLocalizations l10n, BodyMetric metric) {
    switch (metric) {
      case BodyMetric.weightKg:
        return l10n.basicInfoWeight;
      case BodyMetric.bicepsPerimeterCm:
        return l10n.advancedMeasures1BicepsPerimeter;
      case BodyMetric.chestPerimeterCm:
        return l10n.advancedMeasures1ChestPerimeter;
      case BodyMetric.waistPerimeterCm:
        return l10n.advancedMeasures2WaistPerimeter;
      case BodyMetric.quadPerimeterCm:
        return l10n.advancedMeasures2QuadPerimeter;
      case BodyMetric.calfPerimeterCm:
        return l10n.advancedMeasures2CalfPerimeter;
    }
  }

  String _periodLabel(AppLocalizations l10n, int months) {
    if (months == _customPeriodSentinel) {
      if (!_hasCustomPeriod) {
        return Localizations.localeOf(context).languageCode == 'es'
            ? 'Periodo personalizado'
            : 'Custom period';
      }
      return _customPeriodLabel(l10n);
    }
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

  String _customPeriodLabel(AppLocalizations l10n) {
    final unit = switch (_customPeriodUnit) {
      _BodyPeriodUnit.days => 'd',
      _BodyPeriodUnit.months =>
        l10n.progressPeriod1m.contains('mes') ? 'mes' : 'm',
      _BodyPeriodUnit.years => l10n.progressPeriod12m.contains('a') ? 'a' : 'y',
    };
    return '$_customPeriodValue $unit';
  }

  Future<void> _pickCustomPeriod(AppLocalizations l10n) async {
    final valueCtrl =
        TextEditingController(text: _customPeriodValue.toString());
    var selected = _customPeriodUnit;
    final result = await showDialog<({int value, _BodyPeriodUnit unit})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${l10n.progressTitle} · ${l10n.sharedConfirm}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_BodyPeriodUnit>(
                initialValue: selected,
                items: const [
                  DropdownMenuItem(
                      value: _BodyPeriodUnit.days, child: Text('Dias')),
                  DropdownMenuItem(
                      value: _BodyPeriodUnit.months, child: Text('Meses')),
                  DropdownMenuItem(
                      value: _BodyPeriodUnit.years, child: Text('Anios')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selected = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.sharedCancel),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(valueCtrl.text.trim());
                if (parsed == null || parsed <= 0) return;
                Navigator.of(ctx).pop((value: parsed, unit: selected));
              },
              child: Text(l10n.sharedSave),
            ),
          ],
        ),
      ),
    );
    valueCtrl.dispose();
    if (result == null) return;
    setState(() {
      _customPeriodValue = result.value;
      _customPeriodUnit = result.unit;
      _hasCustomPeriod = true;
      _periodMonths = _customPeriodSentinel;
    });
  }

  String _goalLabel(AppLocalizations l10n, String goal) {
    switch (goal) {
      case 'gain':
        return l10n.sharedGain;
      case 'lose':
        return l10n.sharedLose;
      default:
        return l10n.sharedMaintain;
    }
  }

  Color _goalColor(String goal) {
    switch (goal) {
      case 'gain':
        return Colors.greenAccent.withValues(alpha: 0.12);
      case 'lose':
        return Colors.orangeAccent.withValues(alpha: 0.12);
      default:
        return Colors.lightBlueAccent.withValues(alpha: 0.12);
    }
  }

  List<(String goal, int from, int to)> _goalBands(List<_BodyPoint> points) {
    if (points.isEmpty) return const [];
    final phases = List<GoalPhase>.from(_profile.goalHistory)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    String goalAt(DateTime date) {
      String current = _profile.weightGoal;
      for (final phase in phases) {
        final start = DateTime.tryParse(phase.startDate);
        if (start == null) continue;
        if (!start.isAfter(date)) {
          current = phase.weightGoal;
        }
      }
      return current;
    }

    final pointGoals = points.map((p) => goalAt(p.date)).toList();
    final bands = <(String goal, int from, int to)>[];
    var start = 0;
    var currentGoal = pointGoals.first;
    for (var i = 1; i < pointGoals.length; i++) {
      if (pointGoals[i] != currentGoal) {
        bands.add((currentGoal, start, i - 1));
        start = i;
        currentGoal = pointGoals[i];
      }
    }
    bands.add((currentGoal, start, pointGoals.length - 1));
    return bands;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _formatDateFull(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double _yInterval(List<_BodyPoint> points) {
    if (points.length < 2) return 1;
    final values = points.map((p) => p.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs();
    if (range <= 0) return 1;
    final rough = range / 4;
    if (rough <= 0.25) return 0.25;
    if (rough <= 0.5) return 0.5;
    if (rough <= 1) return 1;
    if (rough <= 2) return 2;
    if (rough <= 5) return 5;
    if (rough <= 10) return 10;
    final magnitude =
        math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    return (rough / magnitude).ceil() * magnitude;
  }

  double _xInterval(int pointsCount) {
    if (pointsCount <= 1) return 1;
    if (pointsCount <= 6) return 1;
    if (pointsCount <= 12) return 2;
    if (pointsCount <= 24) return 4;
    return (pointsCount / 6).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = _pointsForMetric();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progressTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
      body: _records == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 3, 6, 12, _customPeriodSentinel].map((period) {
                    return ChoiceChip(
                      label: Text(_periodLabel(l10n, period)),
                      selected: _periodMonths == period,
                      onSelected: (_) {
                        if (period == _customPeriodSentinel) {
                          _pickCustomPeriod(l10n);
                          return;
                        }
                        setState(() => _periodMonths = period);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BodyMetric>(
                  initialValue: _metric,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: BodyMetric.values
                      .map(
                        (metric) => DropdownMenuItem<BodyMetric>(
                          value: metric,
                          child: Text(_metricLabel(l10n, metric)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _metric = value);
                  },
                ),
                const SizedBox(height: 16),
                if (points.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        l10n.progressNoData,
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  )
                else ...[
                  _ProgressChart(
                    points: points,
                    formatDate: _formatDate,
                    formatValue: _formatValue,
                    xInterval: _xInterval(points.length),
                    yInterval: _yInterval(points),
                    goalBands: _goalBands(points),
                    goalColor: _goalColor,
                  ),
                  const SizedBox(height: 10),
                  _GoalLegend(
                    goals: _goalBands(points).map((b) => b.$1).toSet().toList(),
                    goalLabel: (goal) => _goalLabel(l10n, goal),
                    goalColor: _goalColor,
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    points: points,
                    formatValue: _formatValue,
                    formatDate: _formatDateFull,
                    l10n: l10n,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  _metricLabel(l10n, _metric),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...points.reversed.map((point) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.show_chart),
                      title: Text(_formatValue(point.value)),
                      subtitle: Text(_formatDateFull(point.date)),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.points,
    required this.formatValue,
    required this.formatDate,
    required this.l10n,
  });

  final List<_BodyPoint> points;
  final String Function(double value) formatValue;
  final String Function(DateTime date) formatDate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final first = points.first;
    final last = points.last;
    final minPoint = points.reduce((a, b) => a.value <= b.value ? a : b);
    final maxPoint = points.reduce((a, b) => a.value >= b.value ? a : b);
    final delta = last.value - first.value;
    final trendColor = delta > 0
        ? Colors.greenAccent
        : (delta < 0 ? Colors.redAccent : context.textSecondary);
    final trendIcon = delta > 0
        ? Icons.trending_up
        : (delta < 0 ? Icons.trending_down : Icons.trending_flat);
    final deltaPrefix = delta > 0 ? '+' : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(
              label: l10n.progressFirstRecord,
              value: '${formatValue(first.value)} · ${formatDate(first.date)}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: l10n.progressLastRecord,
              value: '${formatValue(last.value)} · ${formatDate(last.date)}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: l10n.progressMinValue,
              value:
                  '${formatValue(minPoint.value)} · ${formatDate(minPoint.date)}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: l10n.progressMaxValue,
              value:
                  '${formatValue(maxPoint.value)} · ${formatDate(maxPoint.date)}',
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Δ $deltaPrefix${formatValue(delta)}',
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatDate(first.date)} → ${formatDate(last.date)}',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _GoalLegend extends StatelessWidget {
  const _GoalLegend({
    required this.goals,
    required this.goalLabel,
    required this.goalColor,
  });

  final List<String> goals;
  final String Function(String goal) goalLabel;
  final Color Function(String goal) goalColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: goals.map((goal) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: goalColor(goal),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              goalLabel(goal),
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({
    required this.points,
    required this.formatDate,
    required this.formatValue,
    required this.xInterval,
    required this.yInterval,
    required this.goalBands,
    required this.goalColor,
  });

  final List<_BodyPoint> points;
  final String Function(DateTime date) formatDate;
  final String Function(double value) formatValue;
  final double xInterval;
  final double yInterval;
  final List<(String goal, int from, int to)> goalBands;
  final Color Function(String goal) goalColor;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final dateLabels = <int, String>{};
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
      dateLabels[i] = formatDate(points[i].date);
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: goalBands
                .map(
                  (band) => VerticalRangeAnnotation(
                    x1: math.max(0, band.$2 - 0.5),
                    x2: band.$3 + 0.5,
                    color: goalColor(band.$1),
                  ),
                )
                .toList(),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
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
                interval: yInterval,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatValue(value),
                    style:
                        TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: xInterval,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateLabels[idx] ?? '',
                      style:
                          TextStyle(fontSize: 9, color: context.textSecondary),
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
              getTooltipItems: (items) => items
                  .map(
                    (item) => LineTooltipItem(
                      '${formatDate(points[item.spotIndex].date)}\n${formatValue(item.y)}',
                      const TextStyle(color: Colors.white),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
