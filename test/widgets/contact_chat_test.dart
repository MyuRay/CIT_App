import 'package:cit_app/widgets/contact/contact_chat_image.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:cit_app/services/contact/contact_chat_image_service.dart';
import 'dart:async';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/screens/admin/contact_management_screen.dart';
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/contact_chat_provider.dart';
import 'package:cit_app/models/contact/contact_chat.dart';
import 'package:cit_app/screens/contact/contact_chat_screen.dart';
import 'package:cit_app/services/contact/contact_chat_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FailOnceService extends ContactChatService {
  _FailOnceService()
    : super(firestore: FakeFirebaseFirestore(), auth: MockFirebaseAuth());
  final ids = <String>[];
  final attachments = <List<String>>[];
  final acknowledgements = <int>[];
  @override
  Future<void> sendMessage({
    required String userId,
    required String text,
    required String messageId,
    bool asAdmin = false,
    List<String> imagePaths = const [],
  }) async {
    ids.add(messageId);
    attachments.add(imagePaths);
    if (ids.length == 1) throw StateError('offline');
  }

  @override
  Future<void> markRead(
    String uid, {
    required bool asAdmin,
    required int seen,
  }) async {
    acknowledgements.add(seen);
  }
}

class _DelayedService extends _FailOnceService {
  final completed = Completer<void>();
  @override
  Future<void> sendMessage({
    required String userId,
    required String text,
    required String messageId,
    bool asAdmin = false,
    List<String> imagePaths = const [],
  }) {
    ids.add(messageId);
    return completed.future;
  }
}

const room = ContactChat(
  userId: 'student',
  displayName: '学生',
  email: '',
  lastMessage: '返信です',
  status: 'in_progress',
  userMessageCount: 1,
  adminMessageCount: 2,
  userReadCount: 0,
  adminReadCount: 1,
);
ContactChatMessage reply(int index) => ContactChatMessage(
  id: 'r$index',
  text: '返信$index',
  senderId: 'operator',
  senderRole: 'admin',
  sequence: index + 1,
  senderSequence: index,
  createdAt: DateTime(2026, 10, 29, 10, index),
);

final _fixtureJpeg = Uint8List.fromList(
  image.encodeJpg(image.Image(width: 16, height: 16)),
);

class _Picker extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [
    XFile.fromData(_fixtureJpeg, name: 'test.jpg', mimeType: 'image/jpeg'),
  ];
}

class _Images extends ContactChatImageService {
  _Images() : super(auth: MockFirebaseAuth());
  @override
  Future<Uint8List> prepare(XFile file) async => _fixtureJpeg;
  @override
  Future<List<String>> upload({
    required String userId,
    required String messageId,
    required List<Uint8List> images,
  }) async => [
    for (var i = 0; i < images.length; i++)
      'contact_chat_images/$userId/student/$messageId/$i.jpg',
  ];
  @override
  Future<Uint8List> read(String userId, String path) async => _fixtureJpeg;
}

void main() {
  final user = MockUser(
    uid: 'student',
    email: 'student@s.chibakoudai.jp',
    isEmailVerified: true,
  );
  Future<void> mount(
    WidgetTester tester, {
    ContactChatService? service,
    ContactChat? chat,
    Stream<List<ContactChatMessage>>? messages,
    double width = 390,
    double scale = 1,
    Brightness brightness = Brightness.light,
    bool asAdmin = false,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          currentUserAdminProvider.overrideWith(
            (ref) => Stream.value(
              asAdmin
                  ? AdminPermissions.fromJson({
                    'userId': 'student',
                    'isAdmin': true,
                  })
                  : null,
            ),
          ),
          contactChatProvider(
            'student',
          ).overrideWith((ref) => Stream.value(chat)),
          contactChatMessagesProvider((
            uid: 'student',
            limit: 50,
          )).overrideWith((ref) => messages ?? Stream.value([])),
          contactChatImageServiceProvider.overrideWithValue(_Images()),
          contactChatImagePickerProvider.overrideWithValue(_Picker()),
          contactChatServiceProvider.overrideWithValue(
            service ?? _FailOnceService(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: ContactChatScreen(
            asAdmin: asAdmin,
            userId: asAdmin ? 'student' : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a friendly empty chat has no subject or category and does not send empty text',
    (tester) async {
      await mount(tester);
      expect(
        find.text(contactChatWelcomeMessage, findRichText: true),
        findsOneWidget,
      );
      expect(find.text('件名'), findsNothing);
      final send = tester.widget<IconButton>(
        find.byKey(const Key('contact-chat-send')),
      );
      expect(send.onPressed, isNull);
      await tester.tap(find.text('ちょっと質問したい'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('contact-chat-input')))
            .controller!
            .text,
        contains('ちょっと質問したい'),
      );
    },
  );

  testWidgets('sending appears immediately and reconciles the server ID once', (
    tester,
  ) async {
    final service = _DelayedService();
    final updates = StreamController<List<ContactChatMessage>>();
    addTearDown(updates.close);
    final messages = Stream<List<ContactChatMessage>>.multi((controller) {
      controller.add([]);
      final sub = updates.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
    await mount(tester, service: service, messages: messages);
    await tester.enterText(
      find.byKey(const Key('contact-chat-input')),
      'すぐに表示',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('contact-chat-send')));
    await tester.pump();
    expect(find.text('すぐに表示'), findsOneWidget);
    expect(find.text('送信中'), findsOneWidget);
    expect(find.textContaining('既読'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('contact-chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    service.completed.complete();
    updates.add([
      ContactChatMessage(
        id: service.ids.single,
        text: 'すぐに表示',
        senderId: 'student',
        senderRole: 'user',
        sequence: 1,
        senderSequence: 1,
        createdAt: DateTime(2026, 10, 30, 12),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('すぐに表示'), findsOneWidget);
    expect(find.text('送信中'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('operator icon and canned response appear without sending', (
    tester,
  ) async {
    final service = _FailOnceService();
    await mount(tester, service: service, chat: room, asAdmin: true);
    expect(find.byType(CircleAvatar), findsWidgets);
    expect(find.byTooltip('ユーザー情報'), findsOneWidget);
    await tester.tap(find.text('お礼の定型文を入力'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('contact-chat-input')))
          .controller!
          .text,
      'いつもCIT Appをご利用いただき誠にありがとうございます。\n今後ともCITをよろしくお願いいたします。',
    );
    expect(service.ids, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed sends preserve the draft and retry uses the same message ID',
    (tester) async {
      final service = _FailOnceService();
      await mount(tester, service: service);
      await tester.enterText(
        find.byKey(const Key('contact-chat-input')),
        'こんにちは',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('contact-chat-send')));
      await tester.pumpAndSettle();
      expect(find.textContaining('送信できませんでした'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('contact-chat-input')))
            .controller!
            .text,
        'こんにちは',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('contact-chat-send')));
      await tester.pumpAndSettle();
      expect(service.ids.length, 2);
      expect(service.ids.first, service.ids.last);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('contact-chat-input')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'new replies arrive live and only loaded replies are acknowledged',
    (tester) async {
      final stream = StreamController<List<ContactChatMessage>>();
      final service = _FailOnceService();
      addTearDown(stream.close);
      // Keep the initial snapshot available to settle the loading indicator.
      final initial = Stream<List<ContactChatMessage>>.multi((controller) {
        controller.add([reply(1)]);
        final sub = stream.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = sub.cancel;
      });
      await mount(tester, service: service, chat: room, messages: initial);
      expect(service.acknowledgements, [1]);
      stream.add([reply(2), reply(1)]);
      await tester.pumpAndSettle();
      expect(find.text('返信2'), findsOneWidget);
      expect(service.acknowledgements, [1, 2]);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('320px large text and keyboard remain usable in $brightness', (
      tester,
    ) async {
      await mount(
        tester,
        width: 320,
        scale: 2,
        brightness: brightness,
        chat: room,
        service: _FailOnceService(),
        messages: Stream.value([reply(1)]),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('contact-chat-input')), findsOneWidget);
    });
  }

  testWidgets(
    'non-admins cannot instantiate another users admin conversation',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            currentUserAdminProvider.overrideWith((ref) => Stream.value(null)),
            contactChatServiceProvider.overrideWith(
              (ref) => throw StateError('Unauthorized query'),
            ),
          ],
          child: const MaterialApp(
            home: ContactChatScreen(userId: 'other', asAdmin: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('管理者権限が必要です'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('switching accounts removes old messages and draft immediately', (
    tester,
  ) async {
    final session = StreamController<MockUser?>();
    addTearDown(session.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => session.stream),
          contactChatProvider(
            'student',
          ).overrideWith((ref) => Stream.value(room)),
          contactChatProvider(
            'other',
          ).overrideWith((ref) => Stream.value(null)),
          contactChatMessagesProvider((
            uid: 'student',
            limit: 50,
          )).overrideWith((ref) => Stream.value([reply(1)])),
          contactChatMessagesProvider((
            uid: 'other',
            limit: 50,
          )).overrideWith((ref) => Stream.value([])),
          contactChatImageServiceProvider.overrideWithValue(_Images()),
          contactChatImagePickerProvider.overrideWithValue(_Picker()),
          contactChatServiceProvider.overrideWithValue(_FailOnceService()),
        ],
        child: const MaterialApp(home: ContactChatScreen()),
      ),
    );
    session.add(user);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('contact-chat-input')), '下書き');
    session.add(MockUser(uid: 'other', isEmailVerified: true));
    await tester.pumpAndSettle();
    expect(find.text('返信1'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('contact-chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    session.add(null);
    await tester.pumpAndSettle();
    expect(find.text('メール認証済みのアカウントでログインしてください'), findsOneWidget);
  });

  testWidgets(
    'operator inbox filters unread conversations independently of status',
    (tester) async {
      const unread = ContactChat(
        userId: 'student',
        displayName: '相談者',
        email: '',
        lastMessage: '時間割について',
        status: 'pending',
        userMessageCount: 2,
        adminMessageCount: 0,
        userReadCount: 0,
        adminReadCount: 0,
      );
      const handled = ContactChat(
        userId: 'other',
        displayName: '回答済みの利用者',
        email: '',
        lastMessage: 'ありがとうございました',
        status: 'resolved',
        userMessageCount: 1,
        adminMessageCount: 1,
        userReadCount: 1,
        adminReadCount: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserAdminProvider.overrideWith(
              (ref) => Stream.value(
                AdminPermissions.fromJson({
                  'userId': 'operator',
                  'isAdmin': true,
                }),
              ),
            ),
            adminContactChatsProvider.overrideWith(
              (ref) => Stream.value([unread, handled]),
            ),
          ],
          child: const MaterialApp(home: ContactManagementScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('相談者'), findsOneWidget);
      expect(find.text('回答済みの利用者'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, '未読のみ'));
      await tester.pumpAndSettle();
      expect(find.text('回答済みの利用者'), findsNothing);
      expect(find.text('相談者'), findsOneWidget);
    },
  );
  testWidgets(
    'loading older messages keeps the current transcript and scroll position',
    (tester) async {
      final older = StreamController<List<ContactChatMessage>>();
      addTearDown(older.close);
      final firstPage = [for (var i = 100; i > 50; i--) reply(i)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
            contactChatProvider(
              'student',
            ).overrideWith((ref) => Stream.value(room)),
            contactChatMessagesProvider((
              uid: 'student',
              limit: 50,
            )).overrideWith((ref) => Stream.value(firstPage)),
            contactChatMessagesProvider((
              uid: 'student',
              limit: 100,
            )).overrideWith((ref) => older.stream),
            contactChatImageServiceProvider.overrideWithValue(_Images()),
            contactChatImagePickerProvider.overrideWithValue(_Picker()),
            contactChatServiceProvider.overrideWithValue(_FailOnceService()),
          ],
          child: const MaterialApp(home: ContactChatScreen()),
        ),
      );
      await tester.pumpAndSettle();
      ScrollableState scroller() => tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      for (var i = 0; i < 3; i++) {
        scroller().position.jumpTo(scroller().position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('さらに前のメッセージ'));
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget);
      expect(scroller().position.pixels, greaterThan(80));
      older.add([for (var i = 100; i > 25; i--) reply(i)]);
      await tester.pumpAndSettle();
      expect(scroller().position.pixels, greaterThan(80));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'image-only sends preserve attachments on failure and clear them after retry',
    (tester) async {
      final service = _FailOnceService();
      await mount(tester, service: service);
      await tester.tap(find.byKey(const Key('contact-chat-attach')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('添付画像を削除'), findsOneWidget);
      await tester.tap(find.byKey(const Key('contact-chat-send')));
      await tester.pumpAndSettle();
      expect(find.textContaining('送信できませんでした'), findsOneWidget);
      expect(find.byTooltip('添付画像を削除'), findsOneWidget);
      expect(service.attachments.single, hasLength(1));
      await tester.tap(find.byKey(const Key('contact-chat-send')));
      await tester.pumpAndSettle();
      expect(service.ids.first, service.ids.last);
      expect(service.attachments.first, service.attachments.last);
      expect(find.byTooltip('添付画像を削除'), findsNothing);
    },
  );

  testWidgets(
    'the initial operator message appears exactly once before an existing conversation',
    (tester) async {
      await mount(tester, chat: room, messages: Stream.value([reply(1)]));
      expect(find.text('お問い合わせ'), findsOneWidget);
      expect(
        find.text(contactChatWelcomeMessage, findRichText: true),
        findsOneWidget,
      );
      expect(find.text('運営とトーク'), findsNothing);
    },
  );

  testWidgets('received attachments can be enlarged and closed', (
    tester,
  ) async {
    await mount(
      tester,
      chat: room,
      messages: Stream.value([
        ContactChatMessage(
          id: 'photo',
          text: '',
          senderId: 'operator',
          senderRole: 'admin',
          sequence: 2,
          senderSequence: 1,
          imagePaths: const [
            'contact_chat_images/student/operator/photo/0.jpg',
          ],
          createdAt: DateTime(2026, 10, 29),
        ),
      ]),
    );
    final attachment = find.byType(ContactChatImage);
    expect(attachment, findsOneWidget);
    await tester.tap(
      find.descendant(of: attachment, matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
