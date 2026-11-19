import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/contact_chat_provider.dart';

import '../../widgets/admin/admin_access_gate.dart';
import '../contact/contact_chat_screen.dart';
import 'legacy_contact_management_screen.dart';

export 'legacy_contact_management_screen.dart' show ContactSort;

class ContactManagementScreen extends ConsumerWidget {
  const ContactManagementScreen({
    super.key,
    this.showAppBar = true,
    this.initialStatus,
  });
  final bool showAppBar;
  final String? initialStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAccessGate(
    title: 'お問い合わせ管理',
    allow: (p) => p.canAccessContactManagement,
    builder:
        (context) => DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar:
                showAppBar
                    ? AppBar(
                      title: const Text('お問い合わせ管理'),
                      bottom: const TabBar(
                        tabs: [Tab(text: 'お問い合わせ'), Tab(text: '過去のお問い合わせ')],
                      ),
                    )
                    : null,
            body: Column(
              children: [
                if (!showAppBar)
                  const TabBar(
                    tabs: [Tab(text: 'お問い合わせ'), Tab(text: '過去のお問い合わせ')],
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ChatInbox(initialStatus: initialStatus),
                      LegacyContactManagementScreen(
                        showAppBar: false,
                        initialStatus: initialStatus,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

class _ChatInbox extends ConsumerStatefulWidget {
  const _ChatInbox({this.initialStatus});
  final String? initialStatus;
  @override
  ConsumerState<_ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends ConsumerState<_ChatInbox> {
  String _query = '';
  late String? _status = widget.initialStatus;
  bool _onlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(adminContactChatsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminContactChatsProvider);
        await ref.read(adminContactChatsProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'ユーザー・メッセージを検索',
                      border: OutlineInputBorder(),
                    ),
                    onChanged:
                        (text) =>
                            setState(() => _query = text.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry
                          in const <String?, String>{
                            null: 'すべて',
                            'pending': '未対応',
                            'in_progress': '対応中',
                            'resolved': '解決済み',
                          }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _status == entry.key,
                          onSelected:
                              (_) => setState(() => _status = entry.key),
                        ),
                      FilterChip(
                        label: const Text('未読のみ'),
                        selected: _onlyUnread,
                        onSelected:
                            (value) => setState(() => _onlyUnread = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ...chats.when(
            data: (all) {
              final items =
                  all
                      .where(
                        (chat) =>
                            (_status == null || chat.status == _status) &&
                            (!_onlyUnread || chat.adminUnreadCount > 0) &&
                            [
                              chat.userLabel,
                              chat.email,
                              chat.lastMessage,
                              chat.userId,
                            ].any((s) => s.toLowerCase().contains(_query)),
                      )
                      .toList()
                    ..sort((a, b) {
                      final unread = (b.adminUnreadCount > 0 ? 1 : 0).compareTo(
                        a.adminUnreadCount > 0 ? 1 : 0,
                      );
                      return unread != 0
                          ? unread
                          : (b.updatedAt ?? DateTime(1970)).compareTo(
                            a.updatedAt ?? DateTime(1970),
                          );
                    });
              if (items.isEmpty)
                return <Widget>[
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('該当するお問い合わせはありません')),
                  ),
                ];
              return <Widget>[
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final chat = items[index];
                    final unread = chat.adminUnreadCount;
                    return Card(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread'),
                          child: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                        ),
                        title: Text(
                          chat.userLabel.isEmpty ? 'ユーザー' : chat.userLabel,
                          style: TextStyle(
                            fontWeight:
                                unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.lastMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${{'pending': '未対応', 'in_progress': '対応中', 'resolved': '解決済み'}[chat.status] ?? chat.status}  ${chat.updatedAt == null ? '' : DateFormat('M/d HH:mm').format(chat.updatedAt!.toLocal())}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => ContactChatScreen(
                                      userId: chat.userId,
                                      asAdmin: true,
                                    ),
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ];
            },
            loading:
                () => <Widget>[
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
            error:
                (_, __) => <Widget>[
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('お問い合わせを読み込めませんでした'),
                          TextButton(
                            onPressed:
                                () => ref.invalidate(adminContactChatsProvider),
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}
