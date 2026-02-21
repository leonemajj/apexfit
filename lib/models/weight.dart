class Weight {
  final int id;
  final String userId;
  final DateTime date;
  final double weightKg;
  final DateTime createdAt;

  Weight({
    required this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
    required this.createdAt,
  });

  factory Weight.fromJson(Map<String, dynamic> json) {
    return Weight(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weight_kg'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
