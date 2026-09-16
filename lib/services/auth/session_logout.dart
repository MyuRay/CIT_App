/// Do not report a successful logout until this installation's subscription is
/// revoked. A network error leaves the current session available for retry.
class SessionLogout {
  const SessionLogout({
    required this.unregisterDevice,
    required this.clearLocalData,
    required this.signOut,
  });
  final Future<void> Function() unregisterDevice;
  final Future<void> Function() clearLocalData;
  final Future<void> Function() signOut;

  Future<void> run() async {
    await unregisterDevice();
    await clearLocalData();
    await signOut();
  }
}
