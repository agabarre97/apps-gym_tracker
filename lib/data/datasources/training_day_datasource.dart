import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Adapter implementing [TrainingDayPort] using [StoragePort].
class TrainingDayDatasource implements TrainingDayPort {
  const TrainingDayDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'training_days';

  @override
  Future<List<TrainingDay>> loadTrainingDays() async {
    final raw = await _storage.get(_key);
    if (raw == null) return [];
    return TrainingDay.listFromJsonString(raw);
  }

  @override
  Future<void> saveTrainingDays(List<TrainingDay> days) =>
      _storage.set(_key, TrainingDay.listToJsonString(days));
}
