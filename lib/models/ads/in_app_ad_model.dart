import 'package:cloud_firestore/cloud_firestore.dart';

enum AdPlacement { homeTop, cafeteria, scheduleBottom, profileTop }

enum AdActionType { bulletin, external }

String adActionTypeToString(AdActionType type) {
  switch (type) {
    case AdActionType.bulletin:
      return 'bulletin';
    case AdActionType.external:
      return 'external';
  }
}

String adPlacementToString(AdPlacement placement) {
  switch (placement) {
    case AdPlacement.homeTop:
      return 'home_top';
    case AdPlacement.cafeteria:
      return 'cafeteria';
    case AdPlacement.scheduleBottom:
      return 'schedule_bottom';
    case AdPlacement.profileTop:
      return 'profile_top';
  }
}

AdPlacement? adPlacementFromString(String? value) {
  switch (value) {
    case 'home_top':
      return AdPlacement.homeTop;
    case 'cafeteria':
      return AdPlacement.cafeteria;
    case 'schedule_bottom':
      return AdPlacement.scheduleBottom;
    case 'profile_top':
      return AdPlacement.profileTop;
    default:
      return null;
  }
}

AdActionType adActionTypeFromString(String? value) {
  switch (value) {
    case 'external':
      return AdActionType.external;
    case 'bulletin':
    default:
      return AdActionType.bulletin;
  }
}

class InAppAd {
  const InAppAd({
    required this.id,
    required this.title,
    required this.body,
    required this.placement,
    required this.actionType,
    required this.actionPayload,
    required this.isActive,
    this.imageUrl,
    this.ctaText,
    this.startAt,
    this.endAt,
    this.weight = 1,
  });

  factory InAppAd.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return InAppAd(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      body: (data['body'] as String?)?.trim() ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim(),
      ctaText: (data['ctaText'] as String?)?.trim(),
      placement:
          adPlacementFromString(data['targetType'] as String?) ??
          AdPlacement.homeTop,
      actionType: adActionTypeFromString(data['actionType'] as String?),
      actionPayload: (data['actionPayload'] as String?)?.trim() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      startAt: _timestampToDate(data['startAt']),
      endAt: _timestampToDate(data['endAt']),
      weight: (data['weight'] as num?)?.toInt() ?? 1,
    );
  }

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? ctaText;
  final AdPlacement placement;
  final AdActionType actionType;
  final String actionPayload;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final int weight;

  bool isEligible(DateTime now) {
    if (!isActive) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  InAppAd copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? ctaText,
    AdPlacement? placement,
    AdActionType? actionType,
    String? actionPayload,
    bool? isActive,
    DateTime? startAt,
    DateTime? endAt,
    int? weight,
  }) {
    return InAppAd(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      ctaText: ctaText ?? this.ctaText,
      placement: placement ?? this.placement,
      actionType: actionType ?? this.actionType,
      actionPayload: actionPayload ?? this.actionPayload,
      isActive: isActive ?? this.isActive,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (ctaText != null && ctaText!.isNotEmpty) 'ctaText': ctaText,
      'targetType': adPlacementToString(placement),
      'actionType': adActionTypeToString(actionType),
      'actionPayload': actionPayload,
      'isActive': isActive,
      if (startAt != null) 'startAt': Timestamp.fromDate(startAt!),
      if (endAt != null) 'endAt': Timestamp.fromDate(endAt!),
      'weight': weight,
      'updatedAt': Timestamp.now(),
    };
  }
}

DateTime? _timestampToDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
