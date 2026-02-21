class Workout {
  final String id; // UUID (text)
  final String userId;
  final String workoutType;
  final DateTime workoutDate;
  final int durationMinutes;
  final int totalCaloriesBurned;
  final String? notes;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.userId,
    required this.workoutType,
    required this.workoutDate,
    required this.durationMinutes,
    required this.totalCaloriesBurned,
    this.notes,
    required this.createdAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutType: json['workout_type'] as String,
      workoutDate: DateTime.parse(json['workout_date'] as String),
      durationMinutes: json['duration_minutes'] as int,
      totalCaloriesBurned: json['total_calories_burned'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'workout_type': workoutType,
    'workout_date': workoutDate.toIso8601String(),
    'duration_minutes': durationMinutes,
    'total_calories_burned': totalCaloriesBurned,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
