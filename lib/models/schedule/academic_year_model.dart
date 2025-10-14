class AcademicYear {
  final int year;
  final AcademicSemester semester;

  const AcademicYear({
    required this.year,
    required this.semester,
  });

  String get displayName => '$year年度${semester.displayName}';
  
  String get key => '${year}_${semester.key}';

  factory AcademicYear.fromKey(String key) {
    final parts = key.split('_');
    if (parts.length != 2) {
      throw ArgumentError('Invalid academic year key: $key');
    }
    
    return AcademicYear(
      year: int.parse(parts[0]),
      semester: AcademicSemester.fromKey(parts[1]),
    );
  }

  factory AcademicYear.current() {
    final now = DateTime.now();
    // 日本の学年度は4月始まり
    final academicYear = now.month >= 4 ? now.year : now.year - 1;
    
    // 前期：4-8月、後期：9-1月
    final semester = now.month >= 4 && now.month <= 8 
        ? AcademicSemester.firstSemester 
        : AcademicSemester.secondSemester;
    
    return AcademicYear(year: academicYear, semester: semester);
  }

  static List<AcademicYear> generateYearRange({
    int? startYear,
    int? endYear,
  }) {
    final start = startYear ?? 2023; // 2023年度から
    final end = endYear ?? 2050;     // 2050年度まで
    
    final years = <AcademicYear>[];
    
    for (int year = start; year <= end; year++) {
      years.add(AcademicYear(year: year, semester: AcademicSemester.firstSemester));
      years.add(AcademicYear(year: year, semester: AcademicSemester.secondSemester));
    }
    
    return years;
  }

  // 全年度範囲を取得（2023-2050）
  static List<AcademicYear> getAllYears() {
    return generateYearRange(startYear: 2023, endYear: 2050);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicYear &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          semester == other.semester;

  @override
  int get hashCode => year.hashCode ^ semester.hashCode;

  @override
  String toString() => displayName;
}

enum AcademicSemester {
  firstSemester('first', '前期'),
  secondSemester('second', '後期'),
  fullYear('full', '通年');

  const AcademicSemester(this.key, this.displayName);

  final String key;
  final String displayName;

  static AcademicSemester fromKey(String key) {
    return AcademicSemester.values.firstWhere(
      (semester) => semester.key == key,
      orElse: () => throw ArgumentError('Unknown semester key: $key'),
    );
  }
}