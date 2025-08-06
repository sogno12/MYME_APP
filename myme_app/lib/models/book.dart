enum ReadingStatus {
  toRead,
  reading, 
  completed,
  paused,
  dropped
}

class Book {
  final String id;
  final String title;
  final String author;
  final String? thumbnailUrl;
  final int totalPages;
  final DateTime? manualStartDate;
  final DateTime? manualEndDate;
  final DateTime? calculatedStartDate;
  final DateTime? calculatedEndDate;
  final ReadingStatus status;
  final int currentPage;
  final String? notes;
  final double? rating;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.thumbnailUrl,
    required this.totalPages,
    this.manualStartDate,
    this.manualEndDate,
    this.calculatedStartDate,
    this.calculatedEndDate,
    this.status = ReadingStatus.toRead,
    this.currentPage = 0,
    this.notes,
    this.rating,
  });

  double get progressPercentage => totalPages > 0 ? (currentPage / totalPages) * 100 : 0;

  int get remainingPages => totalPages - currentPage;

  bool get isCompleted => status == ReadingStatus.completed;

  DateTime? get displayStartDate => manualStartDate ?? calculatedStartDate;
  DateTime? get displayEndDate => manualEndDate ?? calculatedEndDate;

  Book copyWith({
    String? title,
    String? author,
    String? thumbnailUrl,
    int? totalPages,
    DateTime? manualStartDate,
    DateTime? manualEndDate,
    DateTime? calculatedStartDate,
    DateTime? calculatedEndDate,
    ReadingStatus? status,
    int? currentPage,
    String? notes,
    double? rating,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalPages: totalPages ?? this.totalPages,
      manualStartDate: manualStartDate ?? this.manualStartDate,
      manualEndDate: manualEndDate ?? this.manualEndDate,
      calculatedStartDate: calculatedStartDate ?? this.calculatedStartDate,
      calculatedEndDate: calculatedEndDate ?? this.calculatedEndDate,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
      'totalPages': totalPages,
      'manualStartDate': manualStartDate?.toIso8601String(),
      'manualEndDate': manualEndDate?.toIso8601String(),
      'calculatedStartDate': calculatedStartDate?.toIso8601String(),
      'calculatedEndDate': calculatedEndDate?.toIso8601String(),
      'status': status.name,
      'currentPage': currentPage,
      'notes': notes,
      'rating': rating,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      thumbnailUrl: json['thumbnailUrl'],
      totalPages: json['totalPages'],
      manualStartDate: json['manualStartDate'] != null ? DateTime.parse(json['manualStartDate']) : null,
      manualEndDate: json['manualEndDate'] != null ? DateTime.parse(json['manualEndDate']) : null,
      calculatedStartDate: json['calculatedStartDate'] != null ? DateTime.parse(json['calculatedStartDate']) : null,
      calculatedEndDate: json['calculatedEndDate'] != null ? DateTime.parse(json['calculatedEndDate']) : null,
      status: ReadingStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => ReadingStatus.toRead),
      currentPage: json['currentPage'] ?? 0,
      notes: json['notes'],
      rating: json['rating']?.toDouble(),
    );
  }
}