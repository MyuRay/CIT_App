import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/club_provider.dart';
import '../../models/club/club_organization_model.dart';
import 'club_organization_detail_screen.dart';

class ClubOrganizationsScreen extends ConsumerStatefulWidget {
  const ClubOrganizationsScreen({super.key});

  @override
  ConsumerState<ClubOrganizationsScreen> createState() =>
      _ClubOrganizationsScreenState();
}

class _ClubOrganizationsScreenState
    extends ConsumerState<ClubOrganizationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(clubOrganizationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('サークル・部活一覧')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '団体名で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: clubsAsync.when(
              data: (clubs) => _buildList(context, clubs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('読み込みに失敗しました: $error'),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ClubOrganization> clubs) {
    final filtered =
        clubs.where((club) {
          if (_query.isEmpty) return true;
          return club.name.toLowerCase().contains(_query.toLowerCase());
        }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('該当する団体がありません'));
    }

    final grouped = <String, List<ClubOrganization>>{};
    for (final club in filtered) {
      grouped.putIfAbsent(club.categoryLabel, () => <ClubOrganization>[]).add(
        club,
      );
    }

    final categoryOrder = ['部', '同好会', '愛好会', 'その他'];
    final sections =
        categoryOrder.where((label) => grouped.containsKey(label)).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final category = sections[index];
        final items = grouped[category]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((club) => _buildClubTile(context, club)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClubTile(BuildContext context, ClubOrganization club) {
    final description = (club.description ?? '').trim();
    final hasDescription = description.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.groups_outlined),
      title: Text(club.name),
      subtitle:
          hasDescription
              ? Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
              : Text(
                '説明情報は未取得です',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClubOrganizationDetailScreen(club: club),
            ),
          ),
    );
  }
}
