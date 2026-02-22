import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Optional advanced body measurements in a single screen.
class AdvancedMeasuresScreen extends StatefulWidget {
  const AdvancedMeasuresScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  State<AdvancedMeasuresScreen> createState() => _AdvancedMeasuresScreenState();
}

class _AdvancedMeasuresScreenState extends State<AdvancedMeasuresScreen> {
  late final TextEditingController _bicepsCtrl;
  late final TextEditingController _chestCtrl;
  late final TextEditingController _waistCtrl;
  late final TextEditingController _quadCtrl;
  late final TextEditingController _calfCtrl;

  @override
  void initState() {
    super.initState();
    _bicepsCtrl =
        TextEditingController(text: _str(widget.data['bicepsPerimeterCm']));
    _chestCtrl =
        TextEditingController(text: _str(widget.data['chestPerimeterCm']));
    _waistCtrl =
        TextEditingController(text: _str(widget.data['waistPerimeterCm']));
    _quadCtrl =
        TextEditingController(text: _str(widget.data['quadPerimeterCm']));
    _calfCtrl =
        TextEditingController(text: _str(widget.data['calfPerimeterCm']));
  }

  String _str(dynamic v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    _bicepsCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _quadCtrl.dispose();
    _calfCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.data['bicepsPerimeterCm'] = double.tryParse(_bicepsCtrl.text);
    widget.data['chestPerimeterCm'] = double.tryParse(_chestCtrl.text);
    widget.data['waistPerimeterCm'] = double.tryParse(_waistCtrl.text);
    widget.data['quadPerimeterCm'] = double.tryParse(_quadCtrl.text);
    widget.data['calfPerimeterCm'] = double.tryParse(_calfCtrl.text);
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
            controller: _bicepsCtrl,
            decoration: InputDecoration(
                labelText: l10n.advancedMeasures1BicepsPerimeter),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _chestCtrl,
            decoration: InputDecoration(
                labelText: l10n.advancedMeasures1ChestPerimeter),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _waistCtrl,
            decoration: InputDecoration(
                labelText: l10n.advancedMeasures2WaistPerimeter),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quadCtrl,
            decoration:
                InputDecoration(labelText: l10n.advancedMeasures2QuadPerimeter),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _calfCtrl,
            decoration:
                InputDecoration(labelText: l10n.advancedMeasures2CalfPerimeter),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
