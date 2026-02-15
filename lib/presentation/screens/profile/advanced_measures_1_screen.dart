import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Screen 2 — optional upper-body measurements.
class AdvancedMeasures1Screen extends StatefulWidget {
  const AdvancedMeasures1Screen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  State<AdvancedMeasures1Screen> createState() =>
      _AdvancedMeasures1ScreenState();
}

class _AdvancedMeasures1ScreenState extends State<AdvancedMeasures1Screen> {
  late final TextEditingController _armSpanCtrl;
  late final TextEditingController _bicepsCtrl;
  late final TextEditingController _chestCtrl;

  @override
  void initState() {
    super.initState();
    _armSpanCtrl =
        TextEditingController(text: _str(widget.data['armSpanCm']));
    _bicepsCtrl =
        TextEditingController(text: _str(widget.data['bicepsPerimeterCm']));
    _chestCtrl =
        TextEditingController(text: _str(widget.data['chestPerimeterCm']));
  }

  String _str(dynamic v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    _armSpanCtrl.dispose();
    _bicepsCtrl.dispose();
    _chestCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['armSpanCm'] = double.tryParse(_armSpanCtrl.text);
    widget.data['bicepsPerimeterCm'] = double.tryParse(_bicepsCtrl.text);
    widget.data['chestPerimeterCm'] = double.tryParse(_chestCtrl.text);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.advancedMeasures1Title,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextFormField(
            controller: _armSpanCtrl,
            decoration:
                InputDecoration(labelText: l10n.advancedMeasures1ArmSpan),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bicepsCtrl,
            decoration: InputDecoration(
                labelText: l10n.advancedMeasures1BicepsPerimeter),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _chestCtrl,
            decoration: InputDecoration(
                labelText: l10n.advancedMeasures1ChestPerimeter),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
