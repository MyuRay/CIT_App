import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/reports/report_model.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 通報を送信
  static Future<void> submitReport({
    required ReportType type,
    required String targetId,
    required ReportReason reason,
    String? detail,
  }) async {
    try {
      // 認証チェック
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません。ログインしてください。');
      }

      // 詳細が500文字以内かチェック
      if (detail != null && detail.length > 500) {
        throw Exception('詳細は500文字以内で入力してください。');
      }

      // 通報データを作成
      final Report report = Report(
        id: '', // Firestoreで自動生成
        type: type,
        targetId: targetId,
        reporterId: currentUser.uid,
        reporterName: currentUser.displayName ?? '匿名ユーザー',
        reason: reason,
        detail: detail,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );

      // Firestoreに保存
      await _firestore.collection('reports').add(report.toJson());
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('通報の送信に失敗しました: $e');
    }
  }

  /// ステータス別に通報を取得（管理者向け）
  static Stream<List<Report>> watchReportsByStatus(ReportStatus? status) {
    try {
      Query query = _firestore.collection('reports');

      // ステータスでフィルタリング（nullの場合は全件取得）
      if (status != null) {
        query = query.where('status', isEqualTo: status.toJson());
      }

      // 作成日時の降順でソート
      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Report.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('通報の取得に失敗しました: $e');
    }
  }

  /// 通報のステータスを更新（管理者向け）
  static Future<void> updateStatus({
    required String reportId,
    required ReportStatus status,
    String? resolutionNote,
  }) async {
    try {
      // 認証チェック
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません。');
      }

      final Map<String, dynamic> updateData = {
        'status': status.toJson(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // 対応メモがある場合は追加
      if (resolutionNote != null) {
        updateData['resolutionNote'] = resolutionNote;
      }

      await _firestore.collection('reports').doc(reportId).update(updateData);
    } catch (e) {
      throw Exception('通報ステータスの更新に失敗しました: $e');
    }
  }

  /// 特定の通報を取得
  static Future<Report?> getReportById(String reportId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('reports')
          .doc(reportId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Report.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      throw Exception('通報の取得に失敗しました: $e');
    }
  }

  /// 通報統計を取得（管理者向け）
  static Future<Map<String, int>> getReportStatistics() async {
    try {
      final QuerySnapshot allReports = await _firestore
          .collection('reports')
          .get();

      final QuerySnapshot pendingReports = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();

      final QuerySnapshot reviewingReports = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'reviewing')
          .get();

      final QuerySnapshot resolvedReports = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'resolved')
          .get();

      return {
        'total': allReports.docs.length,
        'pending': pendingReports.docs.length,
        'reviewing': reviewingReports.docs.length,
        'resolved': resolvedReports.docs.length,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'reviewing': 0,
        'resolved': 0,
      };
    }
  }

  /// 同じ対象に対する通報が既に存在するかチェック
  static Future<bool> hasAlreadyReported({
    required String targetId,
    required ReportType type,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .where('targetId', isEqualTo: targetId)
          .where('type', isEqualTo: type.toJson())
          .where('reporterId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('通報チェック時のエラー: $e');
      return false;
    }
  }
}
