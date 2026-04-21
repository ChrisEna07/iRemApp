class Task {
  final int? id;
  final String title;
  final String description;
  final String dayOfWeek;
  final DateTime dateTime;
  final bool isDone;
  final String? imagePath;
  final int anticipationDays; // Días de anticipación para avisar

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dayOfWeek,
    required this.dateTime,
    this.isDone = false,
    this.imagePath,
    this.anticipationDays = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dayOfWeek': dayOfWeek,
      'dateTime': dateTime.toIso8601String(),
      'isDone': isDone ? 1 : 0,
      'imagePath': imagePath,
      'anticipationDays': anticipationDays,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dayOfWeek: map['dayOfWeek'],
      dateTime: DateTime.parse(map['dateTime']),
      isDone: map['isDone'] == 1,
      imagePath: map['imagePath'],
      anticipationDays: map['anticipationDays'] ?? 0,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? dayOfWeek,
    DateTime? dateTime,
    bool? isDone,
    String? imagePath,
    int? anticipationDays,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dateTime: dateTime ?? this.dateTime,
      isDone: isDone ?? this.isDone,
      imagePath: imagePath ?? this.imagePath,
      anticipationDays: anticipationDays ?? this.anticipationDays,
    );
  }
}