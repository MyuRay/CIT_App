import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'cafeteria_favorite_model.dart';

String normalizeMenuName(String? value) => (value ?? '').trim().toLowerCase();

class CafeteriaFavoriteTarget {
  const CafeteriaFavoriteTarget.menu({
    required this.cafeteriaId,
    required this.menuName,
    this.menuItemId,
  }) : type = 'menu';
  const CafeteriaFavoriteTarget.cafeteria(this.cafeteriaId)
    : type = 'cafeteria',
      menuItemId = null,
      menuName = null;
  factory CafeteriaFavoriteTarget.fromFavorite(CafeteriaFavorite favorite) =>
      favorite.type == 'cafeteria'
          ? CafeteriaFavoriteTarget.cafeteria(favorite.cafeteriaId ?? '')
          : CafeteriaFavoriteTarget.menu(
            cafeteriaId: favorite.cafeteriaId ?? '',
            menuName: favorite.menuName ?? '',
            menuItemId: favorite.menuItemId,
          );

  final String type, cafeteriaId;
  final String? menuName, menuItemId;
  bool get hasMenuId => menuItemId?.trim().isNotEmpty == true;
  bool get isValid =>
      type == 'cafeteria'
          ? cafeteriaId.isNotEmpty
          : hasMenuId ||
              (cafeteriaId.isNotEmpty &&
                  normalizeMenuName(menuName).isNotEmpty);
  String get key {
    final parts =
        type == 'cafeteria'
            ? ['cafeteria', cafeteriaId]
            : hasMenuId
            ? ['menu', menuItemId!.trim()]
            : ['menu-name', cafeteriaId, normalizeMenuName(menuName)];
    return '${type}_${sha256.convert(utf8.encode(jsonEncode(parts)))}';
  }

  bool matches(CafeteriaFavorite favorite) {
    if (favorite.type != type) return false;
    if (type == 'cafeteria') return favorite.cafeteriaId == cafeteriaId;
    if (hasMenuId && favorite.menuItemId?.trim().isNotEmpty == true) {
      return favorite.menuItemId!.trim() == menuItemId!.trim();
    }
    return cafeteriaId.isNotEmpty &&
        favorite.cafeteriaId == cafeteriaId &&
        normalizeMenuName(menuName).isNotEmpty &&
        normalizeMenuName(favorite.menuName) == normalizeMenuName(menuName);
  }

  @override
  bool operator ==(Object other) =>
      other is CafeteriaFavoriteTarget && key == other.key;
  @override
  int get hashCode => key.hashCode;
}

List<CafeteriaFavorite> uniqueCafeteriaFavorites(
  List<CafeteriaFavorite> favorites,
) {
  final sorted = [...favorites]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final result = <CafeteriaFavorite>[];
  for (final favorite in sorted) {
    final target = CafeteriaFavoriteTarget.fromFavorite(favorite);
    final index = result.indexWhere(target.matches);
    if (index < 0) {
      result.add(favorite);
    } else if (target.hasMenuId &&
        result[index].menuItemId?.isNotEmpty != true) {
      result[index] = favorite;
    }
  }
  return result;
}
