import 'package:cloud_firestore/cloud_firestore.dart';

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
    );
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
    };
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
    );
  }
}