import 'package:flutter/services.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds routine PDF exports for all routine types.
class RoutinePdfExportService {
  static pw.ThemeData? _cachedTheme;

  static Future<Uint8List> buildWorkoutRoutinePdf({
    required Routine routine,
    required List<Exercise> allExercises,
    required WorkoutSession? lastSession,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    final exerciseNameByKey = {
      for (final exercise in allExercises) exercise.key: exercise.name,
    };

    final theme = await _buildTheme();
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (context) => [
          _title(routine.name),
          _meta(
            type: routine.type,
            generatedAt: generatedAt,
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Plan por dias'),
          for (var i = 0; i < routine.days.length; i++)
            _dayBlock(
              dayNumber: i + 1,
              exerciseNames: routine.days[i].exerciseKeys
                  .map((key) => exerciseNameByKey[key] ?? key)
                  .toList(),
            ),
          pw.SizedBox(height: 10),
          _sectionTitle('Ultimo entrenamiento'),
          if (lastSession == null)
            pw.Text('Sin datos de entrenamiento todavia.')
          else ...[
            pw.Text(
              'Fecha: ${_formatDate(lastSession.date)}',
            ),
            if (lastSession.startTime != null || lastSession.endTime != null)
              pw.Text(
                'Horario: ${_formatRange(lastSession.startTime, lastSession.endTime)}',
              ),
            pw.SizedBox(height: 8),
            for (final workoutExercise in lastSession.exercises) ...[
              pw.Text(
                exerciseNameByKey[workoutExercise.exerciseKey] ??
                    workoutExercise.exerciseKey,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: const ['Serie', 'Reps', 'Peso (kg)', 'Descanso (s)'],
                data: [
                  for (var index = 0;
                      index < workoutExercise.sets.length;
                      index++)
                    [
                      '${index + 1}',
                      '${workoutExercise.sets[index].reps}',
                      '${workoutExercise.sets[index].weight}',
                      workoutExercise.sets[index].estimatedRestSeconds != null
                          ? '${workoutExercise.sets[index].estimatedRestSeconds}'
                          : '-',
                    ],
                ],
              ),
              if (workoutExercise.notes.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4, bottom: 8),
                  child: pw.Text('Notas: ${workoutExercise.notes}'),
                ),
              pw.SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildHiitRoutinePdf({
    required Routine routine,
    required List<HiitExercise> routineExercises,
    required HiitSession? lastSession,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();

    final theme = await _buildTheme();
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (context) => [
          _title(routine.name),
          _meta(type: routine.type, generatedAt: generatedAt),
          pw.SizedBox(height: 14),
          _sectionTitle('Plan de ejercicios'),
          for (var i = 0; i < routineExercises.length; i++)
            pw.Bullet(text: '${i + 1}. ${routineExercises[i].name}'),
          pw.SizedBox(height: 10),
          _sectionTitle('Configuracion'),
          pw.Text('Series: ${routine.hiitSets ?? '-'}'),
          pw.Text('Trabajo: ${routine.hiitWorkSeconds ?? '-'} s'),
          pw.Text('Descanso: ${routine.hiitRestSeconds ?? '-'} s'),
          pw.Text(
              'Descanso entre series: ${routine.hiitSetRestSeconds ?? '-'} s'),
          pw.SizedBox(height: 10),
          _sectionTitle('Ultima sesion'),
          if (lastSession == null)
            pw.Text('Sin datos de entrenamiento todavia.')
          else ...[
            pw.Text('Fecha: ${_formatDate(lastSession.date)}'),
            if (lastSession.startTime != null || lastSession.endTime != null)
              pw.Text(
                'Horario: ${_formatRange(lastSession.startTime, lastSession.endTime)}',
              ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildMobilityRoutinePdf({
    required Routine routine,
    required MobilityRoutine? mobilityRoutine,
    required MobilitySession? lastSession,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();

    final exerciseLines = mobilityRoutine == null
        ? <String>[]
        : mobilityRoutine.exercises
            .map((exercise) => '${exercise.key} (${exercise.durationSeconds}s)')
            .toList();

    final theme = await _buildTheme();
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (context) => [
          _title(routine.name),
          _meta(type: routine.type, generatedAt: generatedAt),
          pw.SizedBox(height: 14),
          _sectionTitle('Plan de ejercicios'),
          if (exerciseLines.isEmpty)
            pw.Text('No se pudo cargar el detalle de ejercicios.')
          else
            for (var i = 0; i < exerciseLines.length; i++)
              pw.Bullet(text: '${i + 1}. ${exerciseLines[i]}'),
          if (mobilityRoutine != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                'Duracion total aprox.: ${mobilityRoutine.totalDurationMinutes} min',
              ),
            ),
          pw.SizedBox(height: 10),
          _sectionTitle('Ultima sesion'),
          if (lastSession == null)
            pw.Text('Sin datos de entrenamiento todavia.')
          else ...[
            pw.Text('Fecha: ${_formatDate(lastSession.date)}'),
            if (lastSession.startTime != null || lastSession.endTime != null)
              pw.Text(
                'Horario: ${_formatRange(lastSession.startTime, lastSession.endTime)}',
              ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _title(String value) => pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
        ),
      );

  static pw.Widget _meta({
    required String type,
    required DateTime generatedAt,
  }) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Tipo de rutina: $type'),
          pw.Text('Generado: ${_formatDateTime(generatedAt)}'),
        ],
      );

  static pw.Widget _sectionTitle(String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  static pw.Widget _dayBlock({
    required int dayNumber,
    required List<String> exerciseNames,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Día $dayNumber',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (exerciseNames.isEmpty)
              pw.Text('Sin ejercicios')
            else
              for (final name in exerciseNames) pw.Bullet(text: name),
          ],
        ),
      );

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_formatDate(value)} $hour:$minute';
  }

  static String _formatRange(DateTime? start, DateTime? end) {
    String toShort(DateTime value) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    if (start == null && end == null) return '-';
    if (start == null) return '- -> ${toShort(end!)}';
    if (end == null) return '${toShort(start)} -> -';
    return '${toShort(start)} -> ${toShort(end)}';
  }

  static Future<pw.ThemeData> _buildTheme() async {
    if (_cachedTheme != null) return _cachedTheme!;

    final regularFontData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData =
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final baseFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);
    _cachedTheme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );
    return _cachedTheme!;
  }
}
