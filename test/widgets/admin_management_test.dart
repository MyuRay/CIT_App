import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/admin_dashboard_provider.dart';
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/contact_provider.dart';
import 'package:cit_app/core/providers/global_notification_provider.dart';
import 'package:cit_app/core/providers/report_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/providers/user_management_provider.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/models/notification/notification_model.dart';
import 'package:cit_app/models/reports/report_model.dart';
import 'package:cit_app/models/user_management/user_management_model.dart';
import 'package:cit_app/screens/admin/admin_dashboard_screen.dart';
import 'package:cit_app/screens/admin/contact_management_screen.dart';
import 'package:cit_app/screens/admin/notification_management_screen.dart';
import 'package:cit_app/screens/admin/user_management_screen.dart';
import 'package:cit_app/screens/reports/report_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/theme_test_fonts.dart';

class _RetryReportUpdates extends ReportStatusUpdateNotifier {
  int calls = 0;
  @override
  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status,
    String? resolutionNote,
  }) async {
    calls++;
    state =
        calls == 1
            ? AsyncValue.error(StateError('offline'), StackTrace.current)
            : const AsyncValue.data(null);
  }
}

class _CaptureNotification extends NotificationCreation {
  _CaptureNotification(super.ref);
  final done = Completer<String>();
  GlobalNotification? captured;
  int calls = 0;
  @override
  Future<String> createNotification(GlobalNotification notification) {
    calls++;
    captured = notification;
    return done.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  late SharedPreferences preferences;
  final boundary = GlobalKey();
  final admin = AdminPermissions.fromJson({
    'userId': 'operator',
    'isAdmin': true,
  });
  final contacts = [
    for (final status in ['pending', 'in_progress', 'resolved'])
      ContactForm(
        id: status,
        name: 'テスト利用者',
        email: 'example@example.com',
        category: 'bug',
        categoryName: '不具合報告',
        subject: status == 'resolved' ? '解決したお問い合わせ' : '学年暦の表示について',
        message: '予定の表示方法について確認したいことがあります。',
        createdAt: DateTime(2026, 9, 16, 9),
        status: status,
        userId: 'user',
      ),
  ];
  final users = [
    AppUser(
      uid: 'operator',
      email: 'operator@example.com',
      displayName: '運営チーム',
      createdAt: DateTime(2026, 9, 1),
    ),
    AppUser(
      uid: 'member',
      email: 'member@example.com',
      displayName: 'テスト利用者',
      isActive: false,
      createdAt: DateTime(2026, 9, 2),
    ),
  ];
  final report = Report(
    id: 'report',
    type: ReportType.post,
    targetId: 'post',
    reporterId: 'reporter',
    reporterName: 'テスト利用者',
    reason: ReportReason.spam,
    createdAt: DateTime(2026, 9, 16),
    targetContent: '同じ内容が繰り返し投稿されています。',
    targetAuthorName: '投稿者',
  );

  setUpAll(() async => themes = await loadTestThemes());
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  List<Override> defaults() => [
    currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
    sharedPreferencesProvider.overrideWithValue(preferences),
    for (final queue in AdminQueue.values)
      adminQueueCountProvider(
        queue,
      ).overrideWith((ref) async => queue.index + 2),
    allContactsProvider(
      defaultContactFilter,
    ).overrideWith((ref) => Stream.value(contacts)),
    allUsersProvider(
      defaultUserListFilter,
    ).overrideWith((ref) => Stream.value(users)),
    adminUserIdsProvider.overrideWith((ref) => Stream.value({'operator'})),
    allReportsProvider.overrideWith((ref) => Stream.value([report])),
    allGlobalNotificationsProvider.overrideWith((ref) => Stream.value([])),
  ];

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    Brightness mode = Brightness.light,
    double width = 390,
    double scale = 1,
    List<Override>? overrides,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides ?? defaults(),
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themes[mode],
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 48),
                  ),
                  child: child!,
                ),
            home: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final snapshot =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final data = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      await Directory(themePreviewDirectory).create(recursive: true);
      await File(
        '$themePreviewDirectory/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      snapshot.dispose();
    });
  }

  final screens = <String, Widget>{
    'dashboard': const AdminDashboardScreen(),
    'contacts': const ContactManagementScreen(),
    'users': const UserManagementScreen(),
    'reports': const ReportManagementScreen(),
  };
  for (final mode in Brightness.values) {
    testWidgets('$mode management previews', (tester) async {
      for (final entry in screens.entries) {
        await mount(tester, entry.value, mode: mode);
        await capture(tester, '${entry.key}-${mode.name}');
        expect(tester.takeException(), isNull);
      }
    });
    testWidgets(
      '$mode 320px text 200% and system navigation remain scrollable',
      (tester) async {
        for (final entry in screens.entries) {
          await mount(tester, entry.value, mode: mode, width: 320, scale: 2);
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -550),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('dashboard search and clear retain access to tools', (
    tester,
  ) async {
    await mount(tester, const AdminDashboardScreen());
    await tester.enterText(find.byType(TextField), '時刻表');
    await tester.pumpAndSettle();
    expect(find.text('学バス管理'), findsOneWidget);
    expect(find.text('広告管理'), findsNothing);
    await tester.ensureVisible(find.byTooltip('検索をクリア'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('検索をクリア'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('広告管理'), findsWidgets);
  });

  testWidgets(
    'pending inquiry card opens the pending filter and returns normally',
    (tester) async {
      await mount(tester, const AdminDashboardScreen());
      await tester.tap(find.text('問い合わせ'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactManagementScreen), findsOneWidget);
      expect(find.text('1件を表示'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('管理センター'), findsOneWidget);
    },
  );

  testWidgets(
    'contact search and status clearing combine without resubscribing',
    (tester) async {
      var subscriptions = 0;
      await mount(
        tester,
        const ContactManagementScreen(initialStatus: 'pending'),
        overrides: [
          currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
          allContactsProvider(defaultContactFilter).overrideWith((ref) {
            subscriptions++;
            return Stream.value(contacts);
          }),
        ],
      );
      expect(find.text('1件を表示'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '解決した');
      await tester.pumpAndSettle();
      expect(find.text('0件を表示'), findsOneWidget);
      await tester.tap(find.text('すべて 3'));
      await tester.pumpAndSettle();
      expect(find.text('1件を表示'), findsOneWidget);
      expect(subscriptions, 1);
    },
  );

  testWidgets('user search and role filters do not restart the user stream', (
    tester,
  ) async {
    var subscriptions = 0;
    await mount(
      tester,
      const UserManagementScreen(),
      overrides: [
        currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
        allUsersProvider(defaultUserListFilter).overrideWith((ref) {
          subscriptions++;
          return Stream.value(users);
        }),
        adminUserIdsProvider.overrideWith((ref) => Stream.value({'operator'})),
      ],
    );
    await tester.enterText(find.byType(TextField), 'operator@');
    await tester.pumpAndSettle();
    expect(find.text('1件を表示'), findsOneWidget);
    await tester.tap(find.byTooltip('検索をクリア'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '管理者'));
    await tester.pumpAndSettle();
    expect(find.text('1件を表示'), findsOneWidget);
    expect(subscriptions, 1);
  });

  testWidgets(
    'non-admin management pages never subscribe to protected collections',
    (tester) async {
      for (final screen in screens.values) {
        await mount(
          tester,
          screen,
          overrides: [
            currentUserAdminProvider.overrideWith((ref) => Stream.value(null)),
            adminDashboardFirestoreProvider.overrideWith(
              (ref) => throw StateError('Unauthorized read'),
            ),
            allContactsProvider(
              defaultContactFilter,
            ).overrideWith((ref) => throw StateError('Unauthorized read')),
            allUsersProvider(
              defaultUserListFilter,
            ).overrideWith((ref) => throw StateError('Unauthorized read')),
            allReportsProvider.overrideWith(
              (ref) => throw StateError('Unauthorized read'),
            ),
          ],
        );
        expect(find.text('管理者権限が必要です'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('failed report update stays open and retry succeeds', (
    tester,
  ) async {
    final updates = _RetryReportUpdates();
    await mount(
      tester,
      const ReportManagementScreen(),
      overrides: [
        ...defaults(),
        reportStatusUpdateProvider.overrideWith((ref) => updates),
      ],
    );
    await tester.ensureVisible(find.text('内容を確認・対応を記録 →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('内容を確認・対応を記録 →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();
    expect(find.text('通報詳細'), findsOneWidget);
    expect(find.textContaining('更新に失敗しました'), findsOneWidget);
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();
    expect(find.text('通報詳細'), findsNothing);
    expect(updates.calls, 2);
  });

  testWidgets('notification draft survives the history tab and type changes', (
    tester,
  ) async {
    await mount(tester, const NotificationManagementScreen());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'タイトル'),
      '編集中のお知らせ',
    );
    await tester.tap(find.text('通知履歴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('通知作成'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'タイトル'))
          .controller!
          .text,
      '編集中のお知らせ',
    );
    final chips = find.byType(FilterChip);
    await tester.tap(chips.last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'タイトル'))
          .controller!
          .text,
      '編集中のお知らせ',
    );
  });

  testWidgets(
    'notification saves the displayed title and selected type only once',
    (tester) async {
      late _CaptureNotification action;
      await mount(
        tester,
        const NotificationManagementScreen(),
        overrides: [
          ...defaults(),
          notificationCreationProvider.overrideWith(
            (ref) => action = _CaptureNotification(ref),
          ),
        ],
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'タイトル'),
        '運営からのお知らせ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'メッセージ'),
        '学生のみなさんへの案内です。',
      );
      await tester.ensureVisible(find.text('通知を送信'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('通知を送信'));
      await tester.pump();
      expect(action.captured!.type, NotificationType.general);
      expect(action.captured!.title, '運営からのお知らせ');
      expect(action.captured!.message, '学生のみなさんへの案内です。');
      await tester.tap(find.text('送信中...'));
      await tester.pump();
      expect(action.calls, 1);
      action.done.complete('test-notification');
      await tester.pumpAndSettle();
      expect(find.text('通知を送信しました'), findsOneWidget);
    },
  );
}
