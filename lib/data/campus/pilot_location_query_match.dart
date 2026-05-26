import 'dart:math' as math;

import '../../models/campus/campus_classroom_location.dart';

/// 文字列先頭付近の「最初の連続数字」を返す（例: `1101講義室` → `1101`）。
String pilotLeadingDigitRunFromStart(String s) {
  final lower = s.toLowerCase().trim();
  var i = 0;
  while (i < lower.length && !RegExp(r'\d').hasMatch(lower[i])) {
    i++;
  }
  if (i >= lower.length) return '';
  var j = i;
  while (j < lower.length && RegExp(r'\d').hasMatch(lower[j])) {
    j++;
  }
  return lower.substring(i, j);
}

/// 教室マップ pilot 用の検索一致（大文字小文字は呼び出し側で揃える想定）。
///
/// 数字のみのクエリ（2桁以上）は、先頭の数字列がそのプレフィックスなら一致（例: `110` → `1101講義室`）。
/// 3桁以上の数字のみのときは、他の番号の途中だけの一致を避ける（例: `1101` が `070110` にマッチしない）。
/// `070103` と `70103` は数値として同一なら一致。
bool pilotLocationMatchesQuery(CampusClassroomLocation r, String queryLower) {
  final q = queryLower.trim().toLowerCase();
  if (q.isEmpty) return false;
  final code = r.roomCode.toLowerCase();
  if (code == q) return true;
  if (_hayContainsQuery(code, q)) return true;
  final pin = r.pinLabel;
  if (pin != null && pin.isNotEmpty) {
    final pl = pin.toLowerCase();
    if (pl == q || _hayContainsQuery(pl, q)) return true;
  }
  for (final t in r.searchTerms) {
    if (_hayContainsQuery(t.toLowerCase(), q)) return true;
  }
  return false;
}

/// 統合検索の並び替え用。大きいほど上位に表示する。
int classroomMapPilotMatchRank(CampusClassroomLocation r, String queryLower) {
  final q = queryLower.trim().toLowerCase();
  if (q.isEmpty) return 0;
  var rank = 0;
  final code = r.roomCode.toLowerCase();

  if (code.startsWith(q)) {
    rank = math.max(rank, 4000);
  }
  final pin = r.pinLabel;
  if (pin != null && pin.isNotEmpty) {
    final pl = pin.toLowerCase();
    if (pl.startsWith(q)) {
      rank = math.max(rank, 3800);
    }
  }
  for (final t in r.searchTerms) {
    final tl = t.toLowerCase();
    if (tl.startsWith(q)) {
      rank = math.max(rank, 3500);
    }
  }

  if (RegExp(r'^\d{2,}$').hasMatch(q)) {
    final ldCode = pilotLeadingDigitRunFromStart(code);
    if (ldCode.isNotEmpty && ldCode.startsWith(q)) {
      rank = math.max(rank, 3000);
    }
    for (final t in r.searchTerms) {
      final ld = pilotLeadingDigitRunFromStart(t.toLowerCase());
      if (ld.isNotEmpty && ld.startsWith(q)) {
        rank = math.max(rank, 2800);
      }
    }
  }

  if (rank < 2800 && code.contains(q)) {
    rank = math.max(rank, 500);
  }
  if (rank < 2800) {
    for (final t in r.searchTerms) {
      if (t.toLowerCase().contains(q)) {
        rank = math.max(rank, 400);
        break;
      }
    }
  }

  return rank;
}

bool _numericCodesEquivalent(String hay, String needle) {
  if (!RegExp(r'^\d+$').hasMatch(hay) || !RegExp(r'^\d+$').hasMatch(needle)) {
    return false;
  }
  final hi = int.tryParse(hay);
  final ni = int.tryParse(needle);
  return hi != null && ni != null && hi == ni;
}

bool _hayContainsQuery(String hay, String q) {
  if (q.isEmpty || hay.isEmpty) return false;
  if (_numericCodesEquivalent(hay, q)) return true;
  if (RegExp(r'^\d{2,}$').hasMatch(q)) {
    final ld = pilotLeadingDigitRunFromStart(hay);
    if (ld.isNotEmpty && ld.startsWith(q)) {
      return true;
    }
  }
  if (RegExp(r'^\d{3,}$').hasMatch(q)) {
    if (RegExp('(?<![0-9])${RegExp.escape(q)}(?![0-9])').hasMatch(hay)) {
      return true;
    }
  }
  return hay.contains(q);
}
