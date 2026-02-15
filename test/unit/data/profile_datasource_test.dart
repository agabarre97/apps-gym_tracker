import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ProfileDatasource', () {
    late FakeStoragePort storage;
    late ProfileDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = ProfileDatasource(storage);
    });

    test('loadProfile() returns null when no profile saved', () async {
      expect(await datasource.loadProfile(), isNull);
    });

    test('saveProfile() then loadProfile() returns the same data', () async {
      final profile = sampleProfile();

      await datasource.saveProfile(profile);
      final loaded = await datasource.loadProfile();

      expect(loaded, isNotNull);
      expect(loaded!.birthDate, profile.birthDate);
      expect(loaded.sex, profile.sex);
      expect(loaded.weightKg, profile.weightKg);
      expect(loaded.heightCm, profile.heightCm);
      expect(loaded.gymExperience, profile.gymExperience);
      expect(loaded.armSpanCm, profile.armSpanCm);
      expect(loaded.weightGoal, profile.weightGoal);
      expect(loaded.targetWeightKg, profile.targetWeightKg);
      expect(loaded.kcalPerDay, profile.kcalPerDay);
    });

    test('saveProfile() stores valid JSON in storage', () async {
      await datasource.saveProfile(sampleProfile());

      final raw = await storage.get('user_profile');
      expect(raw, isNotNull);
      expect(raw, contains('"birthDate":"2001-03-15"'));
    });

    test('isProfileCompleted() returns false by default', () async {
      expect(await datasource.isProfileCompleted(), isFalse);
    });

    test('markProfileCompleted() sets the flag to true', () async {
      await datasource.markProfileCompleted();
      expect(await datasource.isProfileCompleted(), isTrue);
    });

    test('saving a new profile overwrites the old one', () async {
      await datasource.saveProfile(sampleProfile(weightGoal: 'gain'));
      await datasource.saveProfile(sampleProfile(weightGoal: 'lose'));

      final loaded = await datasource.loadProfile();
      expect(loaded!.weightGoal, 'lose');
    });
  });
}
