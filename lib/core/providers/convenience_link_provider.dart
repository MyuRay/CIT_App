import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/convenience_link/convenience_link_model.dart';
import '../../services/convenience_link/convenience_link_service.dart';
import 'auth_provider.dart';

// 便利リンク管理のStateNotifier
class ConvenienceLinkNotifier extends StateNotifier<AsyncValue<List<ConvenienceLink>>> {
  ConvenienceLinkNotifier(this._userId, {this.userEmail}) : super(const AsyncValue.loading()) {
    _loadLinks();
  }

  final String _userId;
  final String? userEmail;

  // リンクを読み込み
  Future<void> _loadLinks() async {
    try {
      state = const AsyncValue.loading();
      final links = await ConvenienceLinkService.getUserLinks(_userId, userEmail: userEmail);
      state = AsyncValue.data(links);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // リンクを追加
  Future<void> addLink(ConvenienceLink link) async {
    try {
      await ConvenienceLinkService.addLink(_userId, link);
      await _loadLinks(); // リロード
    } catch (e) {
      // エラー状態は設定せず、現在の状態を保持
      rethrow;
    }
  }

  // リンクを更新
  Future<void> updateLink(ConvenienceLink updatedLink) async {
    try {
      await ConvenienceLinkService.updateLink(_userId, updatedLink);
      await _loadLinks(); // リロード
    } catch (e) {
      rethrow;
    }
  }

  // リンクを削除
  Future<void> deleteLink(String linkId) async {
    try {
      await ConvenienceLinkService.deleteLink(_userId, linkId);
      await _loadLinks(); // リロード
    } catch (e) {
      rethrow;
    }
  }

  // リンクの順序を更新
  Future<void> reorderLinks(List<ConvenienceLink> reorderedLinks) async {
    try {
      await ConvenienceLinkService.reorderLinks(_userId, reorderedLinks);
      await _loadLinks(); // リロード
    } catch (e) {
      rethrow;
    }
  }

  // リンクの有効/無効を切り替え
  Future<void> toggleLinkEnabled(String linkId) async {
    try {
      await ConvenienceLinkService.toggleLinkEnabled(_userId, linkId);
      await _loadLinks(); // リロード
    } catch (e) {
      rethrow;
    }
  }

  // プリセットにリセット
  Future<void> resetToDefaults() async {
    try {
      await ConvenienceLinkService.resetToDefaults(_userId);
      await _loadLinks(); // リロード
    } catch (e) {
      rethrow;
    }
  }

  // 手動リフレッシュ
  Future<void> refresh() async {
    await _loadLinks();
  }
}

// 便利リンクプロバイダー（ユーザーIDごと）
final convenienceLinkProvider = StateNotifierProvider.family<ConvenienceLinkNotifier, AsyncValue<List<ConvenienceLink>>, ({String userId, String? userEmail})>((ref, params) {
  return ConvenienceLinkNotifier(params.userId, userEmail: params.userEmail);
});

// 現在のユーザーの便利リンクプロバイダー
final currentUserConvenienceLinksProvider = Provider<AsyncValue<List<ConvenienceLink>>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;
  
  if (currentUser == null || currentUser.uid.isEmpty) {
    return const AsyncValue.data([]);
  }
  
  // Firebase UIDを使用（一意性保証）
  final userId = currentUser.uid;
  final userEmail = currentUser.email;
  
  return ref.watch(convenienceLinkProvider((userId: userId, userEmail: userEmail)));
});

// 有効な便利リンクのみを取得するプロバイダー
final enabledConvenienceLinksProvider = Provider<AsyncValue<List<ConvenienceLink>>>((ref) {
  final linksAsync = ref.watch(currentUserConvenienceLinksProvider);
  
  return linksAsync.when(
    data: (links) {
      final enabledLinks = links.where((link) => link.isEnabled).toList();
      return AsyncValue.data(enabledLinks);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});