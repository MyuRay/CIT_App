import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 交流タブ（ボトムナビ）を開いている状態でもう一度タップされたことを通知するシグナル。
///
/// 値が増えるたびに [CommunityScreen] が Cwitter / ちばちゃんねる を切り替える。
final communityTabReselectSignalProvider = StateProvider<int>((ref) => 0);
