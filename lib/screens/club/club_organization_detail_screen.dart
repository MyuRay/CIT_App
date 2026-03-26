import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/club/club_organization_model.dart';

class ClubOrganizationDetailScreen extends StatelessWidget {
  final ClubOrganization club;

  const ClubOrganizationDetailScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    final intro = (club.introduction ?? club.description ?? '').trim();
    final information = (club.information ?? '').trim();
    final contact = (club.contact ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: Text(club.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (club.imageUrls.isNotEmpty) ...[
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: club.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final imageUrl = club.imageUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 280,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 280,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          _sectionCard(context, 'Introduction', intro, fallback: '紹介情報はありません'),
          const SizedBox(height: 12),
          _sectionCard(
            context,
            'Information',
            information,
            fallback: '活動情報はありません',
          ),
          const SizedBox(height: 12),
          _sectionCard(context, 'Contact', contact, fallback: '連絡先情報はありません'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openExternalPage(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('公式ページを開く'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context,
    String title,
    String value, {
    required String fallback,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(value.isEmpty ? fallback : value),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalPage(BuildContext context) async {
    final rawUrl = (club.detailUrl ?? '').isNotEmpty ? club.detailUrl : club.sourceUrl;
    if (rawUrl == null || rawUrl.isEmpty) return;
    try {
      final uri = Uri.parse(rawUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'URLを開けませんでした';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ページを開けませんでした: $e')),
      );
    }
  }
}
