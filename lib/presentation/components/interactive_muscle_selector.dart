import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MuscleSelectorView { front, back }

class InteractiveMuscleSelector extends StatefulWidget {
  const InteractiveMuscleSelector({
    super.key,
    required this.selectedMuscles,
    required this.onChanged,
    this.availableMuscles = _defaultMuscles,
    this.frontLabel = 'Front',
    this.backLabel = 'Back',
    this.manualAddLabel = 'Add muscle manually',
    this.selectorTitle = 'Select muscles from the selector',
    this.labelBuilder,
    this.height = 420,
  });

  final List<String> selectedMuscles;
  final ValueChanged<List<String>> onChanged;
  final List<String> availableMuscles;
  final String frontLabel;
  final String backLabel;
  final String manualAddLabel;
  final String selectorTitle;
  final String Function(String muscle)? labelBuilder;
  final double height;

  static const List<String> _defaultMuscles = <String>[
    'abdominals',
    'biceps',
    'calves',
    'chest',
    'forearms',
    'front-shoulders',
    'glutes',
    'hamstrings',
    'lats',
    'lowerback',
    'quads',
    'rear-shoulders',
    'traps',
    'triceps',
  ];

  @override
  State<InteractiveMuscleSelector> createState() =>
      _InteractiveMuscleSelectorState();
}

class _InteractiveMuscleSelectorState extends State<InteractiveMuscleSelector> {
  static Future<_SvgTemplates>? _templatesFuture;
  final Set<String> _selected = <String>{};
  MuscleSelectorView _view = MuscleSelectorView.front;

  static Future<_SvgTemplates> _loadTemplates() {
    return _templatesFuture ??= () async {
      final front = await rootBundle
          .loadString('assets/data/musclewiki/svg_templates/front.svg');
      final back = await rootBundle
          .loadString('assets/data/musclewiki/svg_templates/back.svg');
      return _SvgTemplates(front: front, back: back);
    }();
  }

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.selectedMuscles);
  }

  @override
  void didUpdateWidget(covariant InteractiveMuscleSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSet = oldWidget.selectedMuscles.toSet();
    final newSet = widget.selectedMuscles.toSet();
    if (oldSet.length != newSet.length || !oldSet.containsAll(newSet)) {
      _selected
        ..clear()
        ..addAll(widget.selectedMuscles);
    }
  }

  void _toggleMuscle(String muscleId) {
    setState(() {
      if (_selected.contains(muscleId)) {
        _selected.remove(muscleId);
      } else {
        _selected.add(muscleId);
      }
    });
    widget.onChanged(_selected.toList(growable: false));
  }

  void _addMuscleFromFallback(String? value) {
    if (value == null || _selected.contains(value)) return;
    setState(() => _selected.add(value));
    widget.onChanged(_selected.toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final selectedSet = _selected.toSet();
    final highlightedSet = _view == MuscleSelectorView.front
        ? selectedSet.where((muscle) => muscle != 'calves').toSet()
        : selectedSet;
    final availableUnselected = widget.availableMuscles
        .where((muscle) => !_selected.contains(muscle))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.selectorTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<MuscleSelectorView>(
          segments: [
            ButtonSegment(
              value: MuscleSelectorView.front,
              label: Text(widget.frontLabel),
              icon: const Icon(Icons.accessibility_new),
            ),
            ButtonSegment(
              value: MuscleSelectorView.back,
              label: Text(widget.backLabel),
              icon: const Icon(Icons.accessibility),
            ),
          ],
          selected: <MuscleSelectorView>{_view},
          onSelectionChanged: (selection) {
            final selectedView = selection.firstOrNull;
            if (selectedView == null) return;
            setState(() => _view = selectedView);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('muscle-dropdown-${_selected.length}'),
          value: null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.manualAddLabel,
          ),
          items: availableUnselected
              .map(
                (muscle) => DropdownMenuItem<String>(
                  value: muscle,
                  child: Text(_displayLabel(muscle)),
                ),
              )
              .toList(growable: false),
          onChanged:
              availableUnselected.isEmpty ? null : _addMuscleFromFallback,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: FutureBuilder<_SvgTemplates>(
            future: _loadTemplates(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rawSvg = _view == MuscleSelectorView.front
                  ? snapshot.data!.front
                  : snapshot.data!.back;
              final svg = _applyHighlight(rawSvg, highlightedSet);

              return IgnorePointer(
                child: SvgPicture.string(
                  svg,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selected
              .map(
                (muscle) => InputChip(
                  label: Text(_displayLabel(muscle)),
                  onDeleted: () => _toggleMuscle(muscle),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String _labelForMuscle(String muscle) {
    return muscle
        .split('-')
        .map((part) => part.isEmpty
            ? part
            : '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _displayLabel(String muscle) {
    final custom = widget.labelBuilder?.call(muscle);
    if (custom != null && custom.isNotEmpty) return custom;
    return _labelForMuscle(muscle);
  }
}

class _SvgTemplates {
  const _SvgTemplates({
    required this.front,
    required this.back,
  });

  final String front;
  final String back;
}

String _applyHighlight(String templateSvg, Set<String> highlightedIds) {
  const highlightColor = '#448AFF';
  const neutralColor = '#9CA3AF';

  var result = templateSvg.replaceAll(
    RegExp(r'<style\b[^>]*>.*?</style>', dotAll: true),
    '',
  );

  result = result.replaceAll('fill="currentColor"', 'fill="$neutralColor"');
  for (final muscleId in highlightedIds) {
    result =
        _recolorMuscleBlock(result, muscleId, highlightColor, neutralColor);
  }
  return result;
}

String _recolorMuscleBlock(
  String svg,
  String muscleId,
  String targetColor,
  String currentNeutral,
) {
  final idAttr = 'id="$muscleId"';
  final idPos = svg.indexOf(idAttr);
  if (idPos == -1) return svg;

  final gStart = svg.lastIndexOf('<g', idPos);
  if (gStart == -1) return svg;

  final openTagEnd = svg.indexOf('>', gStart);
  if (openTagEnd == -1) return svg;

  if (!svg.substring(gStart, openTagEnd + 1).contains('bodymap')) return svg;

  final closeTagPos = svg.indexOf('</g>', openTagEnd + 1);
  if (closeTagPos == -1) return svg;

  final inner = svg.substring(openTagEnd + 1, closeTagPos);
  final replaced = inner.replaceAll(
    'fill="$currentNeutral"',
    'fill="$targetColor"',
  );
  return svg.substring(0, openTagEnd + 1) +
      replaced +
      svg.substring(closeTagPos);
}
