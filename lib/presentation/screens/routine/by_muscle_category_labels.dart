const List<String> byMuscleCategoryOrder = [
  'biceps',
  'calves',
  'chest',
  'forearms',
  'front-shoulders',
  'glutes',
  'hamstrings',
  'lats',
  'quads',
  'rear-shoulders',
  'triceps',
];

const Map<String, String> _categoryLabelEs = {
  'calves': 'Gemelos',
  'chest': 'Pecho',
  'front-shoulders': 'Hombro frontal',
  'rear-shoulders': 'Hombro posterior',
  'triceps': 'Triceps',
  'biceps': 'Biceps',
  'forearms': 'Antebrazos',
  'lats': 'Dorsales',
  'quads': 'Cuadriceps',
  'hamstrings': 'Isquiotibiales',
  'glutes': 'Gluteos',
};

const Map<String, String> _categoryLabelEn = {
  'calves': 'Calves',
  'chest': 'Chest',
  'front-shoulders': 'Front Shoulders',
  'rear-shoulders': 'Rear Shoulders',
  'triceps': 'Triceps',
  'biceps': 'Biceps',
  'forearms': 'Forearms',
  'lats': 'Lats',
  'quads': 'Quads',
  'hamstrings': 'Hamstrings',
  'glutes': 'Glutes',
};

String categoryLabelForLocale(String categoryKey, String languageCode) {
  final map = languageCode == 'en' ? _categoryLabelEn : _categoryLabelEs;
  return map[categoryKey] ?? _humanizeCategoryKey(categoryKey);
}

String _humanizeCategoryKey(String value) {
  if (value.isEmpty) return value;
  final parts = value.split(RegExp(r'[-_\s]+'));
  return parts
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
