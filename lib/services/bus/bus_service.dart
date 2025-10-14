import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bus/bus_model.dart';

/// 学バス情報のFirebaseサービス
class BusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _busInfoCollection = 'bus_information';
  static const String _busRoutesSubcollection = 'bus_routes';
  static const String _operationPeriodsSubcollection = 'operation_periods';

  /// 学バス情報を取得
  Future<BusInformation?> getBusInformation() async {
    try {
      print('🚌 学バス情報取得開始');
      
      final doc = await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .get();

      if (!doc.exists) {
        print('🚌 学バス情報が存在しません (ドキュメントなし)');
        return null;
      }
      
      print('🚌 メインドキュメント取得成功');

      final data = doc.data()!;
      print('🚌 メインドキュメントデータ: $data');
      
      // 運行期間を取得（whereなしでテスト）
      print('🚌 運行期間取得中（全件）...');
      final periodsSnapshot = await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_operationPeriodsSubcollection)
          .get()
          .timeout(const Duration(seconds: 10));

      print('🚌 運行期間取得完了 - ${periodsSnapshot.docs.length}件');
      final operationPeriods = periodsSnapshot.docs
          .map((doc) => BusOperationPeriod.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      
      print('🚌 期間処理結果: 全期間=${operationPeriods.length}, アクティブ期間=${operationPeriods.where((p) => p.isActive).length}');

      // バス路線を取得（whereなしでテスト）
      print('🚌 バス路線取得中（全件）...');
      final routesSnapshot = await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_busRoutesSubcollection)
          .get()
          .timeout(const Duration(seconds: 10));

      print('🚌 バス路線取得完了 - ${routesSnapshot.docs.length}件');
      final routes = routesSnapshot.docs
          .map((doc) => BusRoute.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)); // Dart側でソート
      
      print('🚌 路線処理結果: 全路線=${routes.length}, アクティブ路線=${routes.where((r) => r.isActive).length}');

      print('🚌 BusInformation作成中...');
      final busInfo = BusInformation(
        id: doc.id,
        title: data['title'] ?? '学バス時刻表',
        description: data['description'] ?? '',
        routes: routes,
        operationPeriods: operationPeriods,
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedBy: data['updatedBy'] ?? '',
      );
      print('🚌 BusInformation作成完了: ${busInfo.title}');
      print('✅ getBusInformation 完了');
      return busInfo;
    } catch (e) {
      print('❌ getBusInformation エラー: $e');
      print('❌ スタックトレース: ${StackTrace.current}');
      return null;
    }
  }

  /// 学バス情報をリアルタイム監視
  Stream<BusInformation?> watchBusInformation() {
    print('🚌 watchBusInformation: ストリーム開始');
    
    return _firestore
        .collection(_busInfoCollection)
        .doc('main')
        .snapshots()
        .asyncMap((doc) async {
          print('🚌 watchBusInformation: スナップショット受信 - exists: ${doc.exists}');
          if (!doc.exists) return null;
          
          final data = doc.data()!;
          
          // 運行期間を取得
          print('🚌 watchBusInformation: 運行期間取得中...');
          final periodsSnapshot = await _firestore
              .collection(_busInfoCollection)
              .doc('main')
              .collection(_operationPeriodsSubcollection)
              .get();

          print('🚌 watchBusInformation: 運行期間取得完了 - ${periodsSnapshot.docs.length}件');
          final operationPeriods = periodsSnapshot.docs
              .map((doc) => BusOperationPeriod.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          
          print('🚌 ストリーム: 全運行期間=${operationPeriods.length}, アクティブ期間=${operationPeriods.where((p) => p.isActive).length}');

          // バス路線を取得
          print('🚌 watchBusInformation: バス路線取得中...');
          final routesSnapshot = await _firestore
              .collection(_busInfoCollection)
              .doc('main')
              .collection(_busRoutesSubcollection)
              .get();

          print('🚌 watchBusInformation: バス路線取得完了 - ${routesSnapshot.docs.length}件');
          final routes = routesSnapshot.docs
              .map((doc) => BusRoute.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          
          print('🚌 ストリーム: 全路線=${routes.length}, アクティブ路線=${routes.where((r) => r.isActive).length}');

          final busInfo = BusInformation(
            id: doc.id,
            title: data['title'] ?? '学バス時刻表',
            description: data['description'] ?? '',
            routes: routes,
            operationPeriods: operationPeriods,
            lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedBy: data['updatedBy'] ?? '',
          );
          
          print('🚌 watchBusInformation: BusInformation作成完了 - ${busInfo.title} - routes: ${busInfo.routes.length} - periods: ${busInfo.operationPeriods.length}');
          return busInfo;
        }).handleError((error) {
          print('❌ watchBusInformation: ストリームエラー - $error');
          throw error;
        });
  }

  /// 学バス情報を保存・更新
  Future<bool> saveBusInformation(BusInformation busInfo) async {
    try {
      print('🚌 saveBusInformation開始');
      
      final batch = _firestore.batch();
      final mainDocRef = _firestore.collection(_busInfoCollection).doc('main');

      // メイン情報を保存
      final mainData = {
        'title': busInfo.title,
        'description': busInfo.description,
        'lastUpdated': Timestamp.fromDate(busInfo.lastUpdated),
        'updatedBy': busInfo.updatedBy,
      };
      
      print('🚌 メインドキュメント保存: $mainData');
      batch.set(mainDocRef, mainData);
      
      await batch.commit();
      print('✅ メインドキュメント保存完了');

      // 運行期間を保存
      print('🚌 運行期間保存開始: ${busInfo.operationPeriods.length}件');
      await _saveOperationPeriods(busInfo.operationPeriods);
      print('✅ 運行期間保存完了');

      // バス路線を保存
      print('🚌 バス路線保存開始: ${busInfo.routes.length}件');
      await _saveBusRoutes(busInfo.routes);
      print('✅ バス路線保存完了');

      print('✅ 学バス情報保存完了');
      return true;
    } catch (e) {
      print('❌ 学バス情報保存エラー: $e');
      print('❌ エラースタックトレース: ${e.toString()}');
      return false;
    }
  }

  /// 運行期間を保存
  Future<void> _saveOperationPeriods(List<BusOperationPeriod> periods) async {
    final batch = _firestore.batch();
    final collectionRef = _firestore
        .collection(_busInfoCollection)
        .doc('main')
        .collection(_operationPeriodsSubcollection);

    for (final period in periods) {
      final docRef = period.id.isNotEmpty 
          ? collectionRef.doc(period.id)
          : collectionRef.doc();
      
      batch.set(docRef, period.toJson());
    }

    await batch.commit();
  }

  /// バス路線を保存
  Future<void> _saveBusRoutes(List<BusRoute> routes) async {
    final batch = _firestore.batch();
    final collectionRef = _firestore
        .collection(_busInfoCollection)
        .doc('main')
        .collection(_busRoutesSubcollection);

    for (final route in routes) {
      final docRef = route.id.isNotEmpty 
          ? collectionRef.doc(route.id)
          : collectionRef.doc();
      
      batch.set(docRef, route.toJson());
    }

    await batch.commit();
  }

  /// 運行期間を追加
  Future<String?> addOperationPeriod(BusOperationPeriod period) async {
    try {
      final docRef = await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_operationPeriodsSubcollection)
          .add(period.toJson());

      print('✅ 運行期間追加完了: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ 運行期間追加エラー: $e');
      return null;
    }
  }

  /// 運行期間を更新
  Future<bool> updateOperationPeriod(BusOperationPeriod period) async {
    try {
      await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_operationPeriodsSubcollection)
          .doc(period.id)
          .update(period.toJson());

      print('✅ 運行期間更新完了: ${period.id}');
      return true;
    } catch (e) {
      print('❌ 運行期間更新エラー: $e');
      return false;
    }
  }

  /// 運行期間を削除
  Future<bool> deleteOperationPeriod(String periodId) async {
    try {
      await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_operationPeriodsSubcollection)
          .doc(periodId)
          .delete();

      print('✅ 運行期間削除完了: $periodId');
      return true;
    } catch (e) {
      print('❌ 運行期間削除エラー: $e');
      return false;
    }
  }

  /// バス路線を追加
  Future<String?> addBusRoute(BusRoute route) async {
    try {
      // 路線名の検証
      if (route.name.isEmpty) {
        print('❌ バス路線追加エラー: 路線名が空です');
        return null;
      }

      // JSONデータの検証
      final jsonData = route.toJson();
      if (jsonData.isEmpty) {
        print('❌ バス路線追加エラー: JSONデータが空です');
        return null;
      }

      print('🔄 バス路線追加開始: ${route.name}');
      
      final docRef = await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_busRoutesSubcollection)
          .add(jsonData);

      print('✅ バス路線追加完了: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ バス路線追加エラー: $e');
      print('❌ エラー詳細: route.name=${route.name}');
      return null;
    }
  }

  /// バス路線を更新
  Future<bool> updateBusRoute(BusRoute route) async {
    try {
      // IDの検証
      if (route.id.isEmpty) {
        print('❌ バス路線更新エラー: IDが空です');
        return false;
      }

      // 路線名の検証
      if (route.name.isEmpty) {
        print('❌ バス路線更新エラー: 路線名が空です');
        return false;
      }

      // JSONデータの検証
      final jsonData = route.toJson();
      if (jsonData.isEmpty) {
        print('❌ バス路線更新エラー: JSONデータが空です');
        return false;
      }

      print('🔄 バス路線更新開始: ${route.id} (${route.name})');
      
      await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_busRoutesSubcollection)
          .doc(route.id)
          .update(jsonData);

      print('✅ バス路線更新完了: ${route.id}');
      return true;
    } catch (e) {
      print('❌ バス路線更新エラー: $e');
      print('❌ エラー詳細: route.id=${route.id}, route.name=${route.name}');
      return false;
    }
  }

  /// バス路線を削除
  Future<bool> deleteBusRoute(String routeId) async {
    try {
      await _firestore
          .collection(_busInfoCollection)
          .doc('main')
          .collection(_busRoutesSubcollection)
          .doc(routeId)
          .delete();

      print('✅ バス路線削除完了: $routeId');
      return true;
    } catch (e) {
      print('❌ バス路線削除エラー: $e');
      return false;
    }
  }

  /// 初期データを作成（強制再作成オプション付き）
  Future<bool> createInitialBusData({bool forceRecreate = false}) async {
    try {
      print('🚌 初期データ作成開始');
      
      // 既存データをチェック
      final existing = await getBusInformation();
      if (existing != null && !forceRecreate) {
        print('ℹ️ 学バス情報は既に存在します: ${existing.title}');
        return true;
      }
      
      if (forceRecreate && existing != null) {
        print('🚌 既存データを削除して再作成します');
        await _deleteAllBusData();
      }
      
      print('🚌 既存データなし、新規作成を開始');

      // サンプルの運行期間（現在の日付を含むように設定）
      final now = DateTime.now();
      
      final currentPeriod = BusOperationPeriod(
        id: '',
        name: '通常運行',
        startDate: DateTime(now.year, now.month - 1, 1), // 1ヶ月前から
        endDate: DateTime(now.year + 1, now.month, now.day), // 1年後まで
        isActive: true,
      );

      final futurePeriod = BusOperationPeriod(
        id: '',
        name: '秋学期',
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2026, 1, 31),
        isActive: true,
      );

      // サンプルのバス時刻
      final morningTimes = [
        BusTimeEntry(id: '', hour: 8, minute: 30, isActive: true),
        BusTimeEntry(id: '', hour: 9, minute: 0, isActive: true),
        BusTimeEntry(id: '', hour: 9, minute: 30, isActive: true),
      ];

      final eveningTimes = [
        BusTimeEntry(id: '', hour: 16, minute: 30, isActive: true),
        BusTimeEntry(id: '', hour: 17, minute: 0, isActive: true),
        BusTimeEntry(id: '', hour: 17, minute: 30, note: '最終便', isActive: true),
      ];

      // サンプルの路線
      final tsudanumaToNarashino = BusRoute(
        id: '',
        name: '津田沼 → 新習志野',
        description: '津田沼キャンパスから新習志野キャンパスへ',
        timeEntries: morningTimes,
        sortOrder: 1,
        isActive: true,
      );

      final narashinoToTsudanuma = BusRoute(
        id: '',
        name: '新習志野 → 津田沼',
        description: '新習志野キャンパスから津田沼キャンパスへ',
        timeEntries: eveningTimes,
        sortOrder: 2,
        isActive: true,
      );

      // 初期バス情報
      final initialBusInfo = BusInformation(
        id: 'main',
        title: '千葉工業大学 学バス時刻表',
        description: '津田沼キャンパスと新習志野キャンパス間を運行する学バスの時刻表です。',
        routes: [tsudanumaToNarashino, narashinoToTsudanuma],
        operationPeriods: [currentPeriod, futurePeriod],
        lastUpdated: DateTime.now(),
        updatedBy: 'システム初期化',
      );

      // 保存
      print('🚌 学バス情報を保存中...');
      final result = await saveBusInformation(initialBusInfo);
      if (result) {
        print('✅ 学バス情報の初期データを作成しました');
        
        // 作成後、実際にデータが読み取れるか確認
        final verification = await getBusInformation();
        if (verification != null) {
          print('✅ 作成確認: ${verification.title} - 路線数: ${verification.routes.length} - 運行期間数: ${verification.operationPeriods.length}');
        } else {
          print('❌ 作成後の確認でデータが読み取れません');
        }
      } else {
        print('❌ 学バス情報の保存に失敗');
      }
      
      return result;
    } catch (e) {
      print('❌ 初期データ作成エラー: $e');
      return false;
    }
  }
  
  /// 全学バスデータを削除（初期化用）
  Future<void> _deleteAllBusData() async {
    try {
      print('🚌 全学バスデータ削除開始');
      
      final batch = _firestore.batch();
      final mainDocRef = _firestore.collection(_busInfoCollection).doc('main');
      
      // 運行期間を削除
      final periodsSnapshot = await mainDocRef.collection(_operationPeriodsSubcollection).get();
      for (final doc in periodsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // バス路線を削除
      final routesSnapshot = await mainDocRef.collection(_busRoutesSubcollection).get();
      for (final doc in routesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // メインドキュメントを削除
      batch.delete(mainDocRef);
      
      await batch.commit();
      print('✅ 全学バスデータ削除完了');
    } catch (e) {
      print('❌ 学バスデータ削除エラー: $e');
    }
  }
}