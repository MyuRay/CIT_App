import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../services/cafeteria/cafeteria_menu_item_service.dart';

final cafeteriaMenuItemsProvider = StreamProvider.family<Map<String, CafeteriaMenuItem>, String>((ref, cafeteriaId) {
  return CafeteriaMenuItemService.streamItems(cafeteriaId).map((items) {
    final map = <String, CafeteriaMenuItem>{};
    for (final item in items) {
      map[item.menuName.toLowerCase()] = item;
    }
    return map;
  });
});

final cafeteriaMenuItemsListProvider = StreamProvider.family<List<CafeteriaMenuItem>, String>((ref, cafeteriaId) {
  return CafeteriaMenuItemService.streamItems(cafeteriaId);
});

class CafeteriaMenuItemActions {
  Future<String> create({
    required String cafeteriaId,
    required String menuName,
    int? price,
    String? photoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ログインが必要です');
    }
    
    final item = CafeteriaMenuItem(
      id: '',
      cafeteriaId: cafeteriaId,
      menuName: menuName,
      price: price,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
    
    return await CafeteriaMenuItemService.addMenuItem(item);
  }

  Future<void> update({
    required String id,
    required String menuName,
    int? price,
    String? photoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ログインが必要です');

    final data = <String, dynamic>{
      'menuName': menuName,
      'price': price,
      'photoUrl': photoUrl,
    }..removeWhere((k, v) => v == null);

    await CafeteriaMenuItemService.updateMenuItem(id, data);
  }

  Future<void> delete(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ログインが必要です');

    await CafeteriaMenuItemService.deleteMenuItem(id);
  }
}

final cafeteriaMenuItemActionsProvider = Provider<CafeteriaMenuItemActions>((ref) {
  return CafeteriaMenuItemActions();
});

