class CafeteriaCameraService {
  // カメラ画像のベースURL
  static const String baseUrl = 'https://www.cit-s.com/i_catch/dining';
  
  // 各食堂のカメラ画像URL
  // タイムスタンプを追加してキャッシュを無効化（5分毎に更新）
  static String getTsudanumaCameraUrl() {
    // 5分単位のタイムスタンプを生成（5分毎に同じURLになる）
    final now = DateTime.now();
    final minutesSinceEpoch = now.millisecondsSinceEpoch ~/ (1000 * 60 * 5);
    return '$baseUrl/tsudanuma.jpg?$minutesSinceEpoch';
  }

  static String getNarashino1FCameraUrl() {
    final now = DateTime.now();
    final minutesSinceEpoch = now.millisecondsSinceEpoch ~/ (1000 * 60 * 5);
    return '$baseUrl/narashino1.jpg?$minutesSinceEpoch';
  }

  static String getNarashino2FCameraUrl() {
    final now = DateTime.now();
    final minutesSinceEpoch = now.millisecondsSinceEpoch ~/ (1000 * 60 * 5);
    return '$baseUrl/narashino2.jpg?$minutesSinceEpoch';
  }

  // カメラが稼働中かチェック
  static bool isCameraActive({
    required String cafeteria,
    required DateTime now,
  }) {
    final weekday = now.weekday; // 1=月曜日, 7=日曜日
    final hour = now.hour;
    final minute = now.minute;
    final currentTime = hour * 60 + minute;
    final startTime = 11 * 60; // 11:00
    final endTime = 14 * 60; // 14:00

    // 時間チェック（11:00-14:00の間）
    if (currentTime < startTime || currentTime >= endTime) {
      return false;
    }

    // 曜日チェック
    switch (cafeteria) {
      case 'tsudanuma':
      case 'narashino1':
        // 月〜土（1-6）
        return weekday >= 1 && weekday <= 6;
      case 'narashino2':
        // 月〜金（1-5）
        return weekday >= 1 && weekday <= 5;
      default:
        return false;
    }
  }

  // 食堂名を表示用に変換
  static String getCafeteriaDisplayName(String cafeteria) {
    switch (cafeteria) {
      case 'tsudanuma':
        return '津田沼';
      case 'narashino1':
        return '新習志野1F';
      case 'narashino2':
        return '新習志野2F';
      default:
        return cafeteria;
    }
  }

  // カメラ画像URLを取得
  static String getCameraUrl(String cafeteria) {
    switch (cafeteria) {
      case 'tsudanuma':
        return getTsudanumaCameraUrl();
      case 'narashino1':
        return getNarashino1FCameraUrl();
      case 'narashino2':
        return getNarashino2FCameraUrl();
      default:
        return '';
    }
  }
}

