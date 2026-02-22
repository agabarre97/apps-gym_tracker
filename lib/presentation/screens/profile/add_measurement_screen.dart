import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/measurement_record.dart';
import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Form to register a new body-measurement snapshot.
class AddMeasurementScreen extends StatefulWidget {
  const AddMeasurementScreen({
    super.key,
    required this.profile,
    this.latestRecord,
  });

  final UserProfile profile;
  final MeasurementRecord? latestRecord;

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  late DateTime _selectedDate;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _bicepsCtrl;
  late final TextEditingController _chestCtrl;
  late final TextEditingController _waistCtrl;
  late final TextEditingController _quadCtrl;
  late final TextEditingController _calfCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    final seed = widget.latestRecord;

    _weightCtrl = TextEditingController(
      text: _asText(seed?.weightKg ?? widget.profile.weightKg),
    );
    _bicepsCtrl = TextEditingController(
      text:
          _asText(seed?.bicepsPerimeterCm ?? widget.profile.bicepsPerimeterCm),
    );
    _chestCtrl = TextEditingController(
      text: _asText(seed?.chestPerimeterCm ?? widget.profile.chestPerimeterCm),
    );
    _waistCtrl = TextEditingController(
      text: _asText(seed?.waistPerimeterCm ?? widget.profile.waistPerimeterCm),
    );
    _quadCtrl = TextEditingController(
      text: _asText(seed?.quadPerimeterCm ?? widget.profile.quadPerimeterCm),
    );
    _calfCtrl = TextEditingController(
      text: _asText(seed?.calfPerimeterCm ?? widget.profile.calfPerimeterCm),
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bicepsCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _quadCtrl.dispose();
    _calfCtrl.dispose();
    super.dispose();
  }

  String _asText(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  double? _toDouble(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  bool get _hasAnyValue {
    final values = <double?>[
      _toDouble(_weightCtrl),
      _toDouble(_bicepsCtrl),
      _toDouble(_chestCtrl),
      _toDouble(_waistCtrl),
      _toDouble(_quadCtrl),
      _toDouble(_calfCtrl),
    ];
    return values.any((v) => v != null);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _save() {
    final record = MeasurementRecord(
      id: const Uuid().v4(),
      date: _selectedDate,
      weightKg: _toDouble(_weightCtrl),
      bicepsPerimeterCm: _toDouble(_bicepsCtrl),
      chestPerimeterCm: _toDouble(_chestCtrl),
      waistPerimeterCm: _toDouble(_waistCtrl),
      quadPerimeterCm: _toDouble(_quadCtrl),
      calfPerimeterCm: _toDouble(_calfCtrl),
    );
    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progressTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_formatDate(_selectedDate)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 16),
          _NumberField(label: l10n.basicInfoWeight, controller: _weightCtrl),
          const SizedBox(height: 12),
          _NumberField(
            label: l10n.advancedMeasures1BicepsPerimeter,
            controller: _bicepsCtrl,
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: l10n.advancedMeasures1ChestPerimeter,
            controller: _chestCtrl,
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: l10n.advancedMeasures2WaistPerimeter,
            controller: _waistCtrl,
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: l10n.advancedMeasures2QuadPerimeter,
            controller: _quadCtrl,
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: l10n.advancedMeasures2CalfPerimeter,
            controller: _calfCtrl,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _hasAnyValue ? _save : null,
            child: Text(l10n.sharedSave),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}
