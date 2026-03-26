import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/circle/circle_model.dart';
import '../../core/providers/circle_provider.dart';
import 'circle_detail_screen.dart';

const _campusFilters = [
  ('all', '全て'),
  ('tsudanuma', '津田沼'),
  ('narashino', '新習志野'),
  ('shibazono', '芝園'),
];

class CircleEventsScreen extends ConsumerStatefulWidget {
  const CircleEventsScreen({super.key});

  @override
  ConsumerState<CircleEventsScreen> createState() => _CircleEventsScreenState();
}

class _CircleEventsScreenState extends ConsumerState<CircleEventsScreen> {
  String _selectedCampus = 'all';

  @override
  Widget build(BuildContext context) {
    final circlesAsync = ref.watch(circlesProvider);
    final wantToGoAsync = ref.watch(wantToGoIdsProvider);

    return circlesAsync.when(
      data: (circles) {
        var events = <_EventItem>[];
        for (final c in circles) {
          for (var i = 0; i < c.events.length; i++) {
            events.add(_EventItem(
              circle: c,
              event: c.events[i],
              eventIndex: i,
            ));
          }
        }
        if (_selectedCampus != 'all') {
          events = events
              .where((e) => e.event.campus == _selectedCampus)
              .toList();
        }
        events.sort((a, b) => a.event.dateTime.compareTo(b.event.dateTime));

        return wantToGoAsync.when(
          data: (wantIds) => _EventList(
            events: events,
            wantToGoIds: wantIds,
            selectedCampus: _selectedCampus,
            onCampusChanged: (c) => setState(() => _selectedCampus = c),
            onTapCircle: (c) => _openDetail(context, c),
            onToggleWantToGo: (circleId, eventIndex) {
              toggleWantToGo(ref, circleId, eventIndex);
            },
          ),
          loading: () => _EventList(
            events: events,
            wantToGoIds: {},
            selectedCampus: _selectedCampus,
            onCampusChanged: (c) => setState(() => _selectedCampus = c),
            onTapCircle: (c) => _openDetail(context, c),
            onToggleWantToGo: (circleId, eventIndex) {
              toggleWantToGo(ref, circleId, eventIndex);
            },
          ),
          error: (_, __) => _EventList(
            events: events,
            wantToGoIds: {},
            selectedCampus: _selectedCampus,
            onCampusChanged: (c) => setState(() => _selectedCampus = c),
            onTapCircle: (c) => _openDetail(context, c),
            onToggleWantToGo: (circleId, eventIndex) {
              toggleWantToGo(ref, circleId, eventIndex);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
    );
  }

  void _openDetail(BuildContext context, Circle circle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CircleDetailScreen(circle: circle),
      ),
    );
  }
}

class _EventItem {
  final Circle circle;
  final CircleEvent event;
  final int eventIndex;

  _EventItem({
    required this.circle,
    required this.event,
    required this.eventIndex,
  });
}

class _EventList extends StatelessWidget {
  final List<_EventItem> events;
  final Set<String> wantToGoIds;
  final String selectedCampus;
  final void Function(String) onCampusChanged;
  final void Function(Circle) onTapCircle;
  final void Function(String circleId, int eventIndex) onToggleWantToGo;

  const _EventList({
    required this.events,
    required this.wantToGoIds,
    required this.selectedCampus,
    required this.onCampusChanged,
    required this.onTapCircle,
    required this.onToggleWantToGo,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '体験会の予定はありません',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '体験会・新歓イベント',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _campusFilters.map((e) {
                    final id = e.$1;
                    final label = e.$2;
                    final isSelected = selectedCampus == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => onCampusChanged(id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final item = events[i];
              final isWant = isWantToGo(
                wantToGoIds,
                item.circle.id.toString(),
                item.eventIndex,
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onTapCircle(item.circle),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.circle.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.event.date} ${item.event.time}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${item.event.place}（${item.event.campusLabel}）',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isWant ? Icons.bookmark : Icons.bookmark_border,
                            color: isWant ? Colors.orange : null,
                          ),
                          onPressed: () => onToggleWantToGo(
                            item.circle.id.toString(),
                            item.eventIndex,
                          ),
                          tooltip: isWant ? '行きたいを解除' : '行きたい',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
