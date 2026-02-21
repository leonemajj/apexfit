class Meal {
  final int id;
  final String userId;
  final String mealType;
  final DateTime mealDate;
  final int totalCalories;
  final String? notes;
  final DateTime createdAt;

  Meal({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.mealDate,
    required this.totalCalories,
    this.notes,
    required this.createdAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      mealType: json['meal_type'] as String,
      mealDate: DateTime.parse(json['meal_date'] as String),
      totalCalories: json['total_calories'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'meal_type': mealType,
    'meal_date': mealDate.toIso8601String(),
    'total_calories': totalCalories,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
