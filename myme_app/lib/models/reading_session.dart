class ReadingSession {
  final String id;
  final String bookId;
  final DateTime readingDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration duration;
  final int endPage;
  final int pagesRead;
  final String? notes;
  final String? mood;

  ReadingSession({
    required this.id,
    required this.bookId,
    required this.readingDate,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.endPage,
    required this.pagesRead,
    this.notes,
    this.mood,
  });

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double get pagesPerMinute {
    final minutes = duration.inMinutes;
    return minutes > 0 ? pagesRead / minutes : 0;
  }

  int get startPage => endPage - pagesRead;

  ReadingSession copyWith({
    String? bookId,
    DateTime? readingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? duration,
    int? endPage,
    int? pagesRead,
    String? notes,
    String? mood,
  }) {
    return ReadingSession(
      id: id,
      bookId: bookId ?? this.bookId,
      readingDate: readingDate ?? this.readingDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      duration: duration ?? this.duration,
      endPage: endPage ?? this.endPage,
      pagesRead: pagesRead ?? this.pagesRead,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'readingDate': readingDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'endPage': endPage,
      'pagesRead': pagesRead,
      'notes': notes,
      'mood': mood,
    };
  }

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'],
      bookId: json['bookId'],
      readingDate: DateTime.parse(json['readingDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      duration: Duration(minutes: json['durationMinutes']),
      endPage: json['endPage'],
      pagesRead: json['pagesRead'],
      notes: json['notes'],
      mood: json['mood'],
    );
  }
}