import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'assignment_tutorial_demo.dart';

enum TutorialTopic { home, schedule, assignments, community, bulletin, profile }

/// Intentionally independent of providers, storage, APIs and user content.
class TabTutorialDemo extends StatefulWidget {
  const TabTutorialDemo({
    super.key,
    required this.topic,
    required this.selectedCampus,
    required this.onCampusChanged,
  });
  final TutorialTopic topic;
  final String selectedCampus;
  final ValueChanged<String> onCampusChanged;

  @override
  State<TabTutorialDemo> createState() => _TabTutorialDemoState();
}

class _TabTutorialDemoState extends State<TabTutorialDemo> {
  bool _homeMenu = false;
  bool _homeEditing = false;
  final _homeCards = ['学バス', '天気'];
  final _hiddenCards = <String>{};
  bool _scheduleEditing = false;
  bool _scheduleImported = false;
  bool _attendance = false;
  bool _anonymous = false;
  bool _postForm = false;
  bool _bulletinRules = false;
  bool _campusSettings = false;
  bool get _narashino => widget.selectedCampus == 'narashino';

  ThemeData get theme => Theme.of(context);
  ColorScheme get colors => theme.colorScheme;

  Widget _action({
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) => IconButton.filledTonal(
    key: ValueKey(id),
    tooltip: label,
    onPressed: onTap,
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      side: BorderSide(color: colors.primary, width: 1.5),
    ),
    icon: Icon(icon),
  );

  Widget _header(String title, List<Widget> actions) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...actions,
      ],
    ),
  );

  Widget _hint(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onPrimaryContainer,
        ),
      ),
    ),
  );

  Widget _tile(IconData icon, String title, String detail, {Color? seed}) {
    final background =
        seed == null
            ? colors.surfaceContainerHighest
            : AppColors.tintedSurface(context, seed);
    final ink =
        seed == null
            ? colors.onSurface
            : AppColors.ensureContrast(seed, background);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ink, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
                const SizedBox(height: 4),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _home() => Column(
    children: [
      _header('ホーム', [
        _action(
          id: 'demo_home_menu',
          label: '見本：ホームカード設定',
          icon: Icons.menu,
          onTap: () => setState(() => _homeMenu = !_homeMenu),
        ),
      ]),
      if (_homeMenu && !_homeEditing)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            key: const Key('demo_home_edit'),
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('ホームカードを編集'),
            onPressed:
                () => setState(() {
                  _homeEditing = true;
                  _homeMenu = false;
                }),
          ),
        ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_homeEditing) ...[
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _homeCards.length,
                onReorder:
                    (oldIndex, newIndex) => setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      _homeCards.insert(
                        newIndex,
                        _homeCards.removeAt(oldIndex),
                      );
                    }),
                itemBuilder: (context, index) {
                  final name = _homeCards[index];
                  return Padding(
                    key: ValueKey(name),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        ReorderableDelayedDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                        Expanded(child: Text(name)),
                        Switch(
                          key: ValueKey('demo_home_visible_$name'),
                          value: !_hiddenCards.contains(name),
                          onChanged:
                              (visible) => setState(() {
                                if (visible) {
                                  _hiddenCards.remove(name);
                                } else {
                                  _hiddenCards.add(name);
                                }
                              }),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('demo_home_save'),
                  onPressed: () => setState(() => _homeEditing = false),
                  child: const Text('保存'),
                ),
              ),
              _hint('スイッチで表示を切り替え。≡を長押しして上下に動かし、保存します。'),
            ] else ...[
              for (final name in _homeCards)
                if (!_hiddenCards.contains(name)) ...[
                  _tile(
                    name == '学バス'
                        ? Icons.directions_bus
                        : Icons.wb_sunny_outlined,
                    name,
                    name == '学バス' ? '次の便まで 8分' : '晴れ 24°C',
                  ),
                  const SizedBox(height: 8),
                ],
              _hint('右上の≡をタップして、カードの設定を開いてみましょう。'),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _schedule() => Column(
    children: [
      _header(_scheduleEditing ? '時間割・編集中' : '時間割', [
        if (_scheduleEditing)
          _action(
            id: 'demo_schedule_import',
            label: '見本：Excelから自動入力',
            icon: Icons.upload_file,
            onTap:
                () => setState(() {
                  _scheduleImported = true;
                  _attendance = false;
                }),
          )
        else
          _action(
            id: 'demo_schedule_attendance',
            label: '見本：出欠管理',
            icon: Icons.fact_check_outlined,
            onTap: () => setState(() => _attendance = !_attendance),
          ),
        const SizedBox(width: 4),
        _action(
          id: 'demo_schedule_edit',
          label: _scheduleEditing ? '見本：表示モードに切り替え' : '見本：編集モードに切り替え',
          icon: _scheduleEditing ? Icons.visibility : Icons.edit,
          onTap:
              () => setState(() {
                _scheduleEditing = !_scheduleEditing;
                _attendance = false;
              }),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final day in ['月', '火', '水'])
                  Expanded(child: Center(child: Text(day))),
              ],
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color:
                              i == 0 || _scheduleImported
                                  ? AppColors.tintedSurface(
                                    context,
                                    [
                                      Colors.blue,
                                      Colors.green,
                                      Colors.orange,
                                    ][i],
                                  )
                                  : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          i == 0 || _scheduleImported
                              ? ['数学', '英語', '情報基礎'][i]
                              : '空き',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_attendance) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in [
                    ('出席 8', Colors.green),
                    ('遅刻 1', Colors.orange),
                    ('欠席 0', Colors.red),
                  ])
                    Chip(
                      label: Text(item.$1),
                      side: BorderSide.none,
                      backgroundColor: AppColors.tintedSurface(
                        context,
                        item.$2,
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.accent(context, item.$2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _hint(
              _attendance
                  ? 'チェック表のアイコンから、講義ごとの出欠をまとめて確認できます。'
                  : _scheduleImported
                  ? '取り込み後の見本です。実際はCITポータル「学生時間割」で出力したExcelを選び、内容を確認します。'
                  : _scheduleEditing
                  ? 'Excelのボタンが現れました。タップして取り込み後の見本を見てみましょう。'
                  : '右上の鉛筆をタップして、編集モードに切り替えてみましょう。',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _community() => Column(
    children: [
      _header('交流', []),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('demo_community_cwitter'),
                  label: const Text('Cwitter'),
                  selected: !_anonymous,
                  onSelected: (_) => setState(() => _anonymous = false),
                ),
                ChoiceChip(
                  key: const Key('demo_community_channel'),
                  label: const Text('ちばちゃんねる'),
                  selected: _anonymous,
                  onSelected: (_) => setState(() => _anonymous = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tile(
              _anonymous ? Icons.forum_outlined : Icons.chat_bubble_outline,
              _anonymous ? 'おすすめの学食メニューは？' : '今日のキャンパス',
              _anonymous ? '匿名の話題別スレッド・返信 12件' : '空きコマに友だちと学食へ。',
            ),
            const SizedBox(height: 12),
            _hint(
              _anonymous
                  ? 'ちばちゃんねるでは、スレッドを選んで話題に参加できます。'
                  : '上の「ちばちゃんねる」をタップ。2つの交流スペースを比べてみましょう。',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _bulletin() => Column(
    children: [
      _header('掲示板', [
        _action(
          id: 'demo_bulletin_rules',
          label: '見本：掲示板投稿について',
          icon: Icons.info_outline,
          onTap:
              () => setState(() {
                _bulletinRules = !_bulletinRules;
                _postForm = false;
              }),
        ),
        const SizedBox(width: 4),
        _action(
          id: 'demo_bulletin_add',
          label: '見本：投稿する',
          icon: Icons.add,
          onTap:
              () => setState(() {
                _postForm = !_postForm;
                _bulletinRules = false;
              }),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_postForm) ...[
              _tile(Icons.edit_note, '投稿内容を入力', 'タイトル・本文・カテゴリなど'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Icon(Icons.arrow_downward, size: 20),
              ),
              _tile(Icons.hourglass_top, '掲載を申請', '管理者の承認後に公開'),
            ] else
              _tile(
                _bulletinRules ? Icons.info_outline : Icons.campaign_outlined,
                _bulletinRules ? '掲載ルールの確認' : 'サークル体験会のお知らせ',
                _bulletinRules ? '実際のⓘボタンから掲載ルールを開けます。' : 'イベント・サークル・求人・クーポンなど',
              ),
            const SizedBox(height: 12),
            _hint(
              _postForm
                  ? '＋が投稿の入口です。内容を入力して申請し、承認を待ちます。'
                  : _bulletinRules
                  ? '申請前に掲載ルールを確認してください。'
                  : '右上の＋をタップして、掲載までの流れを見てみましょう。',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _profile() => Column(
    children: [
      _header('マイページ', []),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              key: const Key('demo_campus_settings'),
              onPressed:
                  () => setState(() => _campusSettings = !_campusSettings),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.school_outlined),
                    SizedBox(width: 8),
                    Expanded(child: Text('メインキャンパスを設定')),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
            if (_campusSettings) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final narashino in [false, true])
                    ChoiceChip(
                      key: ValueKey('demo_campus_$narashino'),
                      label: Text(narashino ? '新習志野' : '津田沼'),
                      selected: _narashino == narashino,
                      selectedColor: AppColors.tintedSurface(
                        context,
                        narashino ? Colors.green : Colors.blue,
                      ),
                      onSelected:
                          (_) => widget.onCampusChanged(
                            narashino ? 'narashino' : 'tsudanuma',
                          ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _tile(
              Icons.wb_sunny_outlined,
              _narashino ? '新習志野の天気' : '津田沼の天気',
              'ホームに表示されるキャンパスの見本',
              seed: _narashino ? Colors.green : Colors.blue,
            ),
            const SizedBox(height: 12),
            _hint(
              _campusSettings
                  ? '選んだキャンパスは「使い始める」で保存され、ホームの初期表示に反映されます。'
                  : '設定の項目からキャンパスを選択できます。',
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.outlineVariant),
    ),
    child: switch (widget.topic) {
      TutorialTopic.home => _home(),
      TutorialTopic.schedule => _schedule(),
      TutorialTopic.assignments => const AssignmentTutorialDemo(),
      TutorialTopic.community => _community(),
      TutorialTopic.bulletin => _bulletin(),
      TutorialTopic.profile => _profile(),
    },
  );
}
