/// 講義棟フロアマップ上の教室位置（ピンは画像左上を (0,0)、右下を (1,1) とする正規化座標）。
class CampusClassroomLocation {
  const CampusClassroomLocation({
    required this.campus,
    required this.buildingId,
    required this.buildingDisplayName,
    required this.floor,
    required this.roomCode,
    required this.searchTerms,
    required this.pinX,
    required this.pinY,
    this.description,
    this.pinLabel,
    this.pinMarkerScale = 1.0,
  });

  final String campus;
  final String buildingId;
  final String buildingDisplayName;
  final int floor;
  final String roomCode;
  final List<String> searchTerms;
  final double pinX;
  final double pinY;
  final String? description;

  /// フロア図のピン下に出す名称（未指定なら [roomCode]）。
  final String? pinLabel;

  /// ピン・アイコン・ラベル全体の表示倍率（1.0 が既定。長いラベル用に 1 未満を指定）。
  final double pinMarkerScale;
}

extension CampusClassroomLocationDisplay on CampusClassroomLocation {
  /// マップピンや検索一覧の主表示に使う名称。
  String get pinMapLabel => pinLabel ?? roomCode;

  /// ピン座標（0〜1）を図面内に収める。データ誤記でも極端な値で描画が壊れないようにする。
  double get pinXNormalized => pinX.clamp(0.0, 1.0);
  double get pinYNormalized => pinY.clamp(0.0, 1.0);

  /// 階の表記（地下は B2 / B1）。
  String get floorCaption {
    if (floor == -2) return 'B2';
    if (floor == -1) return 'B1';
    return '$floor階';
  }

  /// AppBar 末尾行（教室コード · ピンラベル）。
  String get floorMapDialogRoomDetailLine => '$roomCode · $pinMapLabel';
}
