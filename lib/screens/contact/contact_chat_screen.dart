import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../widgets/contact/contact_chat_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/admin_dashboard_provider.dart';
import '../../core/providers/contact_chat_provider.dart';
import '../../models/contact/contact_chat.dart';
import '../../widgets/admin/admin_access_gate.dart';
import '../../widgets/admin/admin_user_info_dialog.dart';
import 'user_contact_list_screen.dart';

class ContactChatScreen extends ConsumerWidget {
  const ContactChatScreen({super.key, this.userId, this.asAdmin = false});
  final String? userId;
  final bool asAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    return session.when(
      skipLoadingOnReload: false,
      data: (user) {
        if (user == null || !user.emailVerified) {
          return Scaffold(
            appBar: AppBar(title: const Text('お問い合わせ')),
            body: const Center(child: Text('メール認証済みのアカウントでログインしてください')),
          );
        }
        final uid = asAdmin ? userId : user.uid;
        if (uid == null || uid.isEmpty) {
          return const Scaffold(body: Center(child: Text('お問い合わせが見つかりません')));
        }
        Widget body(BuildContext context) => _ChatBody(
          key: ValueKey('${user.uid}:$uid:$asAdmin'),
          uid: uid,
          asAdmin: asAdmin,
        );
        return asAdmin
            ? AdminAccessGate(
              title: 'お問い合わせ',
              allow: (p) => p.canAccessContactManagement,
              builder: body,
            )
            : body(context);
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (_, __) =>
              const Scaffold(body: Center(child: Text('ログイン状態を確認できませんでした'))),
    );
  }
}

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({super.key, required this.uid, required this.asAdmin});
  final String uid;
  final bool asAdmin;
  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false, _atBottom = true, _reading = false;
  int _limit = 50;
  final _images = <Uint8List>[];
  bool _picking = false;
  int _acknowledged = 0;
  List<ContactChatMessage> _lastPage = [];
  String? _retryId, _retryText, _sendError, _readError;
  ContactChatMessage? _pendingMessage;
  List<Uint8List> _pendingImages = [];
  bool _pendingFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(() {
      final bottom = _scroll.offset < 80;
      if (bottom != _atBottom) setState(() => _atBottom = bottom);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_sending || _picking) return;
    if (_images.length >= contactChatMaxImages) {
      setState(() => _sendError = '画像は4枚まで添付できます');
      return;
    }
    setState(() {
      _picking = true;
      _sendError = null;
    });
    try {
      final files = await ref
          .read(contactChatImagePickerProvider)
          .pickMultiImage(
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 85,
            requestFullMetadata: false,
          );
      if (files.length + _images.length > contactChatMaxImages)
        throw ArgumentError('画像は4枚まで添付できます');
      final prepared = <Uint8List>[];
      for (final file in files) {
        if (!mounted) return;
        prepared.add(
          await ref.read(contactChatImageServiceProvider).prepare(file),
        );
      }
      if (mounted) setState(() => _images.addAll(prepared));
    } catch (e) {
      if (mounted)
        setState(
          () =>
              _sendError =
                  e is ArgumentError
                      ? e.message.toString()
                      : '画像を読み込めませんでした。別の画像を選んでください。',
        );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _send() async {
    if (_sending || _picking || (_text.text.trim().isEmpty && _images.isEmpty))
      return;
    final service = ref.read(contactChatServiceProvider);
    final body = _text.text.trim();
    final attachments = List<Uint8List>.of(_images);
    final signature =
        body + _images.map((bytes) => md5.convert(bytes).toString()).join();
    final id =
        _retryText == signature && _retryId != null
            ? _retryId!
            : service.newMessageId(widget.uid);
    setState(() {
      _sending = true;
      _sendError = null;
      _retryText = signature;
      _retryId = id;
      _pendingFailed = false;
      _pendingImages = attachments;
      _pendingMessage = ContactChatMessage(
        id: id,
        text: body,
        senderId: ref.read(authStateProvider).valueOrNull!.uid,
        senderRole: widget.asAdmin ? 'admin' : 'user',
        sequence: 0,
        senderSequence: 0,
      );
      _text.clear();
      _images.clear();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    try {
      final imagePaths =
          attachments.isEmpty
              ? <String>[]
              : await ref
                  .read(contactChatImageServiceProvider)
                  .upload(
                    userId: widget.uid,
                    messageId: id,
                    images: attachments,
                  );
      if (!mounted) return;
      await service.sendMessage(
        userId: widget.uid,
        text: body,
        messageId: id,
        asAdmin: widget.asAdmin,
        imagePaths: imagePaths,
      );
      if (!mounted) return;
      if (widget.asAdmin)
        ref.invalidate(adminQueueCountProvider(AdminQueue.contacts));
      _text.clear();
      setState(() {
        _retryId = null;
        _images.clear();
        _retryText = null;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted)
        setState(() {
          _pendingFailed = true;
          _text.text = body;
          _images
            ..clear()
            ..addAll(attachments);
          _sendError = '送信できませんでした。通信状態を確認して、もう一度送信してください。';
        });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _acknowledge(ContactChat? chat, List<ContactChatMessage> messages) {
    if (chat == null ||
        _reading ||
        !_atBottom ||
        _readError != null ||
        ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed))
      return;
    final opposite = widget.asAdmin ? 'user' : 'admin';
    final seen = messages
        .where((m) => m.senderRole == opposite)
        .fold<int>(0, (value, m) => math.max(value, m.senderSequence));
    final read = widget.asAdmin ? chat.adminReadCount : chat.userReadCount;
    if (seen <= math.max(read, _acknowledged)) return;
    _reading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
        await ref
            .read(contactChatServiceProvider)
            .markRead(widget.uid, asAdmin: widget.asAdmin, seen: seen);
        _acknowledged = math.max(_acknowledged, seen);
      } catch (_) {
        if (mounted) setState(() => _readError = '既読にできませんでした');
      } finally {
        _reading = false;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(contactChatProvider(widget.uid));
    final page = (uid: widget.uid, limit: _limit);
    final messages = ref.watch(contactChatMessagesProvider(page));
    if (messages.hasValue) {
      _lastPage = messages.requireValue;
      if (_pendingMessage != null &&
          _lastPage.any((message) => message.id == _pendingMessage!.id)) {
        _pendingMessage = null;
        _pendingImages = [];
      }
    }
    final displayedMessages =
        !messages.hasValue && _lastPage.isNotEmpty
            ? AsyncValue<List<ContactChatMessage>>.data(_lastPage)
            : messages;
    final room = chat.asData?.value;
    final colors = Theme.of(context).colorScheme;
    if (messages.hasValue && !chat.hasError)
      _acknowledge(room, messages.requireValue);
    final enabled =
        !messages.hasError &&
        !chat.hasError &&
        chat.hasValue &&
        (!widget.asAdmin || room != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asAdmin ? (room?.userLabel ?? 'お問い合わせ') : 'お問い合わせ'),
        actions: [
          if (widget.asAdmin)
            IconButton(
              tooltip: 'ユーザー情報',
              icon: const Icon(Icons.person_search_outlined),
              onPressed: () => showAdminUserInfo(context, widget.uid),
            ),
          if (!widget.asAdmin)
            IconButton(
              tooltip: '過去のお問い合わせ',
              icon: const Icon(Icons.history),
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserContactListScreen(),
                    ),
                  ),
            ),
          if (widget.asAdmin && room != null)
            PopupMenuButton<String>(
              tooltip: '対応状況',
              initialValue: room.status,
              onSelected: (status) async {
                try {
                  await ref
                      .read(contactChatServiceProvider)
                      .setStatus(widget.uid, status);
                  ref.invalidate(adminQueueCountProvider(AdminQueue.contacts));
                } catch (_) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('対応状況を変更できませんでした')),
                    );
                }
              },
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(value: 'pending', child: Text('未対応')),
                    PopupMenuItem(value: 'in_progress', child: Text('対応中')),
                    PopupMenuItem(value: 'resolved', child: Text('解決済み')),
                  ],
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                if (chat.hasError)
                  _error(
                    'お問い合わせを読み込めませんでした',
                    () => ref.invalidate(contactChatProvider(widget.uid)),
                  ),
                if (messages.hasError && _lastPage.isNotEmpty)
                  _error(
                    'メッセージの更新が止まっています',
                    () => ref.invalidate(contactChatMessagesProvider(page)),
                  ),
                Expanded(
                  child: displayedMessages.when(
                    skipLoadingOnRefresh: false,
                    data: (savedItems) {
                      final items = [
                        if (_pendingMessage != null &&
                            !savedItems.any(
                              (item) => item.id == _pendingMessage!.id,
                            ))
                          _pendingMessage!,
                        ...savedItems,
                      ];
                      if (items.isEmpty) return _empty();
                      return ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            if (items.length >= _limit)
                              return TextButton(
                                onPressed:
                                    messages.isLoading
                                        ? null
                                        : () => setState(() => _limit += 50),
                                child: const Text('さらに前のメッセージ'),
                              );
                            return _welcome();
                          }
                          final message = items[index];
                          final mine =
                              message.senderRole ==
                              (widget.asAdmin ? 'admin' : 'user');
                          final peerRead =
                              widget.asAdmin
                                  ? room?.userReadCount ?? 0
                                  : room?.adminReadCount ?? 0;
                          final day = message.createdAt?.toLocal();
                          final previous =
                              index + 1 < items.length
                                  ? items[index + 1].createdAt?.toLocal()
                                  : null;
                          final showDay =
                              day != null &&
                              (previous == null ||
                                  DateUtils.dateOnly(day) !=
                                      DateUtils.dateOnly(previous));
                          return Column(
                            children: [
                              if (showDay)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    DateFormat('yyyy/M/d').format(day),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              Align(
                                alignment:
                                    mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: .86,
                                  child: Column(
                                    crossAxisAlignment:
                                        mine
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                    children: [
                                      if (!mine ||
                                          message.senderRole == 'admin')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child:
                                              message.senderRole == 'admin'
                                                  ? _operatorHeader()
                                                  : Text(
                                                    widget.asAdmin
                                                        ? 'ユーザー'
                                                        : 'CIT App 運営',
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.labelSmall,
                                                  ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              mine
                                                  ? colors.primaryContainer
                                                  : colors
                                                      .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: _messageContent(
                                          message,
                                          style: TextStyle(
                                            color:
                                                mine
                                                    ? colors.onPrimaryContainer
                                                    : colors.onSurface,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          '${mine && message.senderSequence > 0 && peerRead >= message.senderSequence ? "既読  " : ""}${day == null ? (_pendingFailed && message.id == _pendingMessage?.id ? "未送信" : "送信中") : DateFormat("HH:mm").format(day)}',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (_, __) => Center(
                          child: _error(
                            'メッセージを読み込めませんでした',
                            () => ref.invalidate(
                              contactChatMessagesProvider(page),
                            ),
                          ),
                        ),
                  ),
                ),
                if (!_atBottom)
                  TextButton.icon(
                    onPressed:
                        () => _scroll.animateTo(
                          0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('最新のメッセージへ'),
                  ),
                if (_readError != null)
                  _error(_readError!, () => setState(() => _readError = null)),
                if (_sendError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _sendError!,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                if (widget.asAdmin)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ActionChip(
                        label: const Text('お礼の定型文を入力'),
                        avatar: const Icon(Icons.edit_note, size: 18),
                        onPressed:
                            _sending
                                ? null
                                : () {
                                  const message =
                                      'いつもCIT Appをご利用いただき誠にありがとうございます。\n今後ともCITをよろしくお願いいたします。';
                                  final draft = _text.text.trimRight();
                                  _text.text =
                                      draft.isEmpty
                                          ? message
                                          : '$draft\n\n$message';
                                  _text.selection = TextSelection.collapsed(
                                    offset: _text.text.length,
                                  );
                                  setState(() {});
                                },
                      ),
                    ),
                  ),
                if (_images.isNotEmpty) _attachmentStrip(),
                if (_picking) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        key: const Key('contact-chat-attach'),
                        tooltip: '画像を添付',
                        onPressed:
                            enabled && !_sending && !_picking
                                ? _pickImages
                                : null,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                      Expanded(
                        child: TextField(
                          key: const Key('contact-chat-input'),
                          controller: _text,
                          readOnly: _sending,
                          minLines: 1,
                          maxLines: 3,
                          maxLength: contactChatMessageLimit,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'メッセージを入力',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const Key('contact-chat-send'),
                        tooltip: '送信',
                        onPressed:
                            enabled &&
                                    !_sending &&
                                    !_picking &&
                                    (_text.text.trim().isNotEmpty ||
                                        _images.isNotEmpty)
                                ? _send
                                : null,
                        icon:
                            _sending
                                ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _error(String text, VoidCallback retry) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        TextButton(onPressed: retry, child: const Text('再試行')),
      ],
    ),
  );

  Widget _messageContent(
    ContactChatMessage message, {
    TextStyle? style,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (message.id == _pendingMessage?.id)
        for (final image in _pendingImages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Image.memory(image, height: 150, fit: BoxFit.contain),
          ),
      for (final path in message.imagePaths)
        ContactChatImage(key: ValueKey(path), userId: widget.uid, path: path),
      if (message.text.isNotEmpty) SelectableText(message.text, style: style),
    ],
  );

  Widget _operatorHeader() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircleAvatar(
        radius: 14,
        backgroundImage: AssetImage('assets/icons/app_launcher_icon.png'),
      ),
      const SizedBox(width: 8),
      Text('CIT App 運営', style: Theme.of(context).textTheme.labelSmall),
    ],
  );

  Widget _welcome() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _operatorHeader(),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const SelectableText(contactChatWelcomeMessage),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _attachmentStrip() => SizedBox(
    height: 104,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _images.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder:
          (context, index) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _images[index],
                  height: 96,
                  width: 96,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton.filled(
                  tooltip: '添付画像を削除',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed:
                      _sending || _picking
                          ? null
                          : () => setState(() => _images.removeAt(index)),
                ),
              ),
            ],
          ),
    ),
  );

  Widget _empty() => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcome(),
          if (!widget.asAdmin) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final text in ['ちょっと質問したい', '不具合を報告したい', '機能を提案したい'])
                  ActionChip(
                    label: Text(text),
                    onPressed:
                        _sending
                            ? null
                            : () {
                              _text.text = '$text\n';
                              setState(() {});
                            },
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
