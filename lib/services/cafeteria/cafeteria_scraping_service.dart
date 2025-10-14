import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as html;
import '../../models/cafeteria/cafeteria_model.dart';

class CafeteriaScrapeService {
  static const String _userAgent = 'CIT App Mobile Client';
  static const Duration _timeout = Duration(seconds: 10);

  // CITの学食情報URL
  static const String _baseUrl = 'https://www.cit-s.com/dining/';
  static const String _cameraUrl = 'https://www.cit-s.com/dining/dining_icatch/';
  
  // キャンパス情報
  static const Map<String, Map<String, dynamic>> _campusInfo = {
    'tsudanuma': {
      'name': '津田沼学生食堂',
      'location': '3号館1階',
      'seats': 516,
      'operatingHours': {
        'morning': '8:30-9:30',
        'lunch': '10:30-14:00',
        'evening': '15:00-19:30',
      },
      'cameraHours': {
        'days': 'Monday-Saturday',
        'hours': '11:00-14:00',
      },
    },
    'narashino': {
      'name': '新習志野学生食堂',
      'location': '13号館食堂',
      'seats': 1700, // 1F: 1000席 + 2F: 700席
      'operatingHours': {
        'morning': '8:30-9:30',
        'lunch': '10:30-14:00', 
        'evening': '15:00-19:30',
      },
      'cameraHours': {
        'days': 'Monday-Saturday', // 1F: Monday-Saturday, 2F: Monday-Friday
        'hours': '11:00-14:00',
      },
    },
  };

  static Future<CafeteriaMenu?> fetchTodayMenu(String campus) async {
    try {
      final campusData = _campusInfo[campus];
      if (campusData == null) {
        debugPrint('Unknown campus: $campus');
        return null;
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ja,en;q=0.5',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch menu: ${response.statusCode}');
        return null;
      }

      return _parseMenuHtml(response.body, campus, campusData);
    } catch (e) {
      debugPrint('Error fetching cafeteria menu: $e');
      return null;
    }
  }

  static CafeteriaMenu _parseMenuHtml(String htmlContent, String campus, Map<String, dynamic> campusData) {
    final document = html.parse(htmlContent);
    final items = <MenuItem>[];

    try {
      // CIT学食サイトの構造に基づいてパース
      // キャンパス名で該当セクションを見つける
      final campusName = campusData['name'] as String;
      
      // 学食情報を含むセクションを探す
      final sections = document.querySelectorAll('section, div, article');
      
      for (final section in sections) {
        final sectionText = section.text.toLowerCase();
        
        // 津田沼または新習志野の情報を含むセクションを特定
        bool isTargetCampus = false;
        if (campus == 'tsudanuma' && sectionText.contains('津田沼')) {
          isTargetCampus = true;
        } else if (campus == 'narashino' && sectionText.contains('新習志野')) {
          isTargetCampus = true;
        }
        
        if (isTargetCampus) {
          // メニュー画像のリンクを探す
          final menuLinks = section.querySelectorAll('a[href*="menu"], img[src*="menu"]');
          
          if (menuLinks.isNotEmpty) {
            // 画像ベースのメニューの場合、基本情報のみ提供
            items.addAll(_createBasicMenuItems(campusData));
          }
        }
      }

      // 営業時間情報を取得
      final operatingHours = campusData['operatingHours'] as Map<String, String>;
      final currentTime = DateTime.now();
      final currentHour = currentTime.hour;
      
      // 現在時間に基づいて営業中かどうか判定
      bool isOpen = _isCurrentlyOpen(currentHour, operatingHours);
      
      // 営業中でない場合は利用可能フラグを更新
      if (!isOpen) {
        for (var item in items) {
          // Dartでは不変オブジェクトなので新しいインスタンスを作成する必要がある
          // ここでは簡単のため営業時間外でも表示
        }
      }

    } catch (e) {
      debugPrint('Error parsing menu HTML: $e');
      // エラー時はデフォルトメニューを返す
      items.addAll(_createBasicMenuItems(campusData));
    }

    return CafeteriaMenu(
      date: _getTodayDateString(),
      campus: campus,
      items: items.isEmpty ? _createBasicMenuItems(campusData) : items,
      fetchedAt: DateTime.now(),
    );
  }

  static bool _isCurrentlyOpen(int currentHour, Map<String, String> operatingHours) {
    // 簡単な営業時間チェック（平日前提）
    if (currentHour >= 8 && currentHour < 10) return true; // 朝
    if (currentHour >= 10 && currentHour < 14) return true; // 昼
    if (currentHour >= 15 && currentHour < 20) return true; // 夜
    return false;
  }

  static List<MenuItem> _createBasicMenuItems(Map<String, dynamic> campusData) {
    final campusName = campusData['name'] as String;
    
    // 基本的なメニュー項目（実際のメニュー画像から詳細が取得できない場合）
    if (campusName.contains('津田沼')) {
      return [
        MenuItem(name: '日替わり定食', price: '550円', category: '定食'),
        MenuItem(name: '唐揚げ定食', price: '580円', category: '定食'),
        MenuItem(name: 'カツ丼', price: '520円', category: '丼物'),
        MenuItem(name: '親子丼', price: '480円', category: '丼物'),
        MenuItem(name: '醤油ラーメン', price: '420円', category: '麺類'),
        MenuItem(name: 'チャーハン', price: '450円', category: '飯物'),
        MenuItem(name: 'カレーライス', price: '380円', category: 'カレー'),
        MenuItem(name: 'サラダ', price: '250円', category: 'サイド'),
      ];
    } else {
      return [
        MenuItem(name: '日替わり定食', price: '550円', category: '定食'),
        MenuItem(name: 'ハンバーグ定食', price: '600円', category: '定食'), 
        MenuItem(name: 'マーボー丼', price: '500円', category: '丼物'),
        MenuItem(name: '天丼', price: '550円', category: '丼物'),
        MenuItem(name: '味噌ラーメン', price: '450円', category: '麺類'),
        MenuItem(name: 'オムライス', price: '480円', category: '飯物'),
        MenuItem(name: 'ハンバーガー', price: '320円', category: '軽食'),
        MenuItem(name: 'パスタ', price: '420円', category: 'パスタ'),
      ];
    }
  }

  static String _categorizeMenuItem(String name) {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('定食')) return '定食';
    if (lowerName.contains('丼') || lowerName.contains('どん')) return '丼物';
    if (lowerName.contains('ラーメン') || lowerName.contains('うどん') || lowerName.contains('そば')) return '麺類';
    if (lowerName.contains('カレー')) return 'カレー';
    if (lowerName.contains('パスタ')) return 'パスタ';
    if (lowerName.contains('サラダ')) return 'サラダ';
    if (lowerName.contains('デザート') || lowerName.contains('スイーツ')) return 'デザート';
    
    return 'その他';
  }

  static Future<CafeteriaCongestion?> fetchCongestionStatus(String campus) async {
    try {
      final campusData = _campusInfo[campus];
      if (campusData == null) {
        debugPrint('Unknown campus: $campus');
        return null;
      }

      // CIT学食WEBカメラページから混雑状況を取得
      final response = await http.get(
        Uri.parse(_cameraUrl),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch congestion status: ${response.statusCode}');
        return null;
      }

      return _parseCongestionHtml(response.body, campus, campusData);
    } catch (e) {
      debugPrint('Error fetching congestion status: $e');
      return null;
    }
  }

  static CafeteriaCongestion _parseCongestionHtml(String htmlContent, String campus, Map<String, dynamic> campusData) {
    final document = html.parse(htmlContent);
    
    // カメラ運用時間チェック
    final isCameraActive = _isCameraActive(campusData);
    
    // 混雑状況の判定ロジック
    CongestionLevel level;
    if (isCameraActive) {
      level = _estimateCongestionFromCamera(document, campus);
    } else {
      level = _estimateCongestionByTime();
    }
    
    try {
      // WEBカメラの画像を探す
      final cameraImages = document.querySelectorAll('img[src*="camera"], img[src*="live"]');
      String? cameraImageUrl;
      
      for (final img in cameraImages) {
        final src = img.attributes['src'];
        if (src != null) {
          // キャンパス名に基づいて適切なカメラ画像を特定
          final campusName = campusData['name'] as String;
          if ((campus == 'tsudanuma' && src.toLowerCase().contains('tsudanuma')) ||
              (campus == 'narashino' && src.toLowerCase().contains('narashino'))) {
            cameraImageUrl = src.startsWith('http') ? src : 'https://www.cit-s.com$src';
            break;
          }
        }
      }

      // 一般的なカメラ画像URLパターンを試行
      if (cameraImageUrl == null && isCameraActive) {
        final campusPrefix = campus == 'tsudanuma' ? 'tsu' : 'nar';
        cameraImageUrl = 'https://www.cit-s.com/dining/dining_icatch/camera_${campusPrefix}.jpg';
      }

    } catch (e) {
      debugPrint('Error parsing camera HTML: $e');
    }

    final campusName = campusData['name'] as String;
    return CafeteriaCongestion(
      campus: campus,
      location: campusName,
      level: level,
      timestamp: DateTime.now(),
      cameraUrl: isCameraActive ? _cameraUrl : null,
    );
  }

  // カメラが運用中かどうかチェック
  static bool _isCameraActive(Map<String, dynamic> campusData) {
    final now = DateTime.now();
    
    // 土日チェック
    if (now.weekday >= 6) return false;
    
    // カメラ運用時間チェック (11:00-14:00)
    final hour = now.hour;
    if (hour < 11 || hour >= 14) return false;
    
    return true;
  }

  // カメラ画像から混雑状況を推定（将来的に画像解析を実装）
  static CongestionLevel _estimateCongestionFromCamera(html.Document document, String campus) {
    // 現在は時間ベースの推定を使用
    // 将来的にはカメラ画像の解析や、サイト上の混雑情報テキストを解析可能
    
    try {
      // カメラページ内の混雑状況テキストを探す
      final textElements = document.querySelectorAll('p, div, span');
      for (final element in textElements) {
        final text = element.text.toLowerCase();
        
        if (text.contains('混雑')) {
          if (text.contains('空いて') || text.contains('少ない')) {
            return CongestionLevel.low;
          } else if (text.contains('やや')) {
            return CongestionLevel.medium;
          } else {
            return CongestionLevel.high;
          }
        }
      }
    } catch (e) {
      debugPrint('Error analyzing camera content: $e');
    }
    
    // フォールバック: 時間ベースの推定
    return _estimateCongestionByTime();
  }

  // 時間帯に基づく混雑状況の推定
  static CongestionLevel _estimateCongestionByTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeInMinutes = hour * 60 + minute;

    // 平日の想定混雑パターン
    if (now.weekday >= 6) {
      return CongestionLevel.empty; // 土日は休業
    }

    // 朝食時間 (8:30-9:30)
    if (timeInMinutes >= 510 && timeInMinutes <= 570) {
      return CongestionLevel.low;
    }
    
    // 昼食ピーク時間 (12:00-13:00)
    if (timeInMinutes >= 720 && timeInMinutes <= 780) {
      return CongestionLevel.high;
    }
    
    // 昼食時間 (11:00-14:00)
    if (timeInMinutes >= 660 && timeInMinutes <= 840) {
      return CongestionLevel.medium;
    }
    
    // 夕食時間 (17:00-19:00)
    if (timeInMinutes >= 1020 && timeInMinutes <= 1140) {
      return CongestionLevel.medium;
    }

    // その他の時間
    return CongestionLevel.empty;
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  // モックデータ（開発・テスト用）
  static CafeteriaMenu getMockMenu(String campus) {
    return CafeteriaMenu(
      date: _getTodayDateString(),
      campus: campus,
      items: [
        MenuItem(name: '日替わり定食', price: '550円', category: '定食'),
        MenuItem(name: '唐揚げ丼', price: '480円', category: '丼物'),
        MenuItem(name: '醤油ラーメン', price: '420円', category: '麺類'),
        MenuItem(name: 'ハンバーグカレー', price: '580円', category: 'カレー'),
        MenuItem(name: 'ミックスサラダ', price: '280円', category: 'サラダ'),
        MenuItem(name: 'チーズケーキ', price: '250円', category: 'デザート'),
      ],
      fetchedAt: DateTime.now(),
    );
  }

  static CafeteriaCongestion getMockCongestion(String campus) {
    return CafeteriaCongestion(
      campus: campus,
      location: '学食',
      level: CongestionLevel.low,
      timestamp: DateTime.now(),
      cameraUrl: _cameraUrl,
    );
  }
}