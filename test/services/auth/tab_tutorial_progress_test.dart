import 'package:cit_app/services/auth/tab_tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'assignment guide is shown once to accounts that saw the older guide',
    () async {
      SharedPreferences.setMockInitialValues({
        'tab_tutorial_seen_version:existing': '2.0.0',
      });
      final prefs = await SharedPreferences.getInstance();
      final progress = TabTutorialProgress(prefs);
      expect(progress.shouldShow('existing'), isTrue);
      await progress.markSeen('existing');
      await prefs.reload();
      expect(TabTutorialProgress(prefs).shouldShow('existing'), isFalse);
    },
  );

  test(
    'new accounts do not inherit device-wide or another account completion',
    () async {
      SharedPreferences.setMockInitialValues({
        'tab_tutorial_seen_version': TabTutorialProgress.currentVersion,
      });
      final prefs = await SharedPreferences.getInstance();
      final progress = TabTutorialProgress(prefs);
      expect(progress.shouldShow('first'), isTrue);
      await progress.markSeen('first');
      expect(progress.shouldShow('first'), isFalse);
      expect(progress.shouldShow('new-signup'), isTrue);
      await progress.markSeen('new-signup');
      await prefs.reload();
      final restarted = TabTutorialProgress(prefs);
      expect(restarted.shouldShow('new-signup'), isFalse);
      expect(restarted.shouldShow('first'), isFalse);
      expect(restarted.shouldShow('another-signup'), isTrue);
    },
  );
}
