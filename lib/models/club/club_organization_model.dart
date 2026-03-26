class ClubOrganization {
  final String id;
  final String name;
  final String category;
  final bool isActive;
  final String? sourceUrl;
  final String? detailUrl;
  final String? description;
  final String? introduction;
  final String? information;
  final String? contact;
  final List<String> imageUrls;

  const ClubOrganization({
    required this.id,
    required this.name,
    required this.category,
    required this.isActive,
    this.sourceUrl,
    this.detailUrl,
    this.description,
    this.introduction,
    this.information,
    this.contact,
    this.imageUrls = const [],
  });

  factory ClubOrganization.fromMap(String id, Map<String, dynamic> map) {
    return ClubOrganization(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      category: (map['category'] as String? ?? '').trim(),
      isActive: map['isActive'] as bool? ?? true,
      sourceUrl: (map['sourceUrl'] as String?)?.trim(),
      detailUrl: (map['detailUrl'] as String?)?.trim(),
      description: (map['description'] as String?)?.trim(),
      introduction: (map['introduction'] as String?)?.trim(),
      information: (map['information'] as String?)?.trim(),
      contact: (map['contact'] as String?)?.trim(),
      imageUrls:
          (map['imageUrls'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'club':
        return '部';
      case 'circle':
        return '同好会';
      case 'association':
        return '愛好会';
      default:
        return 'その他';
    }
  }
}
