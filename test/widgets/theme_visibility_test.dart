import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/theme/app_colors.dart';
import 'package:cit_app/core/providers/global_notification_provider.dart';
import 'package:cit_app/models/notification/notification_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/screens/auth/widgets/auth_components.dart';
import 'package:cit_app/screens/notification/global_notification_list_screen.dart';
import 'package:cit_app/widgets/global_notification_widget.dart';
import 'package:cit_app/widgets/notification/notification_card.dart';
import 'package:cit_app/widgets/profile/user_avatar.dart';
import 'package:cit_app/widgets/schedule/schedule_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());

  AppNotification notification(NotificationType type, bool read) =>
      AppNotification(
        id: 'test',
        userId: 'local',
        type: type,
        isRead: read,
        title: '講義に関する大切なお知らせです',
        message: '明日の教室が変更されました。時間割の詳細から最新の教室を確認してください。',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

  Future<void> mount(
    WidgetTester tester,
    Brightness mode,
    Widget child, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: themes[mode],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in Brightness.values) {
    for (final listScreen in [false, true]) {
      testWidgets(
        '$mode global notices and important badges at 320px / 200% (list=$listScreen)',
        (tester) async {
          final notices = [
            for (final type in [
              NotificationType.maintenance,
              NotificationType.appUpdate,
              NotificationType.important,
            ])
              GlobalNotification(
                id: type.name,
                type: type,
                title: '${type.displayName}についてのお知らせ',
                message: '最新の情報をこちらからご確認ください。',
                createdAt: DateTime.now(),
              ),
          ];
          await mount(
            tester,
            mode,
            ProviderScope(
              overrides: [
                globalNotificationsProvider.overrideWith(
                  (ref) => Stream.value(notices),
                ),
                unviewedNotificationCountProvider.overrideWithValue(3),
              ],
              child:
                  listScreen
                      ? const SizedBox(
                        height: 700,
                        child: GlobalNotificationListScreen(),
                      )
                      : const GlobalNotificationWidget(),
            ),
            width: 320,
            scale: 2,
          );
          expect(tester.takeException(), isNull);
          expect(find.text(notices.first.title), findsOneWidget);
          // Important badges retain meaning through text as well as color.
          final badge = tester.widget<Text>(
            find.text(NotificationType.maintenance.displayName).first,
          );
          final background =
              (tester
                          .element(
                            find
                                .text(NotificationType.maintenance.displayName)
                                .first,
                          )
                          .findAncestorWidgetOfExactType<Container>()!
                          .decoration!
                      as BoxDecoration)
                  .color!;
          expect(
            AppColors.contrastRatio(badge.style!.color!, background),
            greaterThanOrEqualTo(4.5),
          );
        },
      );
    }
    testWidgets('$mode theme, accents and snackbar colors have text contrast', (
      tester,
    ) async {
      await mount(
        tester,
        mode,
        Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            void readable(Color fg, Color bg, [String? label]) => expect(
              AppColors.contrastRatio(fg, bg),
              greaterThanOrEqualTo(4.499),
              reason: label,
            );
            for (final background in [
              scheme.surface,
              scheme.surfaceContainerLow,
              scheme.surfaceContainerHighest,
            ]) {
              readable(scheme.onSurface, background);
              readable(scheme.onSurfaceVariant, background);
            }
            readable(scheme.onPrimary, scheme.primary);
            readable(scheme.onPrimaryContainer, scheme.primaryContainer);
            readable(scheme.onErrorContainer, scheme.errorContainer);
            readable(scheme.onInverseSurface, scheme.inverseSurface);
            for (final seed in [
              ...Colors.primaries,
              ...Colors.accents,
              Colors.white,
              Colors.black,
              Colors.grey,
            ]) {
              final accent = AppColors.accent(context, seed);
              for (final background in [
                scheme.surface,
                scheme.surfaceContainerHighest,
                AppColors.tintedSurface(context, seed),
              ]) {
                readable(accent, background, '$mode $seed on $background');
              }
              readable(AppColors.onColor(seed), seed);
              expect(
                AppColors.contrastRatio(
                  scheme.onInverseSurface,
                  AppColors.snackBarSurface(context, seed),
                ),
                greaterThanOrEqualTo(6.999),
              );
            }
            return const SizedBox();
          },
        ),
      );
    });

    for (final read in [false, true]) {
      testWidgets(
        '$mode notifications: every type, long content, 320px and 200%',
        (tester) async {
          for (final type in NotificationType.values) {
            var opened = 0, marked = 0, deleted = 0;
            await mount(
              tester,
              mode,
              NotificationCard(
                notification: notification(type, read),
                onTap: () => opened++,
                onMarkRead: () => marked++,
                onDelete: () => deleted++,
              ),
              width: 320,
              scale: 2,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$mode $type read=$read',
            );
            final card = tester.widget<Card>(find.byType(Card));
            for (final text in tester.widgetList<Text>(
              find.descendant(
                of: find.byType(NotificationCard),
                matching: find.byType(Text),
              ),
            )) {
              expect(
                AppColors.contrastRatio(text.style!.color!, card.color!),
                greaterThanOrEqualTo(4.5),
                reason: text.data,
              );
            }
            await tester.tap(find.text(notification(type, read).title));
            expect(opened, 1);
            await tester.ensureVisible(find.byTooltip('通知を削除'));
            await tester.tap(find.byTooltip('通知を削除'));
            expect(deleted, 1);
            if (!read) {
              await tester.tap(find.byTooltip('既読にする'));
              expect(marked, 1);
            } else {
              expect(find.byTooltip('既読にする'), findsNothing);
            }
          }
        },
      );
    }

    testWidgets('$mode auth cards, input and primary action at 200%', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var pressed = 0;
      await mount(
        tester,
        mode,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const AllowedEmailInfoCard(
                headline: '大学のメールアドレスをご利用ください',
                domains: ['s.chibakoudai.jp'],
              ),
              AuthTextField(
                controller: controller,
                hintText: 'メールアドレス',
                prefixIcon: Icons.mail,
              ),
              const AuthInlineError(message: 'メールアドレスを確認してください'),
              PrimaryAuthButton(
                label: 'アカウントを作成する',
                isLoading: false,
                onPressed: () => pressed++,
              ),
              AuthNavigationCard(
                label: 'ログイン画面へ戻る',
                onTap: () {},
                tinted: true,
                emphasizeText: true,
              ),
            ],
          ),
        ),
        width: 320,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('アカウントを作成する'));
      await tester.tap(find.text('アカウントを作成する'));
      expect(pressed, 1);
      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(PrimaryAuthButton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradient = (decorated.decoration as BoxDecoration).gradient!;
      for (final color in gradient.colors) {
        expect(
          AppColors.contrastRatio(Colors.white, color),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('$mode snackbar action and custom appbar foreground', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themes[mode],
          home: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('画像表示'),
            ),
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.snackBarSurface(
                            context,
                            Colors.green,
                          ),
                          content: const Text('保存しました'),
                          action: SnackBarAction(label: '確認', onPressed: () {}),
                        ),
                      );
                    },
                    child: const Text('通知を表示'),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('通知を表示'));
      await tester.pumpAndSettle();
      final title = tester.renderObject<RenderParagraph>(find.text('画像表示'));
      expect(title.text.style!.color, Colors.white);
      final content = tester.renderObject<RenderParagraph>(find.text('保存しました'));
      final action = tester.renderObject<RenderParagraph>(find.text('確認'));
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        AppColors.contrastRatio(
          content.text.style!.color!,
          bar.backgroundColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        AppColors.contrastRatio(
          action.text.style!.color!,
          bar.backgroundColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('$mode avatars and schedule labels use readable colors', (
      tester,
    ) async {
      const lesson = ScheduleClass(
        id: '1',
        subjectName: '情報設計',
        classroom: '701',
        instructor: '教員',
        color: '#212121',
      );
      const schedule = Schedule(
        id: '1',
        userId: 'local',
        semester: '2026',
        timetable: {
          'monday': {1: lesson},
        },
        timeSlots: [TimeSlot(period: 1, startTime: '09:00', endTime: '10:00')],
      );
      await mount(
        tester,
        mode,
        Column(
          children: [
            const UserAvatar(
              displayName: '工大',
              initialTextStyle: TextStyle(color: Colors.white),
            ),
            ScheduleGridWidget(
              schedule: schedule,
              onClassTap: (_, _, _) {},
              onEmptySlotTap: (_, _) {},
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      final initial = tester.widget<Text>(find.text('工'));
      expect(
        AppColors.contrastRatio(initial.style!.color!, avatar.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
      final classroom = tester.widget<Text>(find.text('701'));
      expect(
        AppColors.contrastRatio(
          classroom.style!.color!,
          themes[mode]!.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('$mode schedule preserves selected colors with readable text', (
      tester,
    ) async {
      // Cover the edit screen's saturated, dark and pastel palette on real cells.
      const palette = [
        '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A',
        '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800', '#FF5722', '#F44336',
        '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#795548', '#607D8B',
        '#9E9E9E', '#212121', '#90CAF9', '#80CBC4', '#A5D6A7', '#FFE082',
        '#FFAB91', '#F48FB1', '#CE93D8', '#B0BEC5',
      ];
      final timetable = <String, Map<int, ScheduleClass?>>{};
      for (var i = 0; i < palette.length; i++) {
        final day = Weekday.values[i % 6].name;
        final period = (i ~/ 6) * 2 + 1;
        (timetable[day] ??= {})[period] = ScheduleClass(
          id: '$i',
          subjectName: '講義${i + 1}',
          classroom: '${701 + i}',
          instructor: '教員',
          color: palette[i],
          duration: i.isEven ? 1 : 2,
        );
      }
      final boundary = GlobalKey();
      await mount(
        tester,
        mode,
        RepaintBoundary(
          key: boundary,
          child: ColoredBox(
            color: themes[mode]!.colorScheme.surface,
            child: ScheduleGridWidget(
              schedule: Schedule(
                id: 'palette',
                userId: 'local',
                semester: '2026',
                timetable: timetable,
              ),
              enableScroll: false,
              onClassTap: (_, _, _) {},
              onEmptySlotTap: (_, _) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (var i = 0; i < palette.length; i++) {
        final subject = find.text('講義${i + 1}');
        final cell = tester.widget<Container>(
          find.ancestor(
            of: subject,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).color != null,
            ),
          ).first,
        );
        final background = (cell.decoration! as BoxDecoration).color!;
        expect(
          background,
          Color(int.parse(palette[i].replaceFirst('#', 'ff'), radix: 16)),
        );
        final renderedSubject = tester.renderObject<RenderParagraph>(subject);
        expect(
          AppColors.contrastRatio(renderedSubject.text.style!.color!, background),
          greaterThanOrEqualTo(4.5),
          reason: '$mode ${palette[i]} subject',
        );
        final room = tester.renderObject<RenderParagraph>(
          find.text('${701 + i}'),
        );
        expect(
          AppColors.contrastRatio(
            room.text.style!.color!,
            themes[mode]!.colorScheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '$mode ${palette[i]} classroom',
        );
      }
      if (themePreviewDirectory.isNotEmpty) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary).toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(themePreviewDirectory).create(recursive: true);
          await File('$themePreviewDirectory/schedule-${mode.name}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });

    if (themePreviewDirectory.isNotEmpty) {
      testWidgets('$mode representative production components preview', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final boundary = GlobalKey();
        final controller = TextEditingController(
          text: 'student@s.chibakoudai.jp',
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: themes[mode],
              home: Scaffold(
                appBar: AppBar(
                  title: Text(
                    mode == Brightness.dark ? 'ダークモードの表示確認' : 'ライトモードの表示確認',
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const AllowedEmailInfoCard(
                        headline: '大学のメールアドレスでログインできます',
                        domains: ['s.chibakoudai.jp'],
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: controller,
                        hintText: 'メールアドレス',
                        prefixIcon: Icons.mail_outline,
                      ),
                      const SizedBox(height: 12),
                      PrimaryAuthButton(
                        label: 'ログイン',
                        isLoading: false,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 20),
                      for (final read in [false, true])
                        NotificationCard(
                          notification: notification(
                            NotificationType.maintenance,
                            read,
                          ),
                          onTap: () {},
                          onMarkRead: () {},
                          onDelete: () {},
                        ),
                      const SizedBox(height: 12),
                      const AuthInlineError(message: '入力内容を確認してください。'),
                      const SizedBox(height: 12),
                      Builder(
                        builder:
                            (context) => Container(
                              padding: const EdgeInsets.all(16),
                              color: AppColors.snackBarSurface(
                                context,
                                Colors.green,
                              ),
                              child: Text(
                                '保存しました',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onInverseSurface,
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(themePreviewDirectory).create(recursive: true);
          await File(
            '$themePreviewDirectory/${mode.name}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
