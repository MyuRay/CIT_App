import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 管理者権限モデル
class AdminPermissions {
  final String userId;
  final bool isAdmin;
  final bool canManagePosts;
  final bool canManageUsers;
  final bool canViewContacts;
  final bool canManageCategories;
  final DateTime grantedAt;
  final String grantedBy;

  AdminPermissions({
    required this.userId,
    required this.isAdmin,
    required this.canManagePosts,
    required this.canManageUsers,
    required this.canViewContacts,
    required this.canManageCategories,
    required this.grantedAt,
    required this.grantedBy,
  });

  factory AdminPermissions.fromJson(Map<String, dynamic> json) {
    final isAdmin = json['isAdmin'] as bool? ?? false;
    return AdminPermissions(
      userId: json['userId'] as String? ?? '',
      isAdmin: isAdmin,
      // isAdmin は全管理者権限を含意（旧データでフラグ未設定の場合も許可）
      canManagePosts: json['canManagePosts'] as bool? ?? isAdmin,
      canManageUsers: json['canManageUsers'] as bool? ?? isAdmin,
      canViewContacts: json['canViewContacts'] as bool? ?? isAdmin,
      canManageCategories: json['canManageCategories'] as bool? ?? isAdmin,
      grantedAt: _parseGrantedAt(json['grantedAt']),
      grantedBy: json['grantedBy'] as String? ?? '',
    );
  }

  static DateTime _parseGrantedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  bool get canAccessContactManagement => isAdmin || canViewContacts;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isAdmin': isAdmin,
      'canManagePosts': canManagePosts,
      'canManageUsers': canManageUsers,
      'canViewContacts': canViewContacts,
      'canManageCategories': canManageCategories,
      'grantedAt': Timestamp.fromDate(grantedAt),
      'grantedBy': grantedBy,
    };
  }
}

// お問い合わせモデル
class ContactForm {
  final String id;
  final String? name;
  final String? email;
  final String category;
  final String categoryName;
  final String subject;
  final String message;
  final DateTime createdAt;
  final String status; // pending, in_progress, resolved
  final String userId;
  final String? response;
  final DateTime? respondedAt;
  final String? respondedBy;
  final DateTime? updatedAt;

  ContactForm({
    required this.id,
    this.name,
    this.email,
    required this.category,
    required this.categoryName,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.status,
    required this.userId,
    this.response,
    this.respondedAt,
    this.respondedBy,
    this.updatedAt,
  });

  factory ContactForm.fromJson(Map<String, dynamic> json) {
    return ContactForm(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      category: json['category'] as String? ?? 'other',
      categoryName: json['categoryName'] as String? ?? 'その他',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      userId: json['userId'] as String? ?? '',
      response: json['response'] as String?,
      respondedAt: json['respondedAt'] != null 
          ? (json['respondedAt'] as Timestamp).toDate() 
          : null,
      respondedBy: json['respondedBy'] as String?,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'category': category,
      'categoryName': categoryName,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'userId': userId,
      'response': response,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // ステータス表示用
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return '未対応';
      case 'in_progress':
        return '対応中';
      case 'resolved':
        return '解決済み';
      default:
        return status;
    }
  }

  // ステータス色
  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'in_progress':
        return const Color(0xFF2196F3); // Blue
      case 'resolved':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  // カテゴリアイコン
  String get categoryIcon {
    switch (category) {
      case 'general':
        return '💬';
      case 'bug':
        return '🐛';
      case 'feature':
        return '💡';
      case 'schedule':
        return '📅';
      case 'bulletin':
        return '📢';
      case 'other':
        return '❓';
      default:
        return '📝';
    }
  }
}
