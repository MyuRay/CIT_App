import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin/admin_model.dart';

/// 管理者権限の初期設定用サービス
class AdminSetupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 現在のユーザーに管理者権限を付与（初回セットアップ用）
  static Future<bool> setupInitialAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ ユーザーがログインしていません');
        return false;
      }
      
      final userId = currentUser.uid;
      final email = currentUser.email ?? '';
      
      print('🔧 管理者権限セットアップ開始: $userId ($email)');
      
      // 既に管理者権限があるかチェック
      final existingDoc = await _firestore
          .collection('admin_permissions')
          .doc(userId)
          .get();
      
      if (existingDoc.exists) {
        print('⚠️ 既に管理者権限が設定されています');
        final data = existingDoc.data()!;
        print('既存の権限: $data');
        return data['isAdmin'] == true;
      }
      
      // 管理者権限を作成
      final adminPermissions = AdminPermissions(
        userId: userId,
        isAdmin: true,
        canManagePosts: true,
        canViewContacts: true,
        canManageUsers: true,
        canManageCategories: true,
        grantedAt: DateTime.now(),
        grantedBy: userId, // 自分自身が付与者
      );
      
      await _firestore
          .collection('admin_permissions')
          .doc(userId)
          .set(adminPermissions.toJson());
      
      print('✅ 管理者権限を設定しました: $userId');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ 管理者権限セットアップエラー: $e');
      print('❌ StackTrace: $stackTrace');
      return false;
    }
  }
  
  /// 管理者権限の確認
  static Future<AdminPermissions?> checkAdminPermissions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ ユーザーがログインしていません');
        return null;
      }
      
      final doc = await _firestore
          .collection('admin_permissions')
          .doc(currentUser.uid)
          .get();
      
      if (!doc.exists) {
        print('❌ 管理者権限が設定されていません');
        return null;
      }
      
      final data = doc.data()!;
      print('✅ 管理者権限確認: $data');
      
      return AdminPermissions.fromJson(data);
      
    } catch (e) {
      print('❌ 管理者権限確認エラー: $e');
      return null;
    }
  }
  
  /// 管理者権限データの修正（必須フィールドの追加）
  static Future<bool> fixAdminPermissionsData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ ユーザーがログインしていません');
        return false;
      }
      
      final userId = currentUser.uid;
      print('🔧 管理者権限データ修正開始: $userId');
      
      final doc = await _firestore
          .collection('admin_permissions')
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        print('❌ 管理者権限が存在しません。setupInitialAdmin()を先に実行してください。');
        return false;
      }
      
      final existingData = doc.data()!;
      print('既存データ: $existingData');
      
      // 必須フィールドを補完
      final updatedData = {
        'userId': userId,
        'isAdmin': existingData['isAdmin'] ?? true,
        'canManagePosts': existingData['canManagePosts'] ?? true,
        'canViewContacts': existingData['canViewContacts'] ?? true,
        'canManageUsers': existingData['canManageUsers'] ?? true,
        'createdAt': existingData['createdAt'] ?? Timestamp.now(),
        'grantedAt': existingData['grantedAt'] ?? Timestamp.now(),
        'grantedBy': existingData['grantedBy'] ?? 'system',
      };
      
      await _firestore
          .collection('admin_permissions')
          .doc(userId)
          .update(updatedData);
      
      print('✅ 管理者権限データを修正しました: $updatedData');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ 管理者権限データ修正エラー: $e');
      print('❌ StackTrace: $stackTrace');
      return false;
    }
  }
  
  /// デバッグ用：全体通知作成テスト
  static Future<bool> testGlobalNotificationCreation() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ ユーザーがログインしていません');
        return false;
      }
      
      print('🧪 全体通知作成テスト開始');
      
      // シンプルなテスト通知を作成
      final testNotification = {
        'id': '', // Firestoreで自動生成
        'type': 'general',
        'title': 'テスト通知',
        'message': 'これは管理者権限テスト用の通知です',
        'createdAt': Timestamp.now(),
        'isActive': true,
        'createdBy': currentUser.uid,
      };
      
      final docRef = await _firestore
          .collection('global_notifications')
          .add(testNotification);
      
      // IDを設定して更新
      await docRef.update({'id': docRef.id});
      
      print('✅ テスト通知作成成功: ${docRef.id}');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ テスト通知作成エラー: $e');
      print('❌ StackTrace: $stackTrace');
      return false;
    }
  }
  
  /// Firestoreルールのテスト
  static Future<void> testFirestoreRules() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ ユーザーがログインしていません');
        return;
      }
      
      print('🧪 Firestoreルールテスト開始');
      print('ユーザー: ${currentUser.uid} (${currentUser.email})');
      
      // 1. admin_permissions読み取りテスト
      print('1️⃣ admin_permissions読み取りテスト...');
      try {
        final adminDoc = await _firestore
            .collection('admin_permissions')
            .doc(currentUser.uid)
            .get();
        print('✅ admin_permissions読み取り成功: ${adminDoc.exists}');
        if (adminDoc.exists) {
          print('データ: ${adminDoc.data()}');
        }
      } catch (e) {
        print('❌ admin_permissions読み取り失敗: $e');
      }
      
      // 2. global_notifications読み取りテスト
      print('2️⃣ global_notifications読み取りテスト...');
      try {
        final notificationsQuery = await _firestore
            .collection('global_notifications')
            .limit(1)
            .get();
        print('✅ global_notifications読み取り成功: ${notificationsQuery.docs.length}件');
      } catch (e) {
        print('❌ global_notifications読み取り失敗: $e');
      }
      
      // 3. global_notifications作成テスト
      print('3️⃣ global_notifications作成テスト...');
      try {
        final testDoc = await _firestore
            .collection('global_notifications')
            .add({
              'type': 'test',
              'title': 'ルールテスト',
              'message': 'Firestoreルールテスト用',
              'createdAt': Timestamp.now(),
              'isActive': false,
              'createdBy': currentUser.uid,
            });
        print('✅ global_notifications作成成功: ${testDoc.id}');
        
        // テストドキュメントを削除
        await testDoc.delete();
        print('✅ テストドキュメント削除完了');
      } catch (e) {
        print('❌ global_notifications作成失敗: $e');
      }
      
    } catch (e) {
      print('❌ Firestoreルールテストエラー: $e');
    }
  }
}