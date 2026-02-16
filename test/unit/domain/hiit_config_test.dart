import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';

void main() {
  group('HiitConfig', () {
    test('default constructor uses documented defaults', () {
      const config = HiitConfig();
      expect(config.sets, HiitConfig.defaultSets);
      expect(config.workSeconds, HiitConfig.defaultWorkSeconds);
      expect(config.restSeconds, HiitConfig.defaultRestSeconds);
      expect(config.setRestSeconds, HiitConfig.defaultSetRestSeconds);
    });

    test('toJson and fromJson round-trip', () {
      const original = HiitConfig(
        sets: 5,
        workSeconds: 40,
        restSeconds: 20,
        setRestSeconds: 120,
      );
      final json = original.toJson();
      final restored = HiitConfig.fromJson(json);

      expect(restored.sets, 5);
      expect(restored.workSeconds, 40);
      expect(restored.restSeconds, 20);
      expect(restored.setRestSeconds, 120);
      expect(restored, original);
    });

    test('fromJson falls back to defaults for missing keys', () {
      final config = HiitConfig.fromJson(<String, dynamic>{});
      expect(config.sets, HiitConfig.defaultSets);
      expect(config.workSeconds, HiitConfig.defaultWorkSeconds);
      expect(config.restSeconds, HiitConfig.defaultRestSeconds);
      expect(config.setRestSeconds, HiitConfig.defaultSetRestSeconds);
    });

    test('copyWith overrides individual fields', () {
      const original = HiitConfig(
        sets: 3,
        workSeconds: 20,
        restSeconds: 10,
        setRestSeconds: 90,
      );
      final updated = original.copyWith(sets: 6, workSeconds: 45);

      expect(updated.sets, 6);
      expect(updated.workSeconds, 45);
      expect(updated.restSeconds, 10);
      expect(updated.setRestSeconds, 90);
    });

    test('equality and hashCode', () {
      const a = HiitConfig(sets: 3, workSeconds: 20, restSeconds: 10, setRestSeconds: 90);
      const b = HiitConfig(sets: 3, workSeconds: 20, restSeconds: 10, setRestSeconds: 90);
      const c = HiitConfig(sets: 4, workSeconds: 20, restSeconds: 10, setRestSeconds: 90);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('toString contains all fields', () {
      const config = HiitConfig(sets: 2, workSeconds: 30, restSeconds: 15, setRestSeconds: 60);
      final str = config.toString();
      expect(str, contains('sets: 2'));
      expect(str, contains('work: 30s'));
      expect(str, contains('rest: 15s'));
      expect(str, contains('setRest: 60s'));
    });
  });
}
