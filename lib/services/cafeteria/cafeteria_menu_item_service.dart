import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';

class CafeteriaMenuItemService {
  static final _col = FirebaseFirestore.instance.collection('cafeteria_menu_items');

  static Stream<List<CafeteriaMenuItem>> streamItems(String cafeteriaId) {
    return _col
        .where('cafeteriaId', isEqualTo: cafeteriaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CafeteriaMenuItem.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  static Stream<List<CafeteriaMenuItem>> streamAllItems() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CafeteriaMenuItem.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  static Future<String> addMenuItem(CafeteriaMenuItem item) async {
    final docRef = await _col.add(item.toJson());
    return docRef.id;
  }

  static Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData.removeWhere((key, value) => value == null);
    await _col.doc(id).update(updateData);
  }

  static Future<void> incrementViewCount(String id) async {
    await _col.doc(id).update({'viewCount': FieldValue.increment(1)});
  }

  static Future<void> deleteMenuItem(String id) async {
    await _col.doc(id).delete();
  }

  static Future<CafeteriaMenuItem?> getMenuItem(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CafeteriaMenuItem.fromJson({'id': doc.id, ...doc.data()!});
  }

  static Future<bool> menuExists(String cafeteriaId, String menuName) async {
    final querySnapshot = await _col
        .where('cafeteriaId', isEqualTo: cafeteriaId)
        .where('menuName', isEqualTo: menuName.trim())
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  static Future<bool> checkDuplicate(String cafeteriaId, String menuName) async {
    return await menuExists(cafeteriaId, menuName);
  }

  static Future<String?> uploadImage(File imageFile, String cafeteriaId, String menuName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${cafeteriaId}_${menuName}_$timestamp.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('cafeteria_menu_images')
          .child(fileName);
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('画像のアップロードに失敗しました: $e');
    }
  }
}
