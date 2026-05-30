class CwitterPollOption {
  const CwitterPollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
  });

  final String id;
  final String text;
  final int voteCount;

  factory CwitterPollOption.fromMap(Map<String, dynamic> map) {
    return CwitterPollOption(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      voteCount: (map['voteCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
    };
  }

  CwitterPollOption copyWith({int? voteCount}) {
    return CwitterPollOption(
      id: id,
      text: text,
      voteCount: voteCount ?? this.voteCount,
    );
  }
}

class CwitterPoll {
  const CwitterPoll({
    required this.options,
    this.votedBy = const {},
  });

  static const int minOptions = 2;
  static const int maxOptions = 4;
  static const int maxOptionTextLength = 50;

  final List<CwitterPollOption> options;
  final Map<String, String> votedBy;

  bool get hasPoll => options.length >= minOptions;

  int get totalVotes =>
      options.fold<int>(0, (sum, option) => sum + option.voteCount);

  bool hasVoted(String? uid) =>
      uid != null && votedBy.containsKey(uid);

  String? votedOptionId(String? uid) =>
      uid != null ? votedBy[uid] : null;

  double voteRatioFor(String optionId) {
    if (totalVotes <= 0) return 0;
    for (final option in options) {
      if (option.id == optionId) {
        return option.voteCount / totalVotes;
      }
    }
    return 0;
  }

  factory CwitterPoll.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((item) => CwitterPollOption.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .where((option) => option.id.isNotEmpty && option.text.isNotEmpty)
            .take(maxOptions)
            .toList()
        : <CwitterPollOption>[];

    final rawVotedBy = map['votedBy'];
    final votedBy = rawVotedBy is Map
        ? Map<String, String>.fromEntries(
            rawVotedBy.entries.map(
              (entry) => MapEntry(
                entry.key.toString(),
                entry.value?.toString() ?? '',
              ),
            ),
          )
        : const <String, String>{};

    return CwitterPoll(options: options, votedBy: votedBy);
  }

  Map<String, dynamic> toMap() {
    return {
      'options': options.map((option) => option.toMap()).toList(),
      'votedBy': votedBy,
    };
  }

  CwitterPoll copyWith({
    List<CwitterPollOption>? options,
    Map<String, String>? votedBy,
  }) {
    return CwitterPoll(
      options: options ?? this.options,
      votedBy: votedBy ?? this.votedBy,
    );
  }
}
