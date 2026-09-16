import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/admin/admin_model.dart';
import '../../services/contact/contact_service.dart';

// お問い合わせ一覧プロバイダー
final allContactsProvider =
    StreamProvider.family<List<ContactForm>, ContactFilter>((ref, filter) {
      return ContactService.getAllContacts(
        statusFilter: filter.statusFilter,
        categoryFilter: filter.categoryFilter,
      );
    });

// 特定のお問い合わせ詳細プロバイダー
final contactDetailProvider = FutureProvider.family<ContactForm?, String>((
  ref,
  contactId,
) {
  return ContactService.getContactById(contactId);
});

// ユーザーのお問い合わせプロバイダー
final userContactsProvider = StreamProvider.family<List<ContactForm>, String>((
  ref,
  userId,
) {
  return ContactService.getUserContacts(userId);
});

// お問い合わせ統計プロバイダー
final contactStatsProvider = FutureProvider<ContactStats>((ref) {
  return ContactService.getContactStats();
});

// カテゴリ別統計プロバイダー
final contactCategoryStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ContactService.getCategoryStats();
});

// お問い合わせ管理アクションプロバイダー
final contactActionsProvider = Provider<ContactActions>((ref) {
  return ContactActions(ref);
});

// お問い合わせフィルター
class ContactFilter {
  final String? statusFilter;
  final String? categoryFilter;

  const ContactFilter({this.statusFilter, this.categoryFilter});

  ContactFilter copyWith({String? statusFilter, String? categoryFilter}) {
    return ContactFilter(
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

// お問い合わせ管理アクション
class ContactActions {
  final ProviderRef ref;

  ContactActions(this.ref);

  // お問い合わせを作成
  Future<String> createContact({
    String? name,
    String? email,
    required String category,
    required String categoryName,
    required String subject,
    required String message,
  }) async {
    final contactId = await ContactService.createContact(
      name: name,
      email: email,
      category: category,
      categoryName: categoryName,
      subject: subject,
      message: message,
    );

    // 関連プロバイダーを更新
    ref.invalidate(allContactsProvider);
    ref.invalidate(contactStatsProvider);
    ref.invalidate(contactCategoryStatsProvider);

    return contactId;
  }

  // ステータスを更新
  Future<void> updateStatus(String contactId, String newStatus) async {
    await ContactService.updateContactStatus(contactId, newStatus);

    // 関連プロバイダーを更新
    ref.invalidate(allContactsProvider);
    ref.invalidate(contactDetailProvider(contactId));
    ref.invalidate(contactStatsProvider);
  }

  // 返信を送信
  Future<void> sendResponse(String contactId, String response) async {
    await ContactService.respondToContact(
      contactId: contactId,
      response: response,
    );

    // 関連プロバイダーを更新
    ref.invalidate(allContactsProvider);
    ref.invalidate(contactDetailProvider(contactId));
    ref.invalidate(contactStatsProvider);
  }

  // お問い合わせを削除
  Future<void> deleteContact(String contactId) async {
    await ContactService.deleteContact(contactId);

    // 関連プロバイダーを更新
    ref.invalidate(allContactsProvider);
    ref.invalidate(contactStatsProvider);
    ref.invalidate(contactCategoryStatsProvider);
  }
}

// デフォルトのフィルター
const defaultContactFilter = ContactFilter();

// お問い合わせカテゴリ定義
class ContactCategories {
  static const Map<String, String> categories = {
    'general': '一般的な質問',
    'bug': 'バグ報告',
    'feature': '機能要望',
    'schedule': '時間割について',
    'bulletin': '掲示板について',
    'account': 'アカウント関連',
    'other': 'その他',
  };

  static const Map<String, String> categoryIcons = {
    'general': '💬',
    'bug': '🐛',
    'feature': '💡',
    'schedule': '📅',
    'bulletin': '📢',
    'account': '👤',
    'other': '❓',
  };

  static String getDisplayName(String category) {
    return categories[category] ?? category;
  }

  static String getIcon(String category) {
    return categoryIcons[category] ?? '📝';
  }
}
