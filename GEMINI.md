# 프로젝트 목표: 습관 트래커

이 프로젝트는 습관 트래커 애플리케이션입니다.

## 개발 방향

기존의 도서 관련 기능 개발에서 새로운 습관 트래커 기능 개발로 전환합니다.

### 핵심 기능:
- 사용자는 습관을 생성, 수정, 삭제할 수 있습니다.
- 사용자는 특정 날짜에 습관을 완료했음을 표시할 수 있습니다.
- **하나의 로그에 시간(time), 달성률(percentage), 횟수(quantity) 등 여러 유형의 데이터를 동시에 기록할 수 있습니다.**
- 애플리케이션은 습관 달성 현황 및 연속 기록(streaks)을 시각적으로 보여주는 기능을 제공해야 합니다.

### 모델 설계:
- **`Habit` 모델**: 
    - `trackingType` 필드를 통해 통계 화면에 표시될 '대표' 값 유형(시간, 달성률, 횟수 등)을 지정할 수 있습니다.
    - 이는 로그 기록 시의 입력 필드를 제한하는 것이 아니라, 통계 표시의 기준을 설정하는 역할만 합니다.
- **`HabitLog` 모델**:
    - `timeValue`, `percentageValue`, `quantityValue` 필드를 각각 독립적으로 두어, 하나의 로그에 여러 종류의 수치 데이터를 유연하게 저장할 수 있도록 합니다.

### 현재까지 완성된 기능:
- 오늘의 습관 선택 및 완료 표시 (습관 생성 및 당일 기록)
- 전체 습관 목록 조회 기능
- 습관 수정 기능
- 습관 삭제 기능
- 날짜 선택기 `yyyy/MM/dd` 형식으로 변경
- 태그 관리 기능 (생성, 수정, 삭제)
- `TodaysHabitsScreen` 및 `AllHabitsScreen`에서 태그 및 제목으로 습관 필터링 기능
- `AllHabitsScreen`에서 습관 탭 시 해당 습관의 로그 목록 화면 (`HabitLogListScreen`)으로 이동
- `HabitLog` 모델에 `createdAt`, `updatedAt` 필드 추가
- `HabitLogListScreen`에서 로그 목록을 `logDate`, `createdAt`, `updatedAt` 기준으로 정렬 기능
- `Habit` 모델에 `isArchived` 필드 추가 및 관련 로직 수정
- `AllHabitsScreen`에 보관된 습관을 제외하고 필터링하는 기능 추가
- `Habit` 모델에 `order` 필드 추가 및 습관 정렬 기능 구현
- `TodaysHabitsScreen`의 습관 목록 순서 변경 기능 추가
- `AllHabitsScreen`의 습관 목록 순서 변경 기능 추가
- `Habit` 모델에 `repeatedDays` 필드 추가
- `TodaysHabitsScreen`에 요일별 습관 필터링 기능 추가
- `Habit` 모델에 `tags` 필드 추가
- 태그 추가/삭제 기능
- 태그별 필터링 기능
- `Habit` 모델에 `memo` 필드 추가 및 관련 기능 구현
- 이모지 선택 기능 추가
- `Habit` 모델에 `emoji` 필드 추가
- 데이터베이스 마이그레이션 (3->4, 4->5, 5->6, 6->7, 7->8, 8->9, 9->10)
- **로그 편집 화면에서 `time`, `percentage`, `quantity` 입력 필드를 항상 모두 제공**
- **로그 입력 값 유효성 검사 기능:**
    - `timeValue`: 0 이상의 숫자만 허용
    - `percentageValue`: 0에서 100 사이의 숫자만 허용
    - `quantityValue`: 0 이상의 숫자만 허용

### 앞으로 추가해야 할 기능:
- 습관 달성 현황 및 연속 기록(streaks) 시각화 기능
