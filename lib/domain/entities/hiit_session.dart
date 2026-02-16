import 'dart:convert';

/// A completed HIIT routine session.
class HiitSession {
  const HiitSession({
    required this.id,
    required this.routineName,
    required this.date,
    this.startTime,
    this.endTime,
  });

  final String id;
  final String routineName;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineName': routineName,
        'date': '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory HiitSession.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    return HiitSession(
      id: json['id'] as String,
      routineName: json['routineName'] as String,
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static List<HiitSession> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(HiitSession.fromJson)
          .toList();

  static String listToJsonString(List<HiitSession> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());
}
