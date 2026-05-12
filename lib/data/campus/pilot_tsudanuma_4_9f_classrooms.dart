import '../../models/campus/campus_classroom_location.dart';
import 'pilot_location_query_match.dart';

bool usesTsudanuma4F9AppFloorMap(CampusClassroomLocation room) {
  return room.campus == 'tsudanuma' &&
      room.buildingId == '4' &&
      room.floor == 9;
}

/// 津田沼4号館9階（アプリ同梱フロア図、正規化座標 0〜1・左上原点）。
///
/// **図面に施設名称と教室番号の両方がある区画**を載せる。**倉庫（1）**（番号なし）は載せない。
/// `pinX` / `pinY` は8階パイロット（`pilot_tsudanuma_4_8_classrooms.dart`）と同レイアウト列の区画へ**同じ値**で割り当てる。
/// （右端列末尾の複数は8階の近傍ピンに合わせ、細部は実機画像で調整する）。
List<CampusClassroomLocation> get pilotTsudanumaBuilding4Floor9 => [
  // 040901〜040913 → 040801〜040815 と同順の右列ピン（040807・040811欠番あり）
  _b4f9('040901', '文化会倉庫 (4)', pinX: 0.66, pinY: 0.14, extra: ['文化会倉庫']),
  _b4f9('040902', '第三集会室', pinX: 0.69, pinY: 0.19),
  _b4f9('040903', '自動車工学研究会', pinX: 0.69, pinY: 0.23, extra: ['自動車工学']),
  _b4f9('040904', '東洋学術研究会', pinX: 0.69, pinY: 0.27),
  _b4f9('040905', '天文研究部', pinX: 0.69, pinY: 0.30, extra: ['天文']),
  _b4f9('040906', 'ソフトメディア研究会', pinX: 0.66, pinY: 0.36, extra: ['ソフトメディア']),
  _b4f9(
    '040907',
    'マンガ研究会',
    pinX: 0.66,
    pinY: 0.43,
    extra: ['マンガ', '漫画研究会'],
  ),
  _b4f9(
    '040908',
    '構想ロボット工学研究会',
    pinX: 0.66,
    pinY: 0.50,
    extra: ['ロボット', '構想ロボット'],
  ),
  _b4f9(
    '040909',
    'ラウンジ',
    pinX: 0.66,
    pinY: 0.57,
  ),
  _b4f9(
    '040910',
    '第三会議室',
    pinX: 0.66,
    pinY: 0.64,
    extra: ['会議室'],
  ),
  _b4f9(
    '040911',
    'TRPG研究会',
    pinX: 0.66,
    pinY: 0.71,
    extra: ['TRPG', 'ティーアールピージー'],
  ),
  _b4f9('040912', '電気研究部', pinX: 0.69, pinY: 0.76, extra: ['電気']),
  _b4f9('040913', '電子工学研究会', pinX: 0.69, pinY: 0.80, extra: ['電子工学']),
  // 040914〜916 → 8階040812〜040815列の下端付近ピンと同様
  _b4f9('040914', '将棋倶楽部', pinX: 0.69, pinY: 0.83, extra: ['将棋']),
  _b4f9('040915', '囲碁部', pinX: 0.69, pinY: 0.86, extra: ['囲碁']),
  _b4f9(
    '040916',
    '文化会倉庫 (3)',
    pinX: 0.66
    ,
    pinY: 0.90,
    extra: ['文化会倉庫'],
  ),
  // 040917〜040932 → 040816〜040831 と対応する左列（下端→上）
  _b4f9(
    '040917',
    '吹奏楽部',
    pinX: 0.30,
    pinY: 0.93,
    extra: ['吹奏楽'],
  ),
  _b4f9(
    '040918',
    '放送研究部',
    pinX: 0.30,
    pinY: 0.89,
    extra: ['放送'],
  ),
  _b4f9(
    '040919',
    'フィッシャークラブ',
    pinX: 0.30,
    pinY: 0.86,
    extra: ['フィッシャー'],
  ),
  _b4f9(
    '040920',
    '演劇部',
    pinX: 0.30,
    pinY: 0.83,
    extra: ['演劇'],
  ),
  _b4f9(
    '040921',
    '鉄道倶楽部',
    pinX: 0.30,
    pinY: 0.52,
    extra: ['鉄道'],
  ),
  _b4f9(
    '040922',
    '航空工学研究会',
    pinX: 0.30,
    pinY: 0.49,
    extra: ['航空工学', '航空'],
  ),
  _b4f9(
    '040923',
    '動画制作部',
    pinX: 0.30,
    pinY: 0.45,
    extra: ['動画'],
  ),
  _b4f9(
    '040924',
    '総合工学研究会',
    pinX: 0.30,
    pinY: 0.41,
    extra: ['総合工学'],
  ),
  _b4f9(
    '040925',
    'ゲームサークル',
    pinX: 0.30,
    pinY: 0.38,
    extra: ['ゲーム'],
  ),
  _b4f9(
    '040926',
    'アカペラサークル',
    pinX: 0.30,
    pinY: 0.34,
    extra: ['アカペラ'],
  ),
  _b4f9(
    '040927',
    'ギタークラブ',
    pinX: 0.30,
    pinY: 0.30,
    extra: ['ギター'],
  ),
  _b4f9(
    '040928',
    '手芸倶楽部',
    pinX: 0.30,
    pinY: 0.26,
    extra: ['手芸'],
  ),
  _b4f9(
    '040929',
    '軽音楽部',
    pinX: 0.30,
    pinY: 0.23,
    extra: ['軽音', 'ケイオン'],
  ),
  _b4f9(
    '040930',
    '民族音楽研究会',
    pinX: 0.30,
    pinY: 0.19,
    extra: ['民族音楽'],
  ),
  _b4f9(
    '040931',
    'ハワイアンクラブ',
    pinX: 0.30,
    pinY: 0.15,
    extra: ['ハワイアン'],
  ),
  _b4f9(
    '040932',
    'フォークソング研究会',
    pinX: 0.30,
    pinY: 0.12,
    extra: ['フォークソング', 'フォーク'],
  ),
];

const Map<String, String> _zf9 = {
  '0': '０',
  '1': '１',
  '2': '２',
  '3': '３',
  '4': '４',
  '5': '５',
  '6': '６',
  '7': '７',
  '8': '８',
  '9': '９',
};

String _zenCode(String digits) =>
    digits.replaceAllMapped(RegExp(r'\d'), (m) => _zf9[m[0]]!);

/// 8階ファイルと同一の検索語パターン（室番・全角digit・名称）に揃える。
CampusClassroomLocation _b4f9(
  String roomCode,
  String pinLabel, {
  required double pinX,
  required double pinY,
  List<String> extra = const [],
}) {
  final shortDigits = roomCode.substring(1);
  final zen = _zenCode(roomCode);
  return CampusClassroomLocation(
    campus: 'tsudanuma',
    buildingId: '4',
    buildingDisplayName: '4号館',
    floor: 9,
    roomCode: roomCode,
    searchTerms: [
      roomCode,
      shortDigits,
      zen,
      '$roomCode号室',
      '$roomCode号',
      pinLabel,
      ...extra,
    ],
    pinX: pinX,
    pinY: pinY,
    description: '9階・$pinLabel（$roomCode）',
    pinLabel: pinLabel,
  );
}

List<CampusClassroomLocation> searchPilotTsudanuma4F9(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  bool matches(CampusClassroomLocation r) => pilotLocationMatchesQuery(r, q);
  return pilotTsudanumaBuilding4Floor9.where(matches).toList();
}
