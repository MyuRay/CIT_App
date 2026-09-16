import '../../core/theme/app_colors.dart';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('開発メンバー募集')),
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
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          color: AppColors.accent(context, Color(0xFF2E7D32)),
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
                    'CIT Appは千葉工業大学の学生が開発・運営しています。',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '活動内容',
            items: const [
              'Flutter / Firebase を使ったモバイルアプリ開発',
              '時間割・掲示板・学食・Cwitter などの機能改善',
              'ユーザーからのフィードバックをもとにした改善サイクル',
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '応募対象',
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
              foregroundColor: AppColors.onColor(const Color(0xFF4CAF50)),
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
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

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
