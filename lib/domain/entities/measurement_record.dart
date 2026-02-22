import 'dart:convert';

/// Snapshot of body measurements for a specific calendar day.
class MeasurementRecord {
  const MeasurementRecord({
    required this.id,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.armSpanCm,
    this.bicepsPerimeterCm,
    this.chestPerimeterCm,
    this.waistPerimeterCm,
    this.quadPerimeterCm,
    this.calfPerimeterCm,
  });

  final String id;
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? armSpanCm;
  final double? bicepsPerimeterCm;
  final double? chestPerimeterCm;
  final double? waistPerimeterCm;
  final double? quadPerimeterCm;
  final double? calfPerimeterCm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
        'weightKg': weightKg,
        'heightCm': heightCm,
        'armSpanCm': armSpanCm,
        'bicepsPerimeterCm': bicepsPerimeterCm,
        'chestPerimeterCm': chestPerimeterCm,
        'waistPerimeterCm': waistPerimeterCm,
        'quadPerimeterCm': quadPerimeterCm,
        'calfPerimeterCm': calfPerimeterCm,
      };

  factory MeasurementRecord.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    return MeasurementRecord(
      id: json['id'] as String,
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      armSpanCm: (json['armSpanCm'] as num?)?.toDouble(),
      bicepsPerimeterCm: (json['bicepsPerimeterCm'] as num?)?.toDouble(),
      chestPerimeterCm: (json['chestPerimeterCm'] as num?)?.toDouble(),
      waistPerimeterCm: (json['waistPerimeterCm'] as num?)?.toDouble(),
      quadPerimeterCm: (json['quadPerimeterCm'] as num?)?.toDouble(),
      calfPerimeterCm: (json['calfPerimeterCm'] as num?)?.toDouble(),
    );
  }

  MeasurementRecord copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? armSpanCm,
    double? bicepsPerimeterCm,
    double? chestPerimeterCm,
    double? waistPerimeterCm,
    double? quadPerimeterCm,
    double? calfPerimeterCm,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
    bool clearArmSpanCm = false,
    bool clearBicepsPerimeterCm = false,
    bool clearChestPerimeterCm = false,
    bool clearWaistPerimeterCm = false,
    bool clearQuadPerimeterCm = false,
    bool clearCalfPerimeterCm = false,
  }) =>
      MeasurementRecord(
        id: id ?? this.id,
        date: date ?? this.date,
        weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
        heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
        armSpanCm: clearArmSpanCm ? null : (armSpanCm ?? this.armSpanCm),
        bicepsPerimeterCm: clearBicepsPerimeterCm
            ? null
            : (bicepsPerimeterCm ?? this.bicepsPerimeterCm),
        chestPerimeterCm: clearChestPerimeterCm
            ? null
            : (chestPerimeterCm ?? this.chestPerimeterCm),
        waistPerimeterCm: clearWaistPerimeterCm
            ? null
            : (waistPerimeterCm ?? this.waistPerimeterCm),
        quadPerimeterCm: clearQuadPerimeterCm
            ? null
            : (quadPerimeterCm ?? this.quadPerimeterCm),
        calfPerimeterCm: clearCalfPerimeterCm
            ? null
            : (calfPerimeterCm ?? this.calfPerimeterCm),
      );

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static List<MeasurementRecord> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(MeasurementRecord.fromJson)
          .toList();

  static String listToJsonString(List<MeasurementRecord> list) =>
      jsonEncode(list.map((record) => record.toJson()).toList());
}
