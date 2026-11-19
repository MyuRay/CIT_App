import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/core/providers/cwitter_provider.dart';
import 'package:cit_app/core/providers/cwitter_quote_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/providers/user_block_provider.dart';
import 'package:cit_app/core/providers/user_provider.dart';
import 'package:cit_app/models/community/cwitter_post.dart';
import 'package:cit_app/models/user/user_model.dart';
import 'package:cit_app/screens/community/widgets/cwitter_quote_composer.dart';
import 'package:cit_app/screens/community/widgets/cwitter_quoted_post.dart';
import 'package:cit_app/screens/community/widgets/cwitter_recweet_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final source = CwitterPost(
    id: 'original',
    authorId: 'source',
    cwitterId: 'source',
    displayName: '引用元の学生',
    body: '明日の講義は教室が変更されています。時間割を確認してください。',
    createdAt: DateTime(2026, 9, 30),
  );
  final user = AppUser(
    uid: 'self',
    email: 'self@chibatech.ac.jp',
    displayName: '自分の名前',
    cwitterId: 'self',
    createdAt: DateTime(2026, 9, 30),
  );
  late StreamController<CwitterPost?> sources;
  late StreamController<Set<String>> hidden;
  late SubmitCwitterQuote submit;
  late List<(String, String, String)> writes;
  late bool? result;
  final boundary = GlobalKey();

  setUp(() {
    sources = StreamController.broadcast();
    hidden = StreamController.broadcast();
    writes = [];
    result = null;
    submit = (author, id, body) async => writes.add((author.uid, id, body));
  });
  tearDown(() async {
    await sources.close();
    await hidden.close();
  });

  Future<void> mount(
    WidgetTester tester, {
    bool preview = false,
    double scale = 1,
    Brightness mode = Brightness.light,
    Set<String> hiddenIds = const {},
    bool nested = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'cwitter_guidelines_dismissed': true,
    });
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final shownSource =
        nested
            ? CwitterPost(
              id: source.id,
              authorId: source.authorId,
              cwitterId: source.cwitterId,
              displayName: source.displayName,
              body: source.body,
              createdAt: source.createdAt,
              quotedPostId: 'original',
            )
            : source;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('self'),
          currentAppUserStreamProvider.overrideWith(
            (ref) => Stream.value(user),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          cwitterQuotedPostProvider(source.id).overrideWith((ref) async* {
            yield shownSource;
            yield* sources.stream;
          }),
          hiddenUserIdsProvider.overrideWith((ref) async* {
            yield hiddenIds;
            yield* hidden.stream;
          }),
          authorDisplayNameProvider((
            authorId: source.authorId,
            fallback: source.displayName,
          )).overrideWith((ref) => Stream.value('最新の表示名')),
          submitCwitterQuoteProvider.overrideWithValue(
            (author, id, body) => submit(author, id, body),
          ),
        ],
        child: MaterialApp(
          theme: themes[mode],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) =>
                      preview
                          ? RepaintBoundary(
                            key: boundary,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CwitterQuotedPost(
                                postId: source.id,
                                onOpen: (_) => result = true,
                              ),
                            ),
                          )
                          : TextButton(
                            onPressed: () async {
                              result = await CwitterQuoteComposer.show(
                                context,
                                source,
                              );
                            },
                            child: const Text('引用を開く'),
                          ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!preview) {
      await tester.tap(find.text('引用を開く'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('saves a trimmed comment and source id exactly once', (
    tester,
  ) async {
    final pending = Completer<void>();
    submit = (author, id, body) {
      writes.add((author.uid, id, body));
      return pending.future;
    };
    await mount(tester);
    await tester.enterText(find.byType(TextFormField), '  私も確認しました  ');
    await tester.tap(find.text('引用recweetする'));
    await tester.tap(find.text('引用recweetする'));
    await tester.pump();
    expect(writes, [('self', 'original', '私も確認しました')]);
    expect(find.text('投稿中…'), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty input, discard cancellation and discard never publish', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('引用recweetする'));
    await tester.pumpAndSettle();
    expect(find.text('コメントを入力してください'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '下書き');
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集を続ける'));
    await tester.pumpAndSettle();
    expect(find.text('下書き'), findsOneWidget);
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄する'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(writes, isEmpty);
  });

  testWidgets('failed persistence keeps the comment for a successful retry', (
    tester,
  ) async {
    submit = (_, __, ___) async => throw StateError('offline');
    await mount(tester);
    await tester.enterText(find.byType(TextFormField), '残るコメント');
    await tester.tap(find.text('引用recweetする'));
    await tester.pumpAndSettle();
    expect(find.text('残るコメント'), findsOneWidget);
    expect(find.text('引用recweetできませんでした。もう一度お試しください。'), findsOneWidget);
    expect(result, isNull);
    submit = (author, id, body) async => writes.add((author.uid, id, body));
    await tester.tap(find.text('引用recweetする'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(writes.length, 1);
  });

  testWidgets('deleted source disables submission without dropping the draft', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextFormField), '下書き');
    sources.add(null);
    await tester.pumpAndSettle();
    expect(find.text('元のCweetは削除されたか、表示できません'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('下書き'), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets('blocking or failing to load visibility never leaks the source', (
    tester,
  ) async {
    await mount(tester, preview: true);
    expect(find.text(source.body), findsOneWidget);
    hidden.add({'source'});
    await tester.pumpAndSettle();
    expect(find.text(source.body), findsNothing);
    expect(find.text('最新の表示名'), findsNothing);
    hidden.addError(StateError('visibility unavailable'));
    await tester.pumpAndSettle();
    expect(find.text(source.body), findsNothing);
    expect(find.text('引用元を読み込めませんでした'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a nested or cyclic quote stays one level deep and can open the source',
    (tester) async {
      await mount(tester, preview: true, nested: true);
      expect(find.byType(CwitterQuotedPost), findsOneWidget);
      expect(find.text('引用recweet'), findsOneWidget);
      await tester.tap(find.text('元のCweetを見る'));
      expect(result, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in Brightness.values) {
    testWidgets('quote preview fits 320px and 200 percent in $mode', (
      tester,
    ) async {
      await mount(tester, preview: true, scale: 2, mode: mode);
      expect(find.text('最新の表示名'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (themePreviewDirectory.isNotEmpty) {
        await tester.runAsync(() async {
          final box =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await box.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$themePreviewDirectory/quote-${mode.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }

  testWidgets('recweet menu offers quoting even after a regular recweet', (
    tester,
  ) async {
    CwitterRecweetAction? action;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () async =>
                          action = await showCwitterRecweetActions(
                            context,
                            isRecweeted: true,
                          ),
                  child: const Text('メニュー'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('recweetを取り消す'), findsOneWidget);
    await tester.tap(find.text('引用recweet'));
    await tester.pumpAndSettle();
    expect(action, CwitterRecweetAction.quote);
  });
}
