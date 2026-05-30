import 'cwitter_follow_user.dart';

enum CwitterRankingPeriod {
  allTime('累計'),
  monthly('月間');

  const CwitterRankingPeriod(this.label);
  final String label;
}

enum CwitterRankingKind {
  cweetCount('Cweet数'),
  followerCount('フォロワー数'),
  likeCount('いいね数');

  const CwitterRankingKind(this.label);
  final String label;

  String formatValue(int value) {
    switch (this) {
      case CwitterRankingKind.cweetCount:
        return '$value Cweet';
      case CwitterRankingKind.followerCount:
        return '$value フォロワー';
      case CwitterRankingKind.likeCount:
        return '$value いいね';
    }
  }

  String noteFor(CwitterRankingPeriod period) {
    switch (this) {
      case CwitterRankingKind.cweetCount:
        return period == CwitterRankingPeriod.allTime
            ? 'これまでの Cweet 数の多い順です'
            : '今月投稿した Cweet 数の多い順です';
      case CwitterRankingKind.followerCount:
        return period == CwitterRankingPeriod.allTime
            ? '累計フォロワー数の多い順です'
            : '今月増えたフォロワー数の多い順です';
      case CwitterRankingKind.likeCount:
        return period == CwitterRankingPeriod.allTime
            ? 'Cweet に付いた累計いいね数の多い順です'
            : '今月投稿した Cweet のいいね数の多い順です';
    }
  }
}

class CwitterRankingEntry {
  const CwitterRankingEntry({
    required this.rank,
    required this.user,
    required this.value,
  });

  final int rank;
  final CwitterFollowUser user;
  final int value;
}

class CwitterRankings {
  const CwitterRankings({
    this.cweetCount = const [],
    this.followerCount = const [],
    this.likeCount = const [],
  });

  final List<CwitterRankingEntry> cweetCount;
  final List<CwitterRankingEntry> followerCount;
  final List<CwitterRankingEntry> likeCount;

  List<CwitterRankingEntry> entriesFor(CwitterRankingKind kind) {
    switch (kind) {
      case CwitterRankingKind.cweetCount:
        return cweetCount;
      case CwitterRankingKind.followerCount:
        return followerCount;
      case CwitterRankingKind.likeCount:
        return likeCount;
    }
  }
}

class CwitterRankingBoard {
  const CwitterRankingBoard({
    required this.allTime,
    required this.monthly,
    required this.monthLabel,
  });

  final CwitterRankings allTime;
  final CwitterRankings monthly;
  final String monthLabel;

  CwitterRankings forPeriod(CwitterRankingPeriod period) {
    switch (period) {
      case CwitterRankingPeriod.allTime:
        return allTime;
      case CwitterRankingPeriod.monthly:
        return monthly;
    }
  }
}
