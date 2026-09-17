import 'package:flutter/material.dart';
import 'main_navigation_bar.dart';
import 'tab_tutorial_demo.dart';

const _topics = [
  (
    label: 'ホーム',
    topic: TutorialTopic.home,
    tabIndex: MainNavigation.homeIndex,
    icon: Icons.home_outlined,
    title: 'ホームカードの表示と順序',
    description: '右上のメニューから「ホームカードを編集」。表示するカードと並び順を選べます。',
    tip: '各カードの表示・非表示と並び順を変更できます。',
  ),
  (
    label: '時間割',
    topic: TutorialTopic.schedule,
    tabIndex: MainNavigation.scheduleIndex,
    icon: Icons.calendar_today_outlined,
    title: '時間割の登録・編集',
    description: '鉛筆を押すと編集モードに。Excel取り込みのボタンは、このモードで表示されます。',
    tip: '表示モードでは講義をタップして詳細を確認。出欠管理はチェック表のアイコンから開けます。',
  ),
  (
    label: '課題管理',
    topic: TutorialTopic.assignments,
    tabIndex: MainNavigation.scheduleIndex,
    icon: Icons.assignment_outlined,
    title: '課題の登録・締切・完了',
    description: '時間割の学期ボタン横にある「課題」から開きます。「課題を登録」で課題名と締切を入力します。',
    tip: '未完了の課題は締切順に並び、ホームにも表示されます。講義詳細の「この講義の課題を登録」も使えます。',
  ),
  (
    label: '交流',
    topic: TutorialTopic.community,
    tabIndex: MainNavigation.communityIndex,
    icon: Icons.groups_outlined,
    title: 'Cwitter・ちばちゃんねる',
    description: '上部のタブで、Cwitterとちばちゃんねるを切り替えられます。',
    tip: 'CwitterはID付きの投稿、ちばちゃんねるは匿名のスレッド形式です。',
  ),
  (
    label: '掲示板',
    topic: TutorialTopic.bulletin,
    tabIndex: MainNavigation.bulletinIndex,
    icon: Icons.campaign_outlined,
    title: '掲示板の検索・投稿',
    description: 'カテゴリで投稿を絞り込めます。右上の＋から投稿を申請できます。',
    tip: '投稿は承認後に公開されます。掲載ルールは右上のⓘから確認できます。',
  ),
  (
    label: 'マイページ',
    topic: TutorialTopic.profile,
    tabIndex: MainNavigation.profileIndex,
    icon: Icons.person_outline,
    title: 'メインキャンパスの設定',
    description: '「メインキャンパスを設定」で選ぶと、ホームの天気や学バスの初期表示に反映されます。',
    tip: 'このガイドは「マイページ → チュートリアルを確認」から、いつでも見直せます。',
  ),
];

/// Tutorial pages and bottom-navigation destinations have independent indices.
class TutorialDestination {
  const TutorialDestination(this.tabIndex, {this.showAssignments = false});
  final int tabIndex;
  final bool showAssignments;
}

/// Campus changes are staged until completion; all other examples stay local.
class VisualTabTutorial extends StatefulWidget {
  const VisualTabTutorial({
    super.key,
    required this.initialCampus,
    required this.onSaveCampus,
  });

  final String initialCampus;
  final Future<void> Function(String campus) onSaveCampus;

  @override
  State<VisualTabTutorial> createState() => _VisualTabTutorialState();
}

class _VisualTabTutorialState extends State<VisualTabTutorial> {
  int _index = 0;
  final _scroll = ScrollController();
  String? _selectedCampus;
  bool _saving = false;
  String? _saveError;

  Future<void> _finish() async {
    if (_saving) return;
    final campus = _selectedCampus;
    if (campus == null) {
      Navigator.of(
        context,
      ).pop(const TutorialDestination(MainNavigation.homeIndex));
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSaveCampus(campus);
      if (mounted) {
        Navigator.of(
          context,
        ).pop(const TutorialDestination(MainNavigation.homeIndex));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'キャンパスを保存できませんでした。もう一度お試しください。';
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _topics.length || index == _index) return;
    FocusScope.of(context).unfocus();
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final topic = _topics[_index];
    final last = _index == _topics.length - 1;
    final number = _index + 1;
    return PopScope(
      canPop: !_saving,
      child: AbsorbPointer(
        absorbing: _saving,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 820),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '使い方ガイド',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        key: const Key('tutorial_skip'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('あとで'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$number / ${_topics.length} ・ ${topic.label}',
                          key: const Key('tutorial_progress'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (var i = 0; i < _topics.length; i++)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Semantics(
                                    selected: i == _index,
                                    child: IconButton(
                                      key: ValueKey('tutorial_topic_$i'),
                                      tooltip: '${_topics[i].label}の使い方',
                                      onPressed: () => _goTo(i),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(48, 48),
                                        padding: EdgeInsets.zero,
                                        backgroundColor:
                                            i == _index
                                                ? colors.primaryContainer
                                                : colors
                                                    .surfaceContainerHighest,
                                        foregroundColor:
                                            i == _index
                                                ? colors.onPrimaryContainer
                                                : colors.onSurfaceVariant,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          side: BorderSide(
                                            color:
                                                i == _index
                                                    ? colors.primary
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(_topics[i].icon),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          topic.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          topic.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                last ? 'メインキャンパスを選ぶ' : '操作例',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TabTutorialDemo(
                          topic: topic.topic,
                          selectedCampus:
                              _selectedCampus ?? widget.initialCampus,
                          onCampusChanged:
                              (campus) => setState(() {
                                _selectedCampus = campus;
                                _saveError = null;
                              }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          last
                              ? '「使い始める」で選んだキャンパスを保存します。'
                              : '見本の操作は、実際のデータに反映されません。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(topic.tip, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          key: const Key('tutorial_open_tab'),
                          onPressed:
                              () => Navigator.of(context).pop(
                                TutorialDestination(
                                  topic.tabIndex,
                                  showAssignments:
                                      topic.topic == TutorialTopic.assignments,
                                ),
                              ),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text('${topic.label}を開く'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _saveError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        if (_index > 0) ...[
                          OutlinedButton(
                            key: const Key('tutorial_back'),
                            onPressed: () => _goTo(_index - 1),
                            child: const Text('戻る'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton(
                            key: const Key('tutorial_next'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed:
                                _saving
                                    ? null
                                    : last
                                    ? _finish
                                    : () => _goTo(_index + 1),
                            child: Text(
                              _saving
                                  ? '保存中…'
                                  : last
                                  ? '使い始める'
                                  : '次へ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
