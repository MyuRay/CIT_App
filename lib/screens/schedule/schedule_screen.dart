import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/schedule/schedule_model.dart';
import '../../widgets/schedule/schedule_grid_widget.dart';
import 'schedule_edit_screen.dart';
import '../../core/providers/in_app_ad_provider.dart';
import '../../models/ads/in_app_ad_model.dart';
import '../../widgets/ads/in_app_ad_card.dart';
import '../../services/schedule/schedule_notification_service.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _isEditMode = false;
  bool _isSharing = false; // 共有中フラグ
  final GlobalKey _scheduleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 通知設定が有効な場合、通知を再スケジュール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScheduleNotifications();
    });
  }

  Future<void> _checkAndScheduleNotifications() async {
    final notificationEnabled = ref.read(scheduleNotificationEnabledProvider);
    if (notificationEnabled) {
      final scheduleAsync = ref.read(currentUserScheduleProvider);
      scheduleAsync.whenData((schedule) async {
        if (schedule != null) {
          await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(currentUserScheduleProvider);
    final showSaturday = ref.watch(showSaturdayProvider);
    final scheduleAdAsync = ref.watch(
      inAppAdProvider(AdPlacement.scheduleBottom),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? '時間割 - 編集モード' : '時間割',
          style: _isEditMode ? const TextStyle(color: Colors.black) : null,
        ),
        centerTitle: true,
        backgroundColor: _isEditMode ? Colors.orange.shade50 : null,
        foregroundColor: _isEditMode ? Colors.black : null,
        actions: [
          // 講義通知ON/OFFボタン（表示モードのみ）
          if (!_isEditMode)
            Consumer(
              builder: (context, ref, child) {
                final notificationEnabled = ref.watch(scheduleNotificationEnabledProvider);
                return IconButton(
                  icon: Icon(
                    notificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: notificationEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                  onPressed: () {
                    if (notificationEnabled) {
                      // 既に有効な場合は無効化確認
                      _showDisableNotificationDialog(context);
                    } else {
                      // 無効な場合は説明ポップアップを表示
                      _showNotificationInfoDialog(context);
                    }
                  },
                  tooltip: notificationEnabled ? '講義通知をOFF' : '講義通知をON',
                );
              },
            ),

          // 土曜日表示切り替えボタン（編集モードのみ）
          if (_isEditMode)
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          showSaturday
                              ? Theme.of(context).primaryColor.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                      border: Border.all(
                        color:
                            showSaturday
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '土',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              showSaturday
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (!showSaturday)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.visibility_off,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await ref.read(settingsProvider.notifier).toggleShowSaturday();
                final newState = ref.read(showSaturdayProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newState ? '土曜日を表示しました' : '土曜日を非表示にしました'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: showSaturday ? '土曜日を非表示' : '土曜日を表示',
            ),

          // 編集/表示モード切り替えボタン
          IconButton(
            icon: Icon(_isEditMode ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEditMode ? '編集モードに切り替えました' : '表示モードに切り替えました',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: _isEditMode ? Colors.orange : Colors.blue,
                ),
              );
            },
            tooltip: _isEditMode ? '表示モードに切り替え' : '編集モードに切り替え',
          ),

          // 表示モード時のみ表示される共有ボタン
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareSchedule(context),
              tooltip: '時間割を共有',
            ),

          // 編集モード時のみ表示されるアクション
          if (_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.file_upload),
              onPressed: () => _showDevelopmentMessage(context, 'Excelインポート機能'),
              tooltip: 'Excelファイルをインポート（開発中）',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('時間割をクリア'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('エクスポート'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body: scheduleAsync.when(
        data: (schedule) {
          if (schedule == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('時間割データがありません', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'はじめての利用ですか？以下のボタンから時間割を作成できます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('時間割を作成'),
                      onPressed: () async {
                        final userId = ref.read(currentUserIdProvider);
                        if (userId == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ログインが必要です')),
                            );
                          }
                          return;
                        }
                        await ref
                            .read(scheduleNotifierProvider(userId).notifier)
                            .createInitialSchedule();
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final adSection = scheduleAdAsync.when(
            data:
                (ad) =>
                    ad == null
                        ? const SizedBox.shrink()
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InAppAdCard(
                            ad: ad,
                            placement: AdPlacement.scheduleBottom,
                          ),
                        ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _scheduleKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScheduleGridWidget(
                            schedule: schedule,
                            onClassTap: (weekdayKey, period, scheduleClass) {
                              _navigateToEdit(
                                context,
                                weekdayKey,
                                period,
                                scheduleClass,
                              );
                            },
                            onEmptySlotTap: (weekdayKey, period) {
                              _navigateToEdit(
                                context,
                                weekdayKey,
                                period,
                                null,
                              );
                            },
                            isEditMode: _isEditMode,
                            showSaturday: showSaturday,
                            forceFullHeight: _isSharing, // ���L���͑S�̕
                            enableScroll: false,
                          ),
                          // CIT App�t�b�^�[�i���L���̂ݕ
                          if (_isSharing)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CIT App - ��t�H�Ƒ�w�w���x���A�v��',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                adSection,
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラーが発生しました: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(currentUserScheduleProvider);
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // 時間割を共有する機能
  Future<void> _shareSchedule(BuildContext context) async {
    try {
      print('🔄 共有開始...');

      // ローディング表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('時間割の画像を作成中...'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // フッターを表示するためにUIを更新
      setState(() {
        _isSharing = true;
      });

      // UI更新を十分に待つ（レンダリング完了まで）
      await Future.delayed(const Duration(milliseconds: 500));

      // スクリーンショットを撮影
      final RenderObject? renderObject =
          _scheduleKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        throw Exception('時間割表示エリアが見つかりません');
      }

      final RenderRepaintBoundary boundary =
          renderObject as RenderRepaintBoundary;
      print('📸 スクリーンショット撮影中...');

      // より高解像度で撮影（共有用）
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('画像データの生成に失敗しました');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      print('✅ 画像生成完了: ${pngBytes.length}バイト');

      // 一時ディレクトリに画像を保存
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/cit_schedule_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(tempPath);
      await file.writeAsBytes(pngBytes);
      print('💾 画像保存完了: $tempPath');

      // フッターを非表示に戻す
      setState(() {
        _isSharing = false;
      });

      // 共有テキスト
      const String shareText =
          '私の時間割📚\n\nCIT Appで作成しました！\n\n'
          '📱 便利な機能：\n'
          '• 時間割管理\n'
          '• 掲示板\n'
          '• 学食情報\n'
          '• キャンパスマップ\n\n'
          '🔗 アプリをダウンロード: [🔎CIT App]';

      // share_plusを使った共有を再試行
      print('🚀 share_plus再試行中...');
      await _shareWithSharePlus(context, tempPath, shareText);

      print('✅ 共有完了');

      // 成功メッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('時間割を共有しました！'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ 共有エラー: $e');
      print('📍 スタックトレース: $stackTrace');

      // フッターを非表示に戻す
      setState(() {
        _isSharing = false;
      });

      if (context.mounted) {
        String errorMessage = '共有に失敗しました';

        if (e.toString().contains('Permission') ||
            e.toString().contains('permission')) {
          errorMessage = 'ストレージへのアクセス権限が必要です';
        } else if (e.toString().contains('No application')) {
          errorMessage = '共有できるアプリが見つかりません';
        } else if (e.toString().contains('見つかりません')) {
          errorMessage = '時間割が表示されていません。しばらく待ってから再試行してください。';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMessage)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'エラー詳細: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _shareSchedule(context),
            ),
          ),
        );
      }
    }
  }

  // share_plusを使った共有機能（再試行版）
  Future<void> _shareWithSharePlus(
    BuildContext context,
    String imagePath,
    String shareText,
  ) async {
    try {
      print('🔄 複数の共有方法を試行中...');

      // 方法1: share_plusを試行
      try {
        final XFile imageFile = XFile(imagePath);
        await Share.shareXFiles(
          [imageFile],
          text: shareText,
          subject: 'CIT App - 私の時間割',
        );
        print('✅ share_plus成功');
        return;
      } catch (e1) {
        print('⚠️ share_plus失敗: $e1');
      }

      // 方法2: プラットフォームチャンネルを使用
      try {
        const platform = MethodChannel('flutter/share');
        await platform.invokeMethod('share', {
          'text': shareText,
          'subject': 'CIT App - 私の時間割',
        });
        print('✅ プラットフォームチャンネル成功（テキストのみ）');

        // 画像は別途ダイアログで案内
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('テキストを共有しました！画像は手動で添付してください'),
              backgroundColor: Colors.blue,
              action: SnackBarAction(
                label: '画像場所を表示',
                textColor: Colors.white,
                onPressed: () => _showImageLocation(context, imagePath),
              ),
            ),
          );
        }
        return;
      } catch (e2) {
        print('⚠️ プラットフォームチャンネル失敗: $e2');
      }

      // 方法3: フォールバック
      if (Platform.isAndroid) {
        await _shareOnAndroid(context, imagePath, shareText);
      } else {
        final imageBytes = await File(imagePath).readAsBytes();
        await _fallbackShare(context, imageBytes, shareText, imagePath);
      }
    } catch (e) {
      print('❌ すべての共有方法が失敗: $e');
      final imageBytes = await File(imagePath).readAsBytes();
      await _fallbackShare(context, imageBytes, shareText, imagePath);
    }
  }

  // 画像の場所を表示
  void _showImageLocation(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.image, color: Colors.blue),
                SizedBox(width: 8),
                Text('画像の場所'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('時間割画像は以下の場所に保存されています：'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    imagePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ファイルマネージャーでこの場所を開き、画像を手動で共有アプリに添付してください。',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: imagePath));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('パスをコピーしました'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('パスをコピー'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  // Android用の共有機能（標準共有ダイアログでLINEなどを選択可能）
  Future<void> _shareOnAndroid(
    BuildContext context,
    String imagePath,
    String shareText,
  ) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('画像ファイルが見つかりません: $imagePath');
      }

      print('📱 Android共有機能を使用中...');

      // 複数の方法を試行する
      bool shared = false;

      // 方法1: 画像とテキストを同時に共有
      try {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.SEND',
          type: 'image/png',
          arguments: <String, dynamic>{
            'android.intent.extra.STREAM': imagePath,
            'android.intent.extra.TEXT': shareText,
            'android.intent.extra.SUBJECT': 'CIT App - 私の時間割',
          },
        );

        await intent.launch();
        shared = true;
        print('✅ 方法1成功: 画像とテキスト同時共有');
      } catch (e1) {
        print('⚠️ 方法1失敗: $e1');
      }

      // 方法2: 画像のみ共有
      if (!shared) {
        try {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.SEND',
            type: 'image/*',
            arguments: <String, dynamic>{
              'android.intent.extra.STREAM': imagePath,
              'android.intent.extra.SUBJECT': 'CIT App - 私の時間割',
            },
          );

          await intent.launch();
          shared = true;
          print('✅ 方法2成功: 画像のみ共有');

          // テキストは別途クリップボードにコピー
          await Clipboard.setData(ClipboardData(text: shareText));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('画像を共有しました！テキストはクリップボードにコピー済みです'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e2) {
          print('⚠️ 方法2失敗: $e2');
        }
      }

      if (!shared) {
        throw Exception('すべての共有方法が失敗しました');
      }
    } catch (e) {
      print('❌ Android共有エラー: $e');
      // フォールバックに切り替え
      final imageBytes = await File(imagePath).readAsBytes();
      await _fallbackShare(context, imageBytes, shareText, imagePath);
    }
  }

  // 外部ストレージに画像をコピー（共有用）
  Future<String> _copyToExternalStorage(File imageFile) async {
    try {
      // Downloadsフォルダに一時的にコピー
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('外部ストレージにアクセスできません');
      }

      final String fileName =
          'cit_schedule_${DateTime.now().millisecondsSinceEpoch}.png';
      final String externalPath = '${externalDir.path}/$fileName';
      final File externalFile = File(externalPath);

      await imageFile.copy(externalPath);
      print('📂 外部ストレージにコピー完了: $externalPath');

      return externalPath;
    } catch (e) {
      print('⚠️ 外部ストレージコピー失敗、元のパスを使用: $e');
      return imageFile.path;
    }
  }

  // フォールバック共有機能（画像保存 + テキストコピー + 案内表示）
  Future<void> _fallbackShare(
    BuildContext context,
    Uint8List imageBytes,
    String shareText,
    String imagePath,
  ) async {
    try {
      // 画像をクリップボードにコピー（テスト用）
      await Clipboard.setData(ClipboardData(text: shareText));

      if (context.mounted) {
        // 共有方法の選択ダイアログを表示
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('時間割を共有'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '時間割画像を作成しました！\n以下の方法で共有できます：',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '画像の場所',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '画像は以下のパスに保存されました：\n$imagePath',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.copy, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '共有テキスト（コピー済み）',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              shareText,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // テキストを再度クリップボードにコピー
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('テキストをクリップボードにコピーしました'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('テキストをコピー'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('フォールバック共有エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('共有に失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmDialog(context);
        break;
      case 'export':
        _showDevelopmentMessage(context, 'エクスポート機能');
        break;
    }
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('時間割をクリア'),
            content: const Text('すべての科目を削除します。この操作は元に戻せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final userId = ref.read(currentUserIdProvider);
                  final currentYear = ref.read(currentAcademicYearProvider);
                  if (userId != null) {
                    ref
                        .read(scheduleNotifierProvider(userId).notifier)
                        .clearSchedule();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${currentYear.displayName}の時間割をクリアしました'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('クリア'),
              ),
            ],
          ),
    );
  }

  void _showDevelopmentMessage(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.construction, color: Colors.orange),
                const SizedBox(width: 8),
                Text('$featureName（開発中）'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$featureNameは現在開発中です。',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '現在利用可能な機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('• 手動での科目追加・編集・削除', style: TextStyle(fontSize: 12)),
                      Text(
                        '• リアルタイム同期によるデータ保存',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text('• カラー設定とメモ機能', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('了解'),
              ),
            ],
          ),
    );
  }

  void _navigateToEdit(
    BuildContext context,
    String weekdayKey,
    int period,
    ScheduleClass? scheduleClass,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => ScheduleEditScreen(
              weekdayKey: weekdayKey,
              period: period,
              initialClass: scheduleClass,
            ),
      ),
    );

    if (result == true) {
      // 時間割が更新された場合、通知を再スケジュール
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final notificationEnabled = ref.read(scheduleNotificationEnabledProvider);
        if (notificationEnabled) {
          final scheduleAsync = ref.read(currentUserScheduleProvider);
          scheduleAsync.whenData((schedule) async {
            if (schedule != null) {
              await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
            }
          });
        }
      }
    }
  }

  // 通知説明ポップアップを表示
  void _showNotificationInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // ダイアログ内でデータを取得
        final scheduleAsync = ref.read(currentUserScheduleProvider);
        
        return scheduleAsync.when(
          data: (schedule) {
            // 次の講義を取得してサンプルとして表示
            String sampleSubjectName = 'データ構造とアルゴリズム';
            String sampleClassroom = '1号館 201';

            if (schedule != null) {
              // 次の講義を探す
              final now = DateTime.now();
              for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
                final targetDate = now.add(Duration(days: dayOffset));
                final targetWeekday = targetDate.weekday;
                String? weekdayKey;
                switch (targetWeekday) {
                  case 1:
                    weekdayKey = 'monday';
                    break;
                  case 2:
                    weekdayKey = 'tuesday';
                    break;
                  case 3:
                    weekdayKey = 'wednesday';
                    break;
                  case 4:
                    weekdayKey = 'thursday';
                    break;
                  case 5:
                    weekdayKey = 'friday';
                    break;
                  case 6:
                    weekdayKey = 'saturday';
                    break;
                }

                if (weekdayKey != null) {
                  final daySchedule = schedule.timetable[weekdayKey];
                  if (daySchedule != null) {
                    for (int period = 1; period <= 10; period++) {
                      final scheduleClass = daySchedule[period];
                      if (scheduleClass != null && scheduleClass.isStartCell) {
                        sampleSubjectName = scheduleClass.subjectName;
                        sampleClassroom = scheduleClass.classroom;
                        break;
                      }
                    }
                    if (sampleSubjectName != 'データ構造とアルゴリズム') break;
                  }
                }
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('講義通知について'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '講義開始10分前に通知が届きます。',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '通知の例',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📚 講義開始10分前',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '次の講義は「$sampleSubjectName」です。教室は「$sampleClassroom」です。出席ボタンを押しましょう！',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• 各講義の開始10分前に通知が届きます\n• 今週の全ての講義に対して通知をスケジュールします\n• 時間割を更新すると自動的に通知も更新されます',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _enableNotifications(context);
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('通知をオンにする'),
                ),
              ],
            );
          },
          loading: () => AlertDialog(
            title: const Text('講義通知について'),
            content: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (_, __) => AlertDialog(
            title: const Text('講義通知について'),
            content: const Text('時間割データの読み込みに失敗しました。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
    );
  }

  // 通知無効化確認ダイアログを表示
  void _showDisableNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.grey),
              SizedBox(width: 8),
              Text('通知を無効にしますか？'),
            ],
          ),
          content: const Text(
            '講義通知を無効にすると、今後通知が届かなくなります。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _disableNotifications(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('無効にする'),
            ),
          ],
        );
      },
    );
  }

  // 通知を有効化
  Future<void> _enableNotifications(BuildContext context) async {
    await ref.read(setScheduleNotificationEnabledProvider)(true);

    // 通知を有効化
    final scheduleAsync = ref.read(currentUserScheduleProvider);
    scheduleAsync.whenData((schedule) async {
      if (schedule != null) {
        await ScheduleNotificationService.scheduleWeeklyNotifications(schedule);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('講義通知を有効にしました。講義開始10分前に通知が届きます。'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('時間割データが見つかりません。時間割を設定してください。'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  // 通知を無効化
  Future<void> _disableNotifications(BuildContext context) async {
    await ref.read(setScheduleNotificationEnabledProvider)(false);
    await ScheduleNotificationService.cancelAllNotifications();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('講義通知を無効にしました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
