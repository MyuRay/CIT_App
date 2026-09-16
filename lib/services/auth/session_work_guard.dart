/// Invalidates delayed device writes when logout starts, including failed logout.
abstract final class SessionWorkGuard {
  static int _generation = 0;
  static bool _suspended = false;
  static int get generation => _generation;
  static bool isCurrent(int generation) =>
      !_suspended && generation == _generation;
  static void suspend() {
    _suspended = true;
    _generation++;
  }

  static void resume() {
    _suspended = false;
    _generation++;
  }
}
