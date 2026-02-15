import 'dart:convert';

/// Represents a single day the user trained.
class TrainingDay {
  const TrainingDay({required this.date});

  /// Stored as yyyy-MM-dd string internally.
  final DateTime date;

  String get key => '${date.year}-${_pad(date.month)}-${_pad(date.day)}';

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static TrainingDay fromKey(String key) {
    final parts = key.split('-');
    return TrainingDay(
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
    );
  }

  static List<TrainingDay> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<String>()
          .map(TrainingDay.fromKey)
          .toList();

  static String listToJsonString(List<TrainingDay> list) =>
      jsonEncode(list.map((d) => d.key).toList());
}
