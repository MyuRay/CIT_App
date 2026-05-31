import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

/// CIT App 開発メンバー募集（マイページの隠し入口）
class CitAppRecruitmentScreen extends StatelessWidget {
  const CitAppRecruitmentScreen({super.key});

  Future<void> _openRecruitmentEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.developerRecruitmentEmail,
      queryParameters: const {
        'subject': AppConstants.developerRecruitmentEmailSubject,
        'body': 'お名前：\n学年・学科：\n自己PR・スキル：\n',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'メールアプリを開けませんでした。\n'
          '${AppConstants.developerRecruitmentEmail} 宛に直接ご連絡ください。',
        ),
      ),
    );
  }

  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.parse(AppConstants.developerRecruitmentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('リンクを開けませんでした')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('変な所を連打するあなたへ'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'CIT App 開発メンバー募集',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CIT App は学生主導で開発・運営している ${AppConstants.appDescriptionTitle} です。\n'
                    '千葉工業大学の学生生活をもっと便利にするアプリを、一緒につくりませんか？',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'こんな活動をしています',
            items: const [
              'Flutter / Firebase を使ったモバイルアプリ開発',
              '時間割・掲示板・学食・Cwitter などの機能改善',
              'ユーザーからのフィードバックをもとにした改善サイクル',
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'こんな人を歓迎します',
            items: const [
              'プログラミングに興味がある（未経験でも OK）',
              'UI / UX やデザインが好き',
              '企画・運営・広報など、開発以外の分野にも関心がある',
              '千葉工業大学の学生（学部・大学院問わず）',
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '参加方法',
            items: [
              '下の「メールで応募する」から ${AppConstants.developerRecruitmentEmail} 宛にご連絡ください',
              '件名は「${AppConstants.developerRecruitmentEmailSubject}」でお願いします',
              'お名前・学年・学科・自己PR・スキルなどをお書きください',
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openRecruitmentEmail(context),
            icon: const Icon(Icons.mail_outline),
            label: const Text('メールで応募する'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openWebsite(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('CIT App 公式サイトを見る'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '開発者からのメッセージ',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '押してみたくなるボタンを50回も連打してくれたのですから、さぞエンジニアに適正がある方だと思います。'
                    'ここまで見つけてくれて本当にありがとうございます。\n\n'
                    'CIT App は、少数の学生が授業やバイトの合間に続けてきたプロジェクトです。'
                    '「大学のためのアプリを、学生の手で」—— その想いに共感してくれる人がいたら、'
                    'ぜひメールを待っています。一緒に大学生活をもっと便利にしませんか？\n\n'
                    'この画面を見つけても他の人には教えず、どうぞ自分の好奇心の手柄にしてください。\n\n'
                    '—— CIT App 運代表:村井雅斗',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.65,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('・ '),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
