import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'circle_diagnosis_screen.dart';
import 'circle_events_screen.dart';

/// サークル・部活機能のメイン画面（新歓期間限定）
class CircleMainScreen extends ConsumerStatefulWidget {
  /// 初期表示タブ（0: 診断, 1: 体験会）
  final int initialTabIndex;

  const CircleMainScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<CircleMainScreen> createState() => _CircleMainScreenState();
}

class _CircleMainScreenState extends ConsumerState<CircleMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final idx = widget.initialTabIndex.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: idx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サークル・部活'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: '診断'),
            Tab(icon: Icon(Icons.event), text: '体験会'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CircleDiagnosisScreen(),
          CircleEventsScreen(),
        ],
      ),
    );
  }
}
