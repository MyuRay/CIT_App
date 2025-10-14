import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/schedule/schedule_model.dart';
import '../../models/schedule/academic_year_model.dart';
import '../../services/schedule/schedule_service.dart';
import 'auth_provider.dart';
import '../../services/widget/home_widgets_service.dart';

// グローバルなホーム画面リフレッシュ通知プロバイダー
final homeRefreshNotifierProvider = StateProvider<int>((ref) => 0);

// 現在のユーザーIDプロバイダー（Firebase Authから取得）
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

// 時間割プロバイダー
final scheduleProvider = FutureProvider.family<Schedule?, String>((ref, userId) async {
  return await ScheduleService.getScheduleByUserId(userId);
});

// 今日の時間割プロバイダー
final todayScheduleProvider = FutureProvider.family<List<ScheduleClass?>, String>((ref, userId) async {
  return await ScheduleService.getTodaySchedule(userId);
});

// 次の授業プロバイダー
final nextClassProvider = FutureProvider.family<ScheduleClass?, String>((ref, userId) async {
  return await ScheduleService.getNextClass(userId);
});

// 現在の時限プロバイダー
final currentPeriodProvider = FutureProvider.family<int?, String>((ref, userId) async {
  return await ScheduleService.getCurrentPeriod(userId);
});

// ユーザーの全時間割リストプロバイダー
final scheduleListProvider = FutureProvider.family<List<Schedule>, String>((ref, userId) async {
  return await ScheduleService.getAllSchedulesByUserId(userId);
});

// 時間割管理のStateNotifier
class ScheduleNotifier extends StateNotifier<AsyncValue<Schedule?>> {
  ScheduleNotifier(this._userId) : super(const AsyncValue.loading()) {
    _loadSchedule();
  }

  final String _userId;

  Future<void> _loadSchedule() async {
    try {
      state = const AsyncValue.loading();
      final schedule = await ScheduleService.getScheduleByUserId(_userId);
      state = AsyncValue.data(schedule);
      
      // ウィジェット更新（週間フル時間割）
      await _updateWidgets();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 時間割を再読み込み
  Future<void> refresh() async {
    await _loadSchedule();
  }

  // 初期時間割を作成（存在しない場合の明示作成ボタン用）
  Future<void> createInitialSchedule() async {
    try {
      state = const AsyncValue.loading();
      final schedule = await ScheduleService.createInitialSchedule(_userId);
      state = AsyncValue.data(schedule);
      await _updateWidgets();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 科目を追加
  Future<void> addClass({
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
    WidgetRef? ref, // ホーム画面のプロバイダーを無効化するために追加
  }) async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) {
        throw Exception('時間割が読み込まれていません');
      }

      // 既存の科目が編集中の場合、先に削除する
      final existingClass = currentSchedule.timetable[weekdayKey]?[period];
      if (existingClass != null && existingClass.id == scheduleClass.id) {
        await _removeClassSilently(weekdayKey: weekdayKey, period: period);
        // 削除後、最新の状態を取得
        await refresh();
        final updatedSchedule = state.value;
        if (updatedSchedule == null) {
          throw Exception('時間割の更新に失敗しました');
        }
      }

      // 連続講義の場合は複数の時限に登録
      for (int i = 0; i < scheduleClass.duration; i++) {
        final currentPeriod = period + i;
        
        // 10時限を超える場合はエラー
        if (currentPeriod > 10) {
          throw Exception('${scheduleClass.duration}時間連続講義は${period}限から開始できません（10限を超えます）');
        }

        // 既に授業がある場合はエラー
        final latestSchedule = state.value!;
        final existingClass = latestSchedule.timetable[weekdayKey]?[currentPeriod];
        if (existingClass != null) {
          throw Exception('${currentPeriod}限には既に「${existingClass.subjectName}」が登録されています');
        }

        final classToAdd = ScheduleClass(
          id: scheduleClass.id,
          subjectName: scheduleClass.subjectName,
          classroom: scheduleClass.classroom,
          instructor: scheduleClass.instructor,
          color: scheduleClass.color,
          notes: scheduleClass.notes,
          duration: scheduleClass.duration,
          isStartCell: i == 0, // 最初の時限のみtrue
        );

        await ScheduleService.addOrUpdateClass(
          scheduleId: latestSchedule.id,
          weekdayKey: weekdayKey,
          period: currentPeriod,
          scheduleClass: classToAdd,
        );
      }

      // 更新後のデータを取得
      await refresh();
      
      // ウィジェットを更新
      await _updateWidgets();
      
      // ホーム画面で表示される関連プロバイダーを無効化（ホーム画面の表示を更新）
      if (ref != null) {
        ref.invalidate(todayScheduleProvider(_userId));
        ref.invalidate(nextClassProvider(_userId));
        ref.invalidate(currentPeriodProvider(_userId));
        ref.invalidate(scheduleProvider(_userId));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 内部用の削除メソッド（エラーハンドリングなし）
  Future<void> _removeClassSilently({
    required String weekdayKey,
    required int period,
  }) async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) return;

      final targetClass = currentSchedule.timetable[weekdayKey]?[period];
      if (targetClass == null) return;

      // 連続講義の場合、IDで一括削除されるので、開始セルのperiodでのみ削除を実行
      if (targetClass.duration > 1) {
        // 開始セルかどうかをチェック
        if (targetClass.isStartCell) {
          // 開始セルの場合のみ削除実行（サービス側で全時限削除される）
          await ScheduleService.removeClass(
            scheduleId: currentSchedule.id,
            weekdayKey: weekdayKey,
            period: period,
          );
        } else {
          // 開始セルでない場合は開始セルを探して削除
          for (int p = period - 1; p >= 1; p--) {
            final previousClass = currentSchedule.timetable[weekdayKey]?[p];
            if (previousClass?.id == targetClass.id && previousClass?.isStartCell == true) {
              await ScheduleService.removeClass(
                scheduleId: currentSchedule.id,
                weekdayKey: weekdayKey,
                period: p, // 開始セルのperiodで削除
              );
              break;
            }
          }
        }
      } else {
        // 単体講義の場合
        await ScheduleService.removeClass(
          scheduleId: currentSchedule.id,
          weekdayKey: weekdayKey,
          period: period,
        );
      }
    } catch (e) {
      // サイレント削除なのでエラーは無視
      print('削除処理中のエラー（無視されます）: $e');
    }
  }

  // 科目を削除
  Future<void> removeClass({
    required String weekdayKey,
    required int period,
    WidgetRef? ref, // ホーム画面のプロバイダーを無効化するために追加
  }) async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) {
        throw Exception('時間割が読み込まれていません');
      }

      // 削除対象の科目を取得
      final targetClass = currentSchedule.timetable[weekdayKey]?[period];
      if (targetClass == null) {
        return; // 削除する科目がない場合は何もしない
      }

      // 連続講義の場合は関連する全ての時限を削除
      if (targetClass.duration > 1) {
        // 開始セルを見つける
        int startPeriod = period;
        if (!targetClass.isStartCell) {
          // 現在のセルが開始セルでない場合、開始セルを探す
          for (int p = period - 1; p >= 1; p--) {
            final previousClass = currentSchedule.timetable[weekdayKey]?[p];
            if (previousClass?.id == targetClass.id && previousClass?.isStartCell == true) {
              startPeriod = p;
              break;
            }
          }
        }

        // 関連する全ての時限を削除
        for (int i = 0; i < targetClass.duration; i++) {
          final periodToDelete = startPeriod + i;
          if (periodToDelete <= 10) {
            await ScheduleService.removeClass(
              scheduleId: currentSchedule.id,
              weekdayKey: weekdayKey,
              period: periodToDelete,
            );
          }
        }
      } else {
        // 単体講義の場合は指定された時限のみ削除
        await ScheduleService.removeClass(
          scheduleId: currentSchedule.id,
          weekdayKey: weekdayKey,
          period: period,
        );
      }

      // 更新後のデータを取得
      await refresh();
      
      // ウィジェットを更新
      await _updateWidgets();
      
      // ホーム画面で表示される関連プロバイダーを無効化（ホーム画面の表示を更新）
      if (ref != null) {
        ref.invalidate(todayScheduleProvider(_userId));
        ref.invalidate(nextClassProvider(_userId));
        ref.invalidate(currentPeriodProvider(_userId));
        ref.invalidate(scheduleProvider(_userId));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 時間割をクリア
  Future<void> clearSchedule() async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) {
        throw Exception('時間割が読み込まれていません');
      }

      await ScheduleService.clearSchedule(currentSchedule.id);

      // 更新後のデータを取得
      await refresh();
      
      // ウィジェットを更新
      await _updateWidgets();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // ウィジェット更新（週間フル時間割）
  Future<void> _updateWidgets() async {
    try {
      final schedule = await ScheduleService.getScheduleByUserId(_userId);
      if (schedule != null) {
        await HomeWidgetsService.updateWeeklyFullSchedule(schedule);
      }
    } catch (_) {}
  }

  // 1週間分の時間割を取得
  Future<Map<String, List<ScheduleClass?>>> _getWeeklySchedule() async {
    try {
      final schedule = await ScheduleService.getScheduleByUserId(_userId);
      if (schedule == null) return {};

      final weeklySchedule = <String, List<ScheduleClass?>>{};
      const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      
      for (final weekday in weekdays) {
        final daySchedule = schedule.timetable[weekday];
        if (daySchedule != null) {
          weeklySchedule[weekday] = List.generate(10, (index) => daySchedule[index + 1]);
        } else {
          weeklySchedule[weekday] = List.filled(10, null);
        }
      }
      
      return weeklySchedule;
    } catch (e) {
      print('❌ 週間時間割取得エラー: $e');
      return {};
    }
  }
}

// ScheduleNotifierプロバイダー
final scheduleNotifierProvider = StateNotifierProvider.family<ScheduleNotifier, AsyncValue<Schedule?>, String>((ref, userId) {
  return ScheduleNotifier(userId);
});

// 便利なプロバイダー（現在のユーザー用）
final currentUserScheduleProvider = Provider<AsyncValue<Schedule?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.loading();
  }
  return ref.watch(scheduleNotifierProvider(userId));
});

final currentUserTodayScheduleProvider = Provider<AsyncValue<List<ScheduleClass?>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.loading();
  }
  return ref.watch(todayScheduleProvider(userId));
});

final currentUserNextClassProvider = Provider<AsyncValue<ScheduleClass?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.loading();
  }
  return ref.watch(nextClassProvider(userId));
});

final currentUserCurrentPeriodProvider = Provider<AsyncValue<int?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.loading();
  }
  return ref.watch(currentPeriodProvider(userId));
});

// 週間時間割プロバイダー
final weeklyScheduleProvider = FutureProvider.family<Map<String, List<ScheduleClass?>>, String>((ref, userId) async {
  final schedule = await ScheduleService.getScheduleByUserId(userId);
  if (schedule == null) return {};

  final weeklySchedule = <String, List<ScheduleClass?>>{};
  const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  
  for (final weekday in weekdays) {
    final daySchedule = schedule.timetable[weekday];
    if (daySchedule != null) {
      weeklySchedule[weekday] = List.generate(10, (index) => daySchedule[index + 1]);
    } else {
      weeklySchedule[weekday] = List.filled(10, null);
    }
  }
  
  return weeklySchedule;
});

final currentUserWeeklyScheduleProvider = Provider<AsyncValue<Map<String, List<ScheduleClass?>>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.loading();
  }
  return ref.watch(weeklyScheduleProvider(userId));
});

// 科目リクエストクラス
class ClassRequest {
  final String weekdayKey;
  final int period;

  ClassRequest({required this.weekdayKey, required this.period});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassRequest &&
          runtimeType == other.runtimeType &&
          weekdayKey == other.weekdayKey &&
          period == other.period;

  @override
  int get hashCode => weekdayKey.hashCode ^ period.hashCode;
}

// 特定の曜日・時限の科目プロバイダー
final classProvider = Provider.family<ScheduleClass?, ClassRequest>((ref, request) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  
  final scheduleAsync = ref.watch(scheduleProvider(userId));
  
  return scheduleAsync.when(
    data: (schedule) {
      if (schedule == null) return null;
      final daySchedule = schedule.timetable[request.weekdayKey];
      return daySchedule?[request.period];
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// 特定の曜日の時間割プロバイダー
final dayScheduleProvider = Provider.family<List<ScheduleClass?>, String>((ref, weekdayKey) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return List.filled(10, null);
  
  final scheduleAsync = ref.watch(scheduleProvider(userId));
  
  return scheduleAsync.when(
    data: (schedule) {
      if (schedule == null) return List.filled(10, null);
      final daySchedule = schedule.timetable[weekdayKey];
      if (daySchedule == null) return List.filled(10, null);
      
      return List.generate(10, (index) => daySchedule[index + 1]);
    },
    loading: () => List.filled(10, null),
    error: (_, __) => List.filled(10, null),
  );
});

// 時間枠プロバイダー
final timeSlotsProvider = Provider<List<TimeSlot>>((ref) {
  return DefaultTimeSlots.citTimeSlots;
});

// 現在の曜日プロバイダー
final currentWeekdayProvider = Provider<String?>((ref) {
  return ScheduleUtils.getCurrentWeekdayKey();
});

// 今日が授業日かどうかのプロバイダー
final isSchoolDayProvider = Provider<bool>((ref) {
  return ScheduleUtils.getCurrentWeekdayKey() != null;
});

// =================
// 年度別時間割プロバイダー
// =================

// 現在の年度・学期プロバイダー
final currentAcademicYearProvider = Provider<AcademicYear>((ref) {
  return AcademicYear.current();
});

// 年度別切り替え機能を削除したが、互換性のためプロバイダーは残す（常に現在年度を返す）
final selectedAcademicYearProvider = StateProvider<AcademicYear>((ref) {
  return AcademicYear.current();
});

// 年度・学期別時間割プロバイダー
final scheduleByAcademicYearProvider = FutureProvider.family<Schedule?, (String, AcademicYear)>((ref, params) async {
  final (userId, academicYear) = params;
  return await ScheduleService.getScheduleByUserIdAndAcademicYear(userId, academicYear);
});

// ユーザーの年度・学期リストプロバイダー
final userAcademicYearsProvider = FutureProvider.family<List<AcademicYear>, String>((ref, userId) async {
  return await ScheduleService.getUserAcademicYears(userId);
});

// 現在のユーザーの年度・学期リストプロバイダー
final currentUserAcademicYearsProvider = Provider<AsyncValue<List<AcademicYear>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.loading();
  }
  return ref.watch(userAcademicYearsProvider(userId));
});

// 全年度リストプロバイダー（2023-2050）
final allAcademicYearsProvider = Provider<List<AcademicYear>>((ref) {
  return AcademicYear.getAllYears();
});

// 年度別切り替え機能を削除したが、互換性のためプロバイダーは残す（現在のスケジュールを返す）
final selectedAcademicYearScheduleProvider = Provider<AsyncValue<Schedule?>>((ref) {
  // 常に現在のユーザーのスケジュールを返す
  return ref.watch(currentUserScheduleProvider);
});

// 年度・学期管理のStateNotifier
class AcademicYearScheduleNotifier extends StateNotifier<AsyncValue<Schedule?>> {
  AcademicYearScheduleNotifier(this._userId, this._academicYear) : super(const AsyncValue.loading()) {
    _loadSchedule();
  }

  final String _userId;
  final AcademicYear _academicYear;

  Future<void> _loadSchedule() async {
    try {
      state = const AsyncValue.loading();
      final schedule = await ScheduleService.getScheduleByUserIdAndAcademicYear(_userId, _academicYear);
      state = AsyncValue.data(schedule);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 時間割を再読み込み
  Future<void> refresh() async {
    await _loadSchedule();
  }

  // 科目を追加（年度・学期指定）
  Future<void> addClass({
    required String weekdayKey,
    required int period,
    required ScheduleClass scheduleClass,
    WidgetRef? ref, // ホーム画面のプロバイダーを無効化するために追加
  }) async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) {
        throw Exception('時間割が読み込まれていません');
      }

      // 連続講義の場合は複数の時限に登録
      for (int i = 0; i < scheduleClass.duration; i++) {
        final currentPeriod = period + i;
        
        if (currentPeriod > 10) {
          throw Exception('${scheduleClass.duration}時間連続講義は${period}限から開始できません（10限を超えます）');
        }

        final latestSchedule = state.value!;
        final existingClass = latestSchedule.timetable[weekdayKey]?[currentPeriod];
        if (existingClass != null) {
          throw Exception('${currentPeriod}限には既に「${existingClass.subjectName}」が登録されています');
        }

        final classToAdd = ScheduleClass(
          id: scheduleClass.id,
          subjectName: scheduleClass.subjectName,
          classroom: scheduleClass.classroom,
          instructor: scheduleClass.instructor,
          color: scheduleClass.color,
          notes: scheduleClass.notes,
          duration: scheduleClass.duration,
          isStartCell: i == 0,
        );

        await ScheduleService.addOrUpdateClass(
          scheduleId: latestSchedule.id,
          weekdayKey: weekdayKey,
          period: currentPeriod,
          scheduleClass: classToAdd,
        );
      }

      await refresh();
      
      // ホーム画面で表示される関連プロバイダーを無効化（ホーム画面の表示を更新）
      if (ref != null) {
        ref.invalidate(todayScheduleProvider(_userId));
        ref.invalidate(nextClassProvider(_userId));
        ref.invalidate(currentPeriodProvider(_userId));
        ref.invalidate(scheduleProvider(_userId));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 科目を削除（年度・学期指定）
  Future<void> removeClass({
    required String weekdayKey,
    required int period,
    WidgetRef? ref, // ホーム画面のプロバイダーを無効化するために追加
  }) async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) {
        throw Exception('時間割が読み込まれていません');
      }

      await ScheduleService.removeClass(
        scheduleId: currentSchedule.id,
        weekdayKey: weekdayKey,
        period: period,
      );

      await refresh();
      
      // ホーム画面で表示される関連プロバイダーを無効化（ホーム画面の表示を更新）
      if (ref != null) {
        ref.invalidate(todayScheduleProvider(_userId));
        ref.invalidate(nextClassProvider(_userId));
        ref.invalidate(currentPeriodProvider(_userId));
        ref.invalidate(scheduleProvider(_userId));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 時間割をクリア（年度・学期指定）
  Future<void> clearSchedule() async {
    try {
      final currentSchedule = state.value;
      if (currentSchedule == null) {
        throw Exception('時間割が読み込まれていません');
      }

      await ScheduleService.clearSchedule(currentSchedule.id);
      await refresh();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// 年度・学期別ScheduleNotifierプロバイダー
final academicYearScheduleNotifierProvider = StateNotifierProvider.family<AcademicYearScheduleNotifier, AsyncValue<Schedule?>, (String, AcademicYear)>((ref, params) {
  final (userId, academicYear) = params;
  return AcademicYearScheduleNotifier(userId, academicYear);
});
