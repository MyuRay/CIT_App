import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/admin_dashboard_provider.dart';
import '../../core/providers/user_management_provider.dart';
import '../../models/user_management/user_management_model.dart';
import '../../widgets/admin/admin_access_gate.dart';
import '../../widgets/admin/admin_list_components.dart';
import '../../widgets/common/safe_cached_network_image.dart';
import 'user_detail_screen.dart';

enum AdminUserSort { newest, lastLogin, name }

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});
  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _search = TextEditingController();
  bool? _active;
  bool _adminsOnly = false;
  AdminUserSort _sort = AdminUserSort.newest;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(allUsersProvider(defaultUserListFilter));
    ref.invalidate(adminUserIdsProvider);
    ref.invalidate(userStatsProvider);
    try {
      await ref.read(allUsersProvider(defaultUserListFilter).future);
    } catch (_) {
      /* Inline retry. */
    }
  }

  @override
  Widget build(BuildContext context) =>
      AdminAccessGate(title: 'ユーザー管理', builder: _content);

  Widget _content(BuildContext context) {
    final users = ref.watch(allUsersProvider(defaultUserListFilter));
    final adminIds = ref.watch(adminUserIdsProvider);
    final q = _search.text.trim().toLowerCase();
    final visible = users.whenData((all) {
      final list =
          all
              .where(
                (user) =>
                    (_active == null || user.isActive == _active) &&
                    (!_adminsOnly ||
                        adminIds.valueOrNull?.contains(user.uid) == true) &&
                    [
                      user.email,
                      user.displayDisplayName,
                      user.uid,
                    ].any((value) => value.toLowerCase().contains(q)),
              )
              .toList();
      list.sort((a, b) {
        final result = switch (_sort) {
          AdminUserSort.newest => b.createdAt.compareTo(a.createdAt),
          AdminUserSort.name => a.displayDisplayName.toLowerCase().compareTo(
            b.displayDisplayName.toLowerCase(),
          ),
          AdminUserSort.lastLogin => (b.lastLoginAt ?? DateTime(1970))
              .compareTo(a.lastLoginAt ?? DateTime(1970)),
        };
        return result == 0 ? a.uid.compareTo(b.uid) : result;
      });
      return list;
    });
    // An unavailable role lookup must not masquerade as an empty admin list.
    final results =
        _adminsOnly && !adminIds.hasValue
            ? adminIds.when(
              data: (_) => visible,
              loading: () => const AsyncValue<List<AppUser>>.loading(),
              error:
                  (error, stack) =>
                      AsyncValue<List<AppUser>>.error(error, stack),
            )
            : visible;
    return AdminCollectionScaffold<AppUser>(
      title: 'ユーザー管理',
      items: results,
      onRefresh: _refresh,
      itemBuilder:
          (context, user) => _card(
            context,
            user,
            adminIds.valueOrNull?.contains(user.uid) == true,
          ),
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSearchField(
            controller: _search,
            hint: '名前・メール・UIDを検索',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry
                  in const <bool?, String>{
                    null: 'すべて',
                    true: '有効',
                    false: '停止中',
                  }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _active == entry.key,
                  onSelected: (_) => setState(() => _active = entry.key),
                ),
              FilterChip(
                label: const Text('管理者'),
                selected: _adminsOnly,
                onSelected: (value) => setState(() => _adminsOnly = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AdminUserSort>(
            initialValue: _sort,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '並び順',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AdminUserSort.newest,
                child: Text('登録が新しい順'),
              ),
              DropdownMenuItem(
                value: AdminUserSort.lastLogin,
                child: Text('最近ログインした順'),
              ),
              DropdownMenuItem(value: AdminUserSort.name, child: Text('名前順')),
            ],
            onChanged:
                (value) =>
                    setState(() => _sort = value ?? AdminUserSort.newest),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                results.hasValue
                    ? '${results.requireValue.length}件を表示'
                    : '読み込み中',
              ),
              if (q.isNotEmpty || _active != null || _adminsOnly)
                TextButton(
                  onPressed:
                      () => setState(() {
                        _search.clear();
                        _active = null;
                        _adminsOnly = false;
                      }),
                  child: const Text('絞り込みを解除'),
                ),
            ],
          ),
          if (adminIds.hasError)
            TextButton.icon(
              onPressed: () => ref.invalidate(adminUserIdsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('管理者情報を再取得'),
            ),
          if (users.hasValue)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('ユーザー統計'),
              children: [_summary(users.requireValue)],
            ),
        ],
      ),
    );
  }

  Widget _summary(List<AppUser> users) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month);
    final active = users.where((user) => user.isActive).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminStatusPill('全${users.length}人'),
            AdminStatusPill('有効 $active人', color: Colors.green),
            AdminStatusPill(
              '停止中 ${users.length - active}人',
              color: Colors.orange,
            ),
            AdminStatusPill(
              '今日の登録 ${users.where((u) => !u.createdAt.isBefore(today)).length}人',
            ),
            AdminStatusPill(
              '今月の登録 ${users.where((u) => !u.createdAt.isBefore(month)).length}人',
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppUser user, bool admin) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => UserDetailScreen(user: user)),
        );
        if (mounted) ref.invalidate(adminUserIdsProvider);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child:
                        user.photoURL?.isNotEmpty == true
                            ? SafeCachedNetworkImage(
                              imageUrl: user.photoURL!,
                              width: 40,
                              height: 40,
                              memCacheWidth: 120,
                              errorWidget: const Icon(Icons.person_outline),
                            )
                            : CircleAvatar(
                              child: Text(
                                user
                                        .displayDisplayName
                                        .characters
                                        .firstOrNull ??
                                    'U',
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayDisplayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'ユーザー情報をコピー',
                  onSelected: (value) async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: value == 'uid' ? user.uid : user.email,
                      ),
                    );
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('コピーしました')));
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'uid', child: Text('UIDをコピー')),
                        PopupMenuItem(
                          value: 'email',
                          child: Text('メールアドレスをコピー'),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                AdminStatusPill(
                  user.isActive ? '有効' : '停止中',
                  color: user.isActive ? Colors.green : Colors.orange,
                ),
                if (admin) const AdminStatusPill('管理者', color: Colors.purple),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '最終ログイン：${user.lastLoginDisplay}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '登録：${user.createdAt.toLocal().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
