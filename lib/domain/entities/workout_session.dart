import 'dart:convert';

/// A single set within an exercise: reps, weight, and optional rest estimate.
class ExerciseSet {
  const ExerciseSet({
    required this.reps,
    required this.weight,
    this.estimatedRestSeconds,
  });

  final int reps;

  /// Weight in kilograms (decimals allowed, max 2 decimal places).
  final double weight;

  /// Estimated rest time in seconds before this set was started.
  /// Computed from the time between the last edit of the previous set and
  /// the first edit of this set. `null` for the first set or when unavailable.
  final int? estimatedRestSeconds;

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight,
        if (estimatedRestSeconds != null)
          'estimatedRestSeconds': estimatedRestSeconds,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        reps: json['reps'] as int,
        weight: (json['weight'] as num).toDouble(),
        estimatedRestSeconds: json['estimatedRestSeconds'] as int?,
      );

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    int? estimatedRestSeconds,
    bool clearRest = false,
  }) =>
      ExerciseSet(
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        estimatedRestSeconds: clearRest
            ? null
            : (estimatedRestSeconds ?? this.estimatedRestSeconds),
      );
}

/// Tracks one exercise during a workout session.
class WorkoutExercise {
  const WorkoutExercise({
    required this.exerciseKey,
    required this.sets,
    this.notes = '',
    this.completed = false,
  });

  /// Locale-independent exercise identifier.
  final String exerciseKey;

  /// Sets performed for this exercise.
  final List<ExerciseSet> sets;

  /// Free-text observations.
  final String notes;

  /// Whether the user has marked this exercise as done.
  final bool completed;

  Map<String, dynamic> toJson() => {
        'exerciseKey': exerciseKey,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
        'completed': completed,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        exerciseKey: json['exerciseKey'] as String,
        sets: (json['sets'] as List)
            .cast<Map<String, dynamic>>()
            .map(ExerciseSet.fromJson)
            .toList(),
        notes: json['notes'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );

  WorkoutExercise copyWith({
    String? exerciseKey,
    List<ExerciseSet>? sets,
    String? notes,
    bool? completed,
  }) =>
      WorkoutExercise(
        exerciseKey: exerciseKey ?? this.exerciseKey,
        sets: sets ?? this.sets,
        notes: notes ?? this.notes,
        completed: completed ?? this.completed,
      );

  /// Creates default exercise with 3 empty sets.
  factory WorkoutExercise.empty(String exerciseKey) => WorkoutExercise(
        exerciseKey: exerciseKey,
        sets: List.generate(3, (_) => const ExerciseSet(reps: 0, weight: 0)),
      );
}

/// A complete workout session.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.routineId,
    required this.routineDayIndex,
    required this.date,
    this.startTime,
    this.endTime,
    required this.exercises,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Which routine was used.
  final String routineId;

  /// Which day (0-based index) within the routine.
  final int routineDayIndex;

  /// Calendar date (normalized to yyyy-MM-dd).
  final DateTime date;

  /// When the workout started (null for retroactive entries).
  final DateTime? startTime;

  /// When the workout ended (null for in-progress or retroactive).
  final DateTime? endTime;

  /// Exercise data for this session.
  final List<WorkoutExercise> exercises;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'routineDayIndex': routineDayIndex,
        'date': '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    return WorkoutSession(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      routineDayIndex: json['routineDayIndex'] as int,
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
      exercises: (json['exercises'] as List)
          .cast<Map<String, dynamic>>()
          .map(WorkoutExercise.fromJson)
          .toList(),
    );
  }

  WorkoutSession copyWith({
    String? id,
    String? routineId,
    int? routineDayIndex,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutExercise>? exercises,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) =>
      WorkoutSession(
        id: id ?? this.id,
        routineId: routineId ?? this.routineId,
        routineDayIndex: routineDayIndex ?? this.routineDayIndex,
        date: date ?? this.date,
        startTime: clearStartTime ? null : (startTime ?? this.startTime),
        endTime: clearEndTime ? null : (endTime ?? this.endTime),
        exercises: exercises ?? this.exercises,
      );

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static List<WorkoutSession> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(WorkoutSession.fromJson)
          .toList();

  static String listToJsonString(List<WorkoutSession> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());
}
