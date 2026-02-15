import 'dart:convert';

/// Domain entity representing a user's gym profile.
class UserProfile {
  const UserProfile({
    required this.birthDate,
    required this.sex,
    required this.weightKg,
    required this.heightCm,
    required this.gymExperience,
    this.armSpanCm,
    this.bicepsPerimeterCm,
    this.chestPerimeterCm,
    this.waistPerimeterCm,
    this.quadPerimeterCm,
    this.calfPerimeterCm,
    required this.weightGoal,
    this.targetWeightKg,
    this.kcalPerDay,
  });

  /// Date of birth in ISO format (yyyy-MM-dd).
  final String birthDate;

  /// Biological sex: 'male' | 'female'.
  final String sex;

  final double weightKg;
  final double heightCm;
  final String gymExperience; // '<1', '1-3', '3-5', '>5'
  final double? armSpanCm;
  final double? bicepsPerimeterCm;
  final double? chestPerimeterCm;
  final double? waistPerimeterCm;
  final double? quadPerimeterCm;
  final double? calfPerimeterCm;
  final String weightGoal; // 'gain' | 'lose' | 'maintain'
  final double? targetWeightKg;
  final int? kcalPerDay;

  /// Serialize to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'birthDate': birthDate,
        'sex': sex,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'gymExperience': gymExperience,
        'armSpanCm': armSpanCm,
        'bicepsPerimeterCm': bicepsPerimeterCm,
        'chestPerimeterCm': chestPerimeterCm,
        'waistPerimeterCm': waistPerimeterCm,
        'quadPerimeterCm': quadPerimeterCm,
        'calfPerimeterCm': calfPerimeterCm,
        'weightGoal': weightGoal,
        'targetWeightKg': targetWeightKg,
        'kcalPerDay': kcalPerDay,
      };

  /// Deserialize from a JSON-compatible map.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        birthDate: json['birthDate'] as String,
        sex: json['sex'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        heightCm: (json['heightCm'] as num).toDouble(),
        gymExperience: json['gymExperience'] as String,
        armSpanCm: (json['armSpanCm'] as num?)?.toDouble(),
        bicepsPerimeterCm: (json['bicepsPerimeterCm'] as num?)?.toDouble(),
        chestPerimeterCm: (json['chestPerimeterCm'] as num?)?.toDouble(),
        waistPerimeterCm: (json['waistPerimeterCm'] as num?)?.toDouble(),
        quadPerimeterCm: (json['quadPerimeterCm'] as num?)?.toDouble(),
        calfPerimeterCm: (json['calfPerimeterCm'] as num?)?.toDouble(),
        weightGoal: json['weightGoal'] as String,
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
        kcalPerDay: json['kcalPerDay'] as int?,
      );

  /// Convenience: serialize to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Convenience: deserialize from a JSON string.
  factory UserProfile.fromJsonString(String source) =>
      UserProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
