import 'package:cit_app/core/providers/cwitter_provider.dart';
import 'package:cit_app/models/community/cwitter_social_platform.dart';
import 'package:cit_app/screens/community/widgets/cwitter_social_links_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const id = '123456789012345678';
  const profile = 'https://discord.com/users/$id';
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> launches;
  late List<String> copied;
  late Future<bool> Function(MethodCall) launch;

  setUp(() {
    launches = [];
    copied = [];
    launch = (_) async => true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'launch');
      launches.add(call);
      return launch(call);
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Finder icon(CwitterSocialPlatform platform) => find.byWidgetPredicate(
    (widget) => widget is FaIcon && widget.icon == platform.brandIcon.data,
  );

  Future<void> mount(
    WidgetTester tester, {
    String value = id,
    bool isSelf = false,
    double scale = 1,
    Map<String, String>? links,
  }) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final socialLinks = links ?? {'discord': value};
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cwitterUserSocialLinksProvider(
            'owner',
          ).overrideWith((ref) => Stream.value(socialLinks)),
        ],
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: Scaffold(
            body: CwitterSocialLinksSection(
              authorId: 'owner',
              isSelf: isSelf,
              initialLinks: socialLinks,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tapping a numeric ID launches its Discord profile without copying',
    (tester) async {
      await mount(tester);
      await tester.tap(icon(CwitterSocialPlatform.discord));
      await tester.pumpAndSettle();
      expect(launches, hasLength(1));
      expect(launches.single.arguments['url'], profile);
      expect(launches.single.arguments['universalLinksOnly'], isTrue);
      expect(launches.single.arguments['useWebView'], isFalse);
      expect(copied, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  for (final throws in [false, true]) {
    testWidgets('absent Discord app falls back to browser (throws: $throws)', (
      tester,
    ) async {
      launch = (call) async {
        if (call.arguments['universalLinksOnly'] == true) {
          if (throws) throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
          return false;
        }
        return true;
      };
      await mount(tester, value: profile);
      await tester.tap(icon(CwitterSocialPlatform.discord));
      await tester.pumpAndSettle();
      expect(launches, hasLength(2));
      expect(launches.map((call) => call.arguments['url']), [profile, profile]);
      expect(launches.last.arguments['universalLinksOnly'], isFalse);
      expect(launches.last.arguments['useWebView'], isFalse);
      expect(copied, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('launch failures are visible and a later tap can retry', (
    tester,
  ) async {
    launch = (_) async => false;
    await mount(tester);
    await tester.tap(icon(CwitterSocialPlatform.discord));
    await tester.pumpAndSettle();
    expect(find.text('Discordを開けませんでした。もう一度お試しください'), findsOneWidget);
    expect(copied, isEmpty);
    launch = (_) async => true;
    await tester.tap(icon(CwitterSocialPlatform.discord));
    await tester.pumpAndSettle();
    expect(launches, hasLength(3));
  });

  testWidgets('own legacy username opens editing with ID instructions', (
    tester,
  ) async {
    await mount(tester, value: 'student', isSelf: true, scale: 2);
    await tester.tap(icon(CwitterSocialPlatform.discord));
    await tester.pumpAndSettle();
    expect(find.text('Discord を設定'), findsOneWidget);
    expect(find.textContaining('ユーザーIDをコピー'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('数字のユーザーIDまたはDiscordのプロフィールURLを入力してください'), findsOneWidget);
    expect(launches, isEmpty);
    expect(copied, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'other legacy username explains missing profile and copies only by choice',
    (tester) async {
      await mount(tester, value: 'student');
      await tester.tap(icon(CwitterSocialPlatform.discord));
      await tester.pumpAndSettle();
      expect(find.text('Discordのプロフィールを開けません'), findsOneWidget);
      expect(launches, isEmpty);
      expect(copied, isEmpty);
      await tester.tap(find.text('登録内容をコピー'));
      await tester.pumpAndSettle();
      expect(copied, ['student']);
    },
  );

  testWidgets('Discord lookalike URL is never launched directly', (
    tester,
  ) async {
    await mount(tester, value: 'https://discord.com.evil.example/users/$id');
    await tester.tap(icon(CwitterSocialPlatform.discord));
    await tester.pumpAndSettle();
    expect(launches, isEmpty);
    expect(copied, isEmpty);
    expect(find.text('Discordのプロフィールを開けません'), findsOneWidget);
  });

  testWidgets('other social links still ask before opening external sites', (
    tester,
  ) async {
    await mount(tester, links: {'instagram': 'student'});
    await tester.tap(icon(CwitterSocialPlatform.instagram));
    await tester.pumpAndSettle();
    expect(find.text('外部サイトを開く'), findsOneWidget);
    expect(launches, isEmpty);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(launches, isEmpty);
  });
}
