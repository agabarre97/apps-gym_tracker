import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Screen 1 of the onboarding flow — collects birth date, sex, weight, height,
/// and gym experience.
class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  static const _experienceOptions = ['<1', '1-3', '3-5', '>5'];
  static const _sexOptions = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: _str(widget.data['weightKg']));
    _heightCtrl = TextEditingController(text: _str(widget.data['heightCm']));
  }

  String _str(dynamic v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _saveNumericFields() {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    widget.data['weightKg'] = weight;
    widget.data['heightCm'] = height;
    widget.onChanged();
  }

  // ── Date picker ───────────────────────────────────────────────────

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = widget.data['birthDate'] != null
        ? DateTime.tryParse(widget.data['birthDate'] as String) ??
            DateTime(2000, 1, 1)
        : DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
      locale: Localizations.localeOf(context),
    );

    if (picked != null) {
      final iso =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      widget.data['birthDate'] = iso;
      widget.onChanged();
      setState(() {});
    }
  }

  String _formatBirthDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}'; // dd/MM/yyyy
  }

  // ── Validators ────────────────────────────────────────────────────

  String? _validateWeight(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.sharedFieldRequired;
    final n = double.tryParse(v);
    if (n == null || n < 30 || n > 300) {
      return l10n.sharedFieldInvalidRange('30', '300');
    }
    return null;
  }

  String? _validateHeight(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.sharedFieldRequired;
    final n = double.tryParse(v);
    if (n == null || n < 100 || n > 250) {
      return l10n.sharedFieldInvalidRange('100', '250');
    }
    return null;
  }

  // ── Labels ────────────────────────────────────────────────────────

  String _experienceLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case '<1':
        return l10n.basicInfoExpLessThan1;
      case '1-3':
        return l10n.basicInfoExp1to3;
      case '3-5':
        return l10n.basicInfoExp3to5;
      case '>5':
        return l10n.basicInfoExpMoreThan5;
      default:
        return key;
    }
  }

  String _sexLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'male':
        return l10n.basicInfoSexMale;
      case 'female':
        return l10n.basicInfoSexFemale;
      default:
        return key;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedExp = widget.data['gymExperience'] as String?;
    final selectedSex = widget.data['sex'] as String?;
    final birthDate = widget.data['birthDate'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.basicInfoTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),

          // ── Birth date ──
          Text(l10n.basicInfoBirthDate,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: l10n.basicInfoBirthDateHint,
                suffixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                birthDate != null
                    ? _formatBirthDate(birthDate)
                    : l10n.basicInfoBirthDateHint,
                style: TextStyle(
                  color: birthDate != null ? null : Colors.white54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Sex ──
          Text(l10n.basicInfoSex,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _sexOptions.map((key) {
              final isSelected = selectedSex == key;
              return ChoiceChip(
                label: Text(_sexLabel(key, l10n)),
                selected: isSelected,
                onSelected: (_) {
                  widget.data['sex'] = key;
                  widget.onChanged();
                  setState(() {});
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Weight ──
          TextFormField(
            controller: _weightCtrl,
            decoration: InputDecoration(labelText: l10n.basicInfoWeight),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateWeight,
            onChanged: (_) => _saveNumericFields(),
          ),
          const SizedBox(height: 16),

          // ── Height ──
          TextFormField(
            controller: _heightCtrl,
            decoration: InputDecoration(labelText: l10n.basicInfoHeight),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateHeight,
            onChanged: (_) => _saveNumericFields(),
          ),
          const SizedBox(height: 24),

          // ── Gym experience ──
          Text(l10n.basicInfoGymExperience,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _experienceOptions.map((key) {
              final isSelected = selectedExp == key;
              return ChoiceChip(
                label: Text(_experienceLabel(key, l10n)),
                selected: isSelected,
                onSelected: (_) {
                  widget.data['gymExperience'] = key;
                  widget.onChanged();
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
