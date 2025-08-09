// users 테이블의 데이터를 담을 모델 클래스
class User {
  final int? id;
  final String email;
  final String password;
  final String? name;
  final String? nickname;

  User({
    this.id,
    required this.email,
    required this.password,
    this.name,
    this.nickname,
  });

  // 데이터베이스에 저장하기 위해 Map 형태로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'nickname': nickname,
    };
  }

  // Map 형태의 데이터를 User 객체로 변환합니다.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'],
      email: map['email'],
      password: map['password'],
      name: map['name'],
      nickname: map['nickname'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, nickname: $nickname}';
  }
}

