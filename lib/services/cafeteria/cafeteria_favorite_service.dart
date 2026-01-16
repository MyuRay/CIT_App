import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cafeteria/cafeteria_favorite_model.dart';

/// 学食お気に入り（メニュー / 食堂）用サービス
///
/// Firestore パス:
///   users/{uid}/cafeteria_favorites/{favoriteId}
class CafeteriaFavoriteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cafeteria_favorites');
  }

  /// ストリームでユーザーのお気に入り一覧を取得
  static Stream<List<CafeteriaFavorite>> streamFavorites(String userId) {
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CafeteriaFavorite.fromJson({
                  'id': d.id,
                  ...d.data(),
                }),
              )
              .toList(),
        );
  }

  /// お気に入りを追加
  static Future<void> addFavorite({
    required String userId,
    required String type, // 'cafeteria' | 'menu'
    String? cafeteriaId,
    String? menuItemId,
    String? menuName,
  }) async {
    final data = CafeteriaFavorite(
      id: '',
      userId: userId,
      type: type,
      cafeteriaId: cafeteriaId,
      menuItemId: menuItemId,
      menuName: menuName,
      createdAt: DateTime.now(),
    ).toJson();

    await _col(userId).add(data);
  }

  /// お気に入りを削除（type + target で検索して削除）
  static Future<void> removeFavorite({
    required String userId,
    required String type,
    String? cafeteriaId,
    String? menuItemId,
  }) async {
    final query = _col(userId)
        .where('type', isEqualTo: type)
        .where(
          type == 'cafeteria' ? 'cafeteriaId' : 'menuItemId',
          isEqualTo: type == 'cafeteria' ? cafeteriaId : menuItemId,
        )
        .limit(1);

    final snap = await query.get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.delete();
  }

  /// お気に入り状態を確認
  static Future<bool> isFavorite({
    required String userId,
    required String type,
    String? cafeteriaId,
    String? menuItemId,
  }) async {
    final query = _col(userId)
        .where('type', isEqualTo: type)
        .where(
          type == 'cafeteria' ? 'cafeteriaId' : 'menuItemId',
          isEqualTo: type == 'cafeteria' ? cafeteriaId : menuItemId,
        )
        .limit(1);

    final snap = await query.get();
    return snap.docs.isNotEmpty;
  }
}

