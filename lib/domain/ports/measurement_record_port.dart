import 'package:gym_tracker/domain/entities/measurement_record.dart';

/// Port for body measurement history persistence.
abstract class MeasurementRecordPort {
  Future<List<MeasurementRecord>> loadRecords();
  Future<void> saveRecords(List<MeasurementRecord> records);

  Future<void> addRecord(MeasurementRecord record) async {
    final all = await loadRecords();
    all.add(record);
    await saveRecords(all);
  }
}
