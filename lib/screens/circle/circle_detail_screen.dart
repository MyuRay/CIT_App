import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/circle/circle_model.dart';
import '../../core/providers/circle_provider.dart';

class CircleDetailScreen extends ConsumerWidget {
  final Circle circle;

  const CircleDetailScreen({super.key, required this.circle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wantToGoAsync = ref.watch(wantToGoIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(circle.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    circle.affiliationLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    circle.memberCountLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (circle.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'タグ',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: circle.tags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            if (circle.events.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '体験会・新歓',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...circle.events.asMap().entries.map((e) {
                final idx = e.key;
                final ev = e.value;
                return wantToGoAsync.when(
                  data: (ids) {
                    final isWant = isWantToGo(
                      ids,
                      circle.id.toString(),
                      idx,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ev.date} ${ev.time}',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${ev.place}（${ev.campusLabel}）',
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
                              onPressed: () {
                                toggleWantToGo(ref, circle.id.toString(), idx);
                              },
                              tooltip: isWant ? '行きたいを解除' : '行きたい',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${ev.date} ${ev.time}'),
                      subtitle: Text('${ev.place}（${ev.campusLabel}）'),
                    ),
                  ),
                  error: (_, __) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${ev.date} ${ev.time}'),
                      subtitle: Text('${ev.place}（${ev.campusLabel}）'),
                    ),
                  ),
                );
              }),
            ],
            if (circle.mail != null) ...[
              const SizedBox(height: 24),
              Text(
                '連絡先',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(circle.mail!),
            ],
            if (circle.sns != null &&
                (circle.sns!.xUrl != null || circle.sns!.instagramUrl != null)) ...[
              const SizedBox(height: 24),
              Text(
                'SNS',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (circle.sns!.xUrl != null)
                    FilledButton.icon(
                      onPressed: () => _launch(circle.sns!.xUrl!),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('X'),
                    ),
                  if (circle.sns!.xUrl != null && circle.sns!.instagramUrl != null)
                    const SizedBox(width: 8),
                  if (circle.sns!.instagramUrl != null)
                    FilledButton.icon(
                      onPressed: () => _launch(circle.sns!.instagramUrl!),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Instagram'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
