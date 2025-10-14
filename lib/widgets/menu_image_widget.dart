import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/providers/menu_image_provider.dart';
import '../services/cafeteria/menu_image_service.dart';

class MenuImageWidget extends ConsumerWidget {
  final String campus;
  final DateTime? date;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MenuImageWidget({
    super.key,
    required this.campus,
    this.date,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetDate = date ?? DateTime.now();
    final request = MenuImageRequest(campus: campus, date: targetDate);
    final imageAsync = ref.watch(menuImageProvider(request));

    return imageAsync.when(
      data: (imagePath) {
        if (imagePath == null) {
          return _buildErrorWidget(context, '今日のメニュー画像はありません');
        }

        if (kIsWeb) {
          // Web版では画像URLを直接表示
          final imageUrl = _getImageUrl(campus, targetDate);
          return _buildNetworkImage(context, imageUrl);
        } else {
          // モバイル版ではローカルファイルを表示（ファイルが存在する場合）
          final file = File(imagePath);
          if (file.existsSync()) {
            return _buildFileImage(context, imagePath);
          } else {
            // ローカルファイルがない場合はWeb版と同じようにネットワーク画像を表示
            final imageUrl = _getImageUrl(campus, targetDate);
            return _buildNetworkImage(context, imageUrl);
          }
        }
      },
      loading: () => _buildLoadingWidget(context),
      error: (error, _) => _buildErrorWidget(context, 'メニュー画像の読み込みに失敗しました'),
    );
  }

  Widget _buildNetworkImage(BuildContext context, String imageUrl) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget(context);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget(context, 'メニュー画像を読み込めません');
          },
        ),
      ),
    );
  }

  Widget _buildFileImage(BuildContext context, String imagePath) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget(context, 'メニュー画像を読み込めません');
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      width: width ?? 200,
      height: height ?? 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('メニューを読み込み中...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      width: width ?? 200,
      height: height ?? 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, 
                 color: Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String campus, DateTime date) {
    // 実際のファイル名形式に合わせる
    const campusFileNames = {
      'td': 'td',      // 津田沼
      'ns': 'sd1',     // 新習志野（実際はsd1）
    };
    
    final campusCode = campusFileNames[campus] ?? campus;
    final yearMonth = '${date.year}${date.month.toString().padLeft(2, '0')}';
    
    // 8月は固定で2を使用（実際のサイトに合わせて）
    final weekNumber = 2; // 現在8月は2で固定
    
    final filename = '${campusCode}_${yearMonth}_$weekNumber.png';
    final fullUrl = 'https://www.cit-s.com/wp/wp-content/themes/cit/menu/$filename';
    
    debugPrint('Widget generated menu image URL: $fullUrl for campus: $campus');
    return fullUrl;
  }
}

// 週間メニュー表示ウィジェット
class WeeklyMenuWidget extends ConsumerWidget {
  final String campus;

  const WeeklyMenuWidget({super.key, required this.campus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuPathsAsync = ref.watch(weeklyMenuPathsProvider(campus));

    return menuPathsAsync.when(
      data: (menuPaths) {
        final monday = _getMondayOfCurrentWeek();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今週のメニュー',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  final date = monday.add(Duration(days: index));
                  final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final isToday = _isToday(date);
                  
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isToday 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${MenuImageService.getWeekdayName(date)}曜日',
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday ? Colors.white : Colors.black87,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: MenuImageWidget(
                            campus: campus,
                            date: date,
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('週間メニューの読み込みに失敗しました: $error'),
    );
  }

  DateTime _getMondayOfCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}