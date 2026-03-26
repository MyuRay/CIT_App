import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/circle/circle_model.dart';
import '../../core/providers/circle_provider.dart';
import 'circle_detail_screen.dart';

/// 診断の質問と選択肢（タグにマッピング）
const _questions = [
  {
    'q': '大学生活のスタンスは？',
    'choices': [
      {'label': 'ガッツリ打ち込みたい', 'tags': ['ガチ', 'アクティブ']},
      {'label': '学業やバイトと両立して楽しみたい', 'tags': ['ゆるめ', '趣味']},
    ],
  },
  {
    'q': '活動場所の希望は？',
    'choices': [
      {'label': '屋外でアクティブに', 'tags': ['屋外']},
      {'label': '屋内でじっくり', 'tags': ['屋内']},
    ],
  },
  {
    'q': '興味がある分野は？',
    'choices': [
      {'label': 'スポーツ・運動', 'tags': ['運動系']},
      {'label': 'ものづくり・技術・科学', 'tags': ['ものづくり', '技術', '科学']},
      {'label': '芸術・音楽・文化', 'tags': ['芸術', '音楽', '文化系']},
    ],
  },
  {
    'q': 'サークルの規模感は？',
    'choices': [
      {'label': '大人数でワイワイ', 'tags': ['大人数']},
      {'label': '少人数でアットホーム', 'tags': ['初心者歓迎']},
    ],
  },
];

class CircleDiagnosisScreen extends ConsumerStatefulWidget {
  const CircleDiagnosisScreen({super.key});

  @override
  ConsumerState<CircleDiagnosisScreen> createState() =>
      _CircleDiagnosisScreenState();
}

class _CircleDiagnosisScreenState extends ConsumerState<CircleDiagnosisScreen> {
  int _currentStep = 0;
  final List<String> _selectedTags = [];

  void _selectChoice(List<String> tags) {
    setState(() {
      _selectedTags.addAll(tags);
      if (_currentStep < _questions.length - 1) {
        _currentStep++;
      } else {
        _currentStep = -1; // 結果表示
      }
    });
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _selectedTags.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep < 0) {
      return _buildResult(context);
    }

    final q = _questions[_currentStep];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'ぴったりの活動を見つけよう',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentStep + 1} / ${_questions.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            q['q'] as String,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...((q['choices'] as List).map((c) {
            final choice = c as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: () => _selectChoice(
                  (choice['tags'] as List).cast<String>(),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(choice['label'] as String),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final diagnosisAsync = ref.watch(circleDiagnosisProvider(_selectedTags));

    return diagnosisAsync.when(
      data: (circles) {
        if (circles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '該当するサークルがありませんでした',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _reset,
                  child: const Text('もう一度診断する'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'あなたにオススメのサークル',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('やり直す'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: circles.length,
                itemBuilder: (context, i) {
                  final c = circles[i];
                  return _CircleCard(
                    circle: c,
                    onTap: () => _openDetail(context, c),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('エラー: $e'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reset, child: const Text('やり直す')),
          ],
        ),
      ),
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

class _CircleCard extends StatelessWidget {
  final Circle circle;
  final VoidCallback onTap;

  const _CircleCard({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      circle.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      circle.memberCountLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                circle.affiliationLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (circle.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: circle.tags.take(5).map((t) {
                    return Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (circle.sns != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (circle.sns!.xUrl != null)
                      IconButton(
                        icon: const Icon(Icons.link, size: 20),
                        onPressed: () => _launchUrl(circle.sns!.xUrl!),
                        tooltip: 'X',
                      ),
                    if (circle.sns!.instagramUrl != null)
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: () =>
                            _launchUrl(circle.sns!.instagramUrl!),
                        tooltip: 'Instagram',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
