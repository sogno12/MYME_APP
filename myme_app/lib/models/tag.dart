// lib/models/tag.dart

class Tag {
  final String id;
  String name;

  Tag({
    required this.id,
    required this.name,
  });

  // JSON 직렬화/역직렬화를 위한 팩토리 생성자 및 메서드 (향후 데이터 영속성 추가 시 유용)
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Tag 객체 비교를 위한 equals 및 hashCode 오버라이드
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // 복사를 위한 copyWith 메서드
  Tag copyWith({
    String? id,
    String? name,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}