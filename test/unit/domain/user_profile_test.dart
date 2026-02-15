import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('toJson() produces a valid map with all required fields', () {
      const profile = UserProfile(
        birthDate: '1996-05-20',
        sex: 'male',
        weightKg: 85.5,
        heightCm: 175.0,
        gymExperience: '3-5',
        weightGoal: 'gain',
        targetWeightKg: 90.0,
        kcalPerDay: 3000,
      );

      final json = profile.toJson();

      expect(json['birthDate'], '1996-05-20');
      expect(json['sex'], 'male');
      expect(json['weightKg'], 85.5);
      expect(json['heightCm'], 175.0);
      expect(json['gymExperience'], '3-5');
      expect(json['weightGoal'], 'gain');
      expect(json['targetWeightKg'], 90.0);
      expect(json['kcalPerDay'], 3000);
      // Optional fields should be null when not provided
      expect(json['armSpanCm'], isNull);
      expect(json['bicepsPerimeterCm'], isNull);
      expect(json['chestPerimeterCm'], isNull);
      expect(json['waistPerimeterCm'], isNull);
      expect(json['quadPerimeterCm'], isNull);
      expect(json['calfPerimeterCm'], isNull);
    });

    test('toJson() includes optional fields when provided', () {
      const profile = UserProfile(
        birthDate: '2001-03-15',
        sex: 'female',
        weightKg: 80.0,
        heightCm: 180.0,
        gymExperience: '1-3',
        armSpanCm: 182.0,
        bicepsPerimeterCm: 35.0,
        chestPerimeterCm: 100.0,
        waistPerimeterCm: 80.0,
        quadPerimeterCm: 55.0,
        calfPerimeterCm: 38.0,
        weightGoal: 'lose',
        targetWeightKg: 75.0,
        kcalPerDay: 2000,
      );

      final json = profile.toJson();

      expect(json['armSpanCm'], 182.0);
      expect(json['bicepsPerimeterCm'], 35.0);
      expect(json['chestPerimeterCm'], 100.0);
      expect(json['waistPerimeterCm'], 80.0);
      expect(json['quadPerimeterCm'], 55.0);
      expect(json['calfPerimeterCm'], 38.0);
    });

    test('fromJson() correctly deserializes all fields', () {
      final json = {
        'birthDate': '1998-07-12',
        'sex': 'female',
        'weightKg': 72.3,
        'heightCm': 168.0,
        'gymExperience': '<1',
        'armSpanCm': null,
        'bicepsPerimeterCm': null,
        'chestPerimeterCm': 95.0,
        'waistPerimeterCm': null,
        'quadPerimeterCm': 50.0,
        'calfPerimeterCm': null,
        'weightGoal': 'lose',
        'targetWeightKg': 65.0,
        'kcalPerDay': 1800,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.birthDate, '1998-07-12');
      expect(profile.sex, 'female');
      expect(profile.weightKg, 72.3);
      expect(profile.heightCm, 168.0);
      expect(profile.gymExperience, '<1');
      expect(profile.armSpanCm, isNull);
      expect(profile.chestPerimeterCm, 95.0);
      expect(profile.quadPerimeterCm, 50.0);
      expect(profile.calfPerimeterCm, isNull);
      expect(profile.weightGoal, 'lose');
      expect(profile.targetWeightKg, 65.0);
      expect(profile.kcalPerDay, 1800);
    });

    test('toJson() / fromJson() roundtrip preserves data', () {
      const original = UserProfile(
        birthDate: '1986-11-03',
        sex: 'male',
        weightKg: 100.0,
        heightCm: 190.0,
        gymExperience: '>5',
        armSpanCm: 195.0,
        bicepsPerimeterCm: 40.0,
        chestPerimeterCm: 110.0,
        waistPerimeterCm: 90.0,
        quadPerimeterCm: 60.0,
        calfPerimeterCm: 42.0,
        weightGoal: 'gain',
        targetWeightKg: 105.0,
        kcalPerDay: 3500,
      );

      final roundTripped = UserProfile.fromJson(original.toJson());

      expect(roundTripped.birthDate, original.birthDate);
      expect(roundTripped.sex, original.sex);
      expect(roundTripped.weightKg, original.weightKg);
      expect(roundTripped.heightCm, original.heightCm);
      expect(roundTripped.gymExperience, original.gymExperience);
      expect(roundTripped.armSpanCm, original.armSpanCm);
      expect(roundTripped.bicepsPerimeterCm, original.bicepsPerimeterCm);
      expect(roundTripped.chestPerimeterCm, original.chestPerimeterCm);
      expect(roundTripped.waistPerimeterCm, original.waistPerimeterCm);
      expect(roundTripped.quadPerimeterCm, original.quadPerimeterCm);
      expect(roundTripped.calfPerimeterCm, original.calfPerimeterCm);
      expect(roundTripped.weightGoal, original.weightGoal);
      expect(roundTripped.targetWeightKg, original.targetWeightKg);
      expect(roundTripped.kcalPerDay, original.kcalPerDay);
    });

    test('toJsonString() / fromJsonString() roundtrip preserves data', () {
      const original = UserProfile(
        birthDate: '2004-01-30',
        sex: 'female',
        weightKg: 60.0,
        heightCm: 165.0,
        gymExperience: '<1',
        weightGoal: 'lose',
        targetWeightKg: 55.0,
        kcalPerDay: 1500,
      );

      final jsonStr = original.toJsonString();
      // Verify it's valid JSON
      expect(() => jsonDecode(jsonStr), returnsNormally);

      final restored = UserProfile.fromJsonString(jsonStr);

      expect(restored.birthDate, original.birthDate);
      expect(restored.sex, original.sex);
      expect(restored.weightKg, original.weightKg);
      expect(restored.heightCm, original.heightCm);
      expect(restored.weightGoal, original.weightGoal);
      expect(restored.armSpanCm, isNull);
    });

    test('fromJson() handles integer weight/height (num cast)', () {
      final json = {
        'birthDate': '2001-03-15',
        'sex': 'male',
        'weightKg': 80, // int, not double
        'heightCm': 180, // int, not double
        'gymExperience': '1-3',
        'armSpanCm': null,
        'bicepsPerimeterCm': null,
        'chestPerimeterCm': null,
        'waistPerimeterCm': null,
        'quadPerimeterCm': null,
        'calfPerimeterCm': null,
        'weightGoal': 'gain',
        'targetWeightKg': 85,
        'kcalPerDay': 2500,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.weightKg, 80.0);
      expect(profile.heightCm, 180.0);
      expect(profile.targetWeightKg, 85.0);
    });
  });
}
