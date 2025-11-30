import 'dart:convert';

class TrainingEntry {
  TrainingEntry({
    required this.id,
    required this.title,
    required this.date,
    this.durationMinutes,
    this.notes,
    this.goalReached = false,
    this.distanceKm,
    this.googleFitActivityId,
  });

  final String id;
  final String title;
  final DateTime date;
  final int? durationMinutes;
  final String? notes;
  final bool goalReached;
  final double? distanceKm;
  final String? googleFitActivityId;

  TrainingEntry copyWith({
    String? title,
    DateTime? date,
    int? durationMinutes,
    String? notes,
    bool? goalReached,
    double? distanceKm,
    String? googleFitActivityId,
  }) {
    return TrainingEntry(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      goalReached: goalReached ?? this.goalReached,
      distanceKm: distanceKm ?? this.distanceKm,
      googleFitActivityId: googleFitActivityId ?? this.googleFitActivityId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'notes': notes,
        'goalReached': goalReached,
        'distanceKm': distanceKm,
        'googleFitActivityId': googleFitActivityId,
      };

  factory TrainingEntry.fromJson(Map<String, dynamic> json) {
    return TrainingEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int?,
      notes: json['notes'] as String?,
      goalReached: json['goalReached'] as bool? ?? false,
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
      googleFitActivityId: json['googleFitActivityId'] as String?,
    );
  }

  String toQrPayload() {
    final payload = {
      'sessionId': id,
      'title': title,
      'date': date.toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'goalReached': goalReached,
      'generatedAt': DateTime.now().toIso8601String(),
    };
    return jsonEncode(payload);
  }
}
