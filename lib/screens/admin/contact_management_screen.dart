import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/contact_provider.dart';
import '../../models/admin/admin_model.dart';
import '../../widgets/admin/admin_access_gate.dart';
import '../../widgets/admin/admin_list_components.dart';
import 'contact_detail_screen.dart';

enum ContactSort { priority, newest, oldest }

class ContactManagementScreen extends ConsumerStatefulWidget {
  const ContactManagementScreen({
    super.key,
    this.showAppBar = true,
    this.initialStatus,
  });
  final bool showAppBar;
  final String? initialStatus;
  @override
  ConsumerState<ContactManagementScreen> createState() =>
      _ContactManagementScreenState();
}

class _ContactManagementScreenState
    extends ConsumerState<ContactManagementScreen> {
  final _search = TextEditingController();
  late String? _status = widget.initialStatus;
  String? _category;
  ContactSort _sort = ContactSort.priority;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(allContactsProvider(defaultContactFilter));
    try {
      await ref.read(allContactsProvider(defaultContactFilter).future);
    } catch (_) {
      /* Inline retry. */
    }
  }

  @override
  Widget build(BuildContext context) => AdminAccessGate(
    title: 'お問い合わせ管理',
    allow: (permissions) => permissions.canAccessContactManagement,
    builder: _content,
  );

  Widget _content(BuildContext context) {
    final contacts = ref.watch(allContactsProvider(defaultContactFilter));
    final q = _search.text.trim().toLowerCase();
    final visible = contacts.whenData((all) {
      final list =
          all
              .where(
                (contact) =>
                    (_status == null || contact.status == _status) &&
                    (_category == null || contact.category == _category) &&
                    [
                      contact.subject,
                      contact.message,
                      contact.name ?? '',
                      contact.email ?? '',
                      contact.userId,
                      contact.id,
                    ].any((text) => text.toLowerCase().contains(q)),
              )
              .toList();
      int priority(String status) => switch (status) {
        'pending' => 0,
        'in_progress' => 1,
        'resolved' => 2,
        _ => 3,
      };
      list.sort((a, b) {
        final status =
            _sort == ContactSort.priority
                ? priority(a.status).compareTo(priority(b.status))
                : 0;
        if (status != 0) return status;
        final date =
            _sort == ContactSort.newest
                ? b.createdAt.compareTo(a.createdAt)
                : a.createdAt.compareTo(b.createdAt);
        return date == 0 ? a.id.compareTo(b.id) : date;
      });
      return list;
    });
    return AdminCollectionScaffold<ContactForm>(
      title: 'お問い合わせ管理',
      showAppBar: widget.showAppBar,
      items: visible,
      onRefresh: _refresh,
      itemBuilder: _card,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSearchField(
            controller: _search,
            hint: '件名・本文・送信者を検索',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry
                  in const <String?, String>{
                    null: 'すべて',
                    'pending': '未対応',
                    'in_progress': '対応中',
                    'resolved': '解決済み',
                  }.entries)
                ChoiceChip(
                  selected: _status == entry.key,
                  label: Text(
                    contacts.hasValue
                        ? '${entry.value} ${contacts.requireValue.where((c) => entry.key == null || c.status == entry.key).length}'
                        : entry.value,
                  ),
                  onSelected: (_) => setState(() => _status = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns =
                  constraints.maxWidth >= 340 &&
                  MediaQuery.textScalerOf(context).scale(14) < 20;
              final width =
                  twoColumns
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_category),
                      initialValue: _category ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリ',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('すべて')),
                        for (final entry
                            in ContactCategories.categories.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged:
                          (value) => setState(
                            () => _category = value == '' ? null : value,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<ContactSort>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '並び順',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ContactSort.priority,
                          child: Text('未対応・古い順'),
                        ),
                        DropdownMenuItem(
                          value: ContactSort.newest,
                          child: Text('新しい順'),
                        ),
                        DropdownMenuItem(
                          value: ContactSort.oldest,
                          child: Text('古い順'),
                        ),
                      ],
                      onChanged:
                          (value) => setState(
                            () => _sort = value ?? ContactSort.priority,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                visible.hasValue
                    ? '${visible.requireValue.length}件を表示'
                    : '読み込み中',
              ),
              if (q.isNotEmpty || _status != null || _category != null)
                TextButton(
                  onPressed:
                      () => setState(() {
                        _search.clear();
                        _status = null;
                        _category = null;
                      }),
                  child: const Text('絞り込みを解除'),
                ),
            ],
          ),
          if (contacts.hasValue)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('受付状況の詳細'),
              children: [_summary(contacts.requireValue)],
            ),
        ],
      ),
    );
  }

  Widget _summary(List<ContactForm> contacts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = today.subtract(Duration(days: today.weekday - 1));
    final month = DateTime(now.year, now.month);
    int since(DateTime date) =>
        contacts.where((c) => !c.createdAt.isBefore(date)).length;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminStatusPill('全${contacts.length}件'),
            AdminStatusPill('今日 ${since(today)}件'),
            AdminStatusPill('今週 ${since(week)}件'),
            AdminStatusPill('今月 ${since(month)}件'),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, ContactForm contact) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ContactDetailScreen(contact: contact),
          ),
        );
        if (mounted) ref.invalidate(contactStatsProvider);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                AdminStatusPill(
                  contact.statusDisplayName,
                  color: contact.statusColor,
                ),
                AdminStatusPill(contact.categoryName, color: Colors.grey),
                if (contact.response?.trim().isNotEmpty == true)
                  const AdminStatusPill('返信済み', color: Colors.green),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              contact.subject.isEmpty ? 'タイトルなし' : contact.subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(contact.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text(
              '${contact.name?.isNotEmpty == true ? contact.name : '匿名'} ・ ${contact.createdAt.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '内容を確認・返信 →',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    ),
  );
}
