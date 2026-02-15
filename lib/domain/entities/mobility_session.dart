import 'dart:convert';

/// A completed mobility routine session (timer-based).
class MobilitySession {
  const MobilitySession({
    required this.id,
    required this.routineKey,
    required this.date,
    this.startTime,
    this.endTime,
  });

  final String id;
  final String routineKey;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineKey': routineKey,
        'date': '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory MobilitySession.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    return MobilitySession(
      id: json['id'] as String,
      routineKey: json['routineKey'] as String,
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

  static List<MobilitySession> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(MobilitySession.fromJson)
          .toList();

  static String listToJsonString(List<MobilitySession> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());
}
