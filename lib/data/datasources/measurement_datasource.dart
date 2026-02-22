import 'package:gym_tracker/domain/entities/measurement_record.dart';
import 'package:gym_tracker/domain/ports/measurement_record_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Adapter implementing [MeasurementRecordPort] using [StoragePort].
class MeasurementDatasource implements MeasurementRecordPort {
  const MeasurementDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'measurement_records';

  @override
  Future<List<MeasurementRecord>> loadRecords() async {
    final raw = await _storage.get(_key);
    if (raw == null || raw.isEmpty) return [];
    return MeasurementRecord.listFromJsonString(raw);
  }

  @override
  Future<void> saveRecords(List<MeasurementRecord> records) =>
      _storage.set(_key, MeasurementRecord.listToJsonString(records));

  @override
  Future<void> addRecord(MeasurementRecord record) async {
    final all = await loadRecords();
    all.add(record);
    await saveRecords(all);
  }
}
