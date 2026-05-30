import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../community/cwitter_social_platform.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? department; // 学部・学科
  final String? studentId; // 学籍番号
  final int? graduationYear; // 卒業年度
  final int reviewCount;
  final bool emailVerified; // メール認証済みフラグ
  final String? cwitterId; // Cwitter ID（半角英数字と _、設定後は変更不可）
  final String? cwitterBio; // Cwitter プロフィールの自己紹介
  final List<String> cwitterTags; // Cwitter プロフィールのハッシュタグ（最大2件）
  final Map<String, String> cwitterSocialLinks; // Cwitter プロフィールの SNS リンク

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.department,
    this.studentId,
    this.graduationYear,
    this.reviewCount = 0,
    this.emailVerified = false,
    this.cwitterId,
    this.cwitterBio,
    this.cwitterTags = const [],
    this.cwitterSocialLinks = const {},
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      department: json['department'] as String?,
      studentId: json['studentId'] as String?,
      graduationYear: json['graduationYear'] as int?,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      emailVerified: json['emailVerified'] as bool? ?? false,
      cwitterId: _parseCwitterId(json['cwitterId']),
      cwitterBio: _parseCwitterBio(json['cwitterBio']),
      cwitterTags: _parseCwitterTags(json['cwitterTags']),
      cwitterSocialLinks: CwitterSocialPlatform.parseLinks(
        json['cwitterSocialLinks'] is Map
            ? Map<String, dynamic>.from(json['cwitterSocialLinks'] as Map)
            : null,
      ),
    );
  }

  static List<String> _parseCwitterTags(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((tag) => tag.isNotEmpty)
        .take(AppConstants.cwitterTagsMaxCount)
        .toList();
  }

  static String? _parseCwitterBio(dynamic value) {
    if (value == null) return null;
    final bio = value.toString().trim();
    return bio.isEmpty ? null : bio;
  }

  static String? _parseCwitterId(dynamic value) {
    if (value == null) return null;
    final id = value.toString().trim();
    return id.isEmpty ? null : id;
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'department': department,
      'studentId': studentId,
      'graduationYear': graduationYear,
      'reviewCount': reviewCount,
      'emailVerified': emailVerified,
      if (cwitterId != null) 'cwitterId': cwitterId,
      if (cwitterBio != null) 'cwitterBio': cwitterBio,
      if (cwitterTags.isNotEmpty) 'cwitterTags': cwitterTags,
      if (cwitterSocialLinks.isNotEmpty) 'cwitterSocialLinks': cwitterSocialLinks,
    };
  }

  bool get hasCwitterId => cwitterId != null && cwitterId!.isNotEmpty;

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    
    // Firestore Timestamp型の場合
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }
    
    // DateTime型の場合
    if (dateTime is DateTime) {
      return dateTime;
    }
    
    // String型の場合
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? department,
    String? studentId,
    int? graduationYear,
    int? reviewCount,
    bool? emailVerified,
    String? cwitterId,
    String? cwitterBio,
    List<String>? cwitterTags,
    Map<String, String>? cwitterSocialLinks,
    bool clearCwitterBio = false,
    bool clearCwitterTags = false,
    bool clearCwitterSocialLinks = false,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
      graduationYear: graduationYear ?? this.graduationYear,
      reviewCount: reviewCount ?? this.reviewCount,
      emailVerified: emailVerified ?? this.emailVerified,
      cwitterId: cwitterId ?? this.cwitterId,
      cwitterBio: clearCwitterBio ? null : (cwitterBio ?? this.cwitterBio),
      cwitterTags: clearCwitterTags ? const [] : (cwitterTags ?? this.cwitterTags),
      cwitterSocialLinks: clearCwitterSocialLinks
          ? const {}
          : (cwitterSocialLinks ?? this.cwitterSocialLinks),
    );
  }
}
