import 'package:myme_app/models/book_model.dart';

// ReadingStatus enum을 한국어 문자열로 매핑
Map<ReadingStatus, String> readingStatusKorean = {
  ReadingStatus.toRead: '읽을 책',
  ReadingStatus.reading: '읽는 중',
  ReadingStatus.completed: '완독',
  ReadingStatus.paused: '잠시 멈춤',
  ReadingStatus.dropped: '읽기 중단',
};

// 영어 enum 이름을 한국어 문자열로 변환하는 함수
String getReadingStatusKorean(String statusName) {
  try {
    final status = ReadingStatus.values.firstWhere(
      (e) => e.name == statusName,
    );
    return readingStatusKorean[status] ?? statusName; // 매핑된 값이 없으면 영어 이름 반환
  } catch (e) {
    return statusName; // 유효하지 않은 enum 이름이면 그대로 반환
  }
}