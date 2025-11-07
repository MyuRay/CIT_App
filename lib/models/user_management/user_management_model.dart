import 'package:cloud_firestore/cloud_firestore.dart';

// ユーザー情報モデル
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.lastLoginAt,
    required this.createdAt,
    this.isActive = true,
    this.metadata,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      // profileImageUrlとphotoURLの両方に対応
      photoURL: json['photoURL'] as String? ?? json['profileImageUrl'] as String?,
      lastLoginAt: _parseDateTime(json['lastLoginAt']) ?? _parseDateTime(json['updatedAt']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // ユーザー名を取得（表示名 > メールアドレスの@前 > UID）
  String get displayDisplayName {
    if (displayName?.isNotEmpty == true) {
      return displayName!;
    }
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return uid;
  }

  // 最終ログイン時間の表示用文字列
  String get lastLoginDisplay {
    if (lastLoginAt == null) return '未ログイン';
    
    final now = DateTime.now();
    final difference = now.difference(lastLoginAt!);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${lastLoginAt!.month}/${lastLoginAt!.day}';
    }
  }

  // アカウント作成からの日数
  int get daysSinceCreated {
    return DateTime.now().difference(createdAt).inDays;
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ユーザー統計情報
class UserStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int todayRegistrations;
  final int monthlyRegistrations;

  const UserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.todayRegistrations,
    required this.monthlyRegistrations,
  });
}

// ユーザーアクティビティ
class UserActivity {
  final String uid;
  final String action;
  final DateTime timestamp;
  final String? details;
  final String? ipAddress;

  const UserActivity({
    required this.uid,
    required this.action,
    required this.timestamp,
    this.details,
    this.ipAddress,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      uid: json['uid'] as String,
      action: json['action'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      details: json['details'] as String?,
      ipAddress: json['ipAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
      'ipAddress': ipAddress,
    };
  }
}