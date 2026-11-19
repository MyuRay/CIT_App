import 'dart:async';

/// An empty snapshot is data. A failed or silent first subscription must never
/// leave the notification screen waiting forever. Keep listening after timeout
/// so a late connection can still recover without losing incoming notifications.
Stream<T> withInitialNotificationTimeout<T>(
  Stream<T> source, {
  Duration timeout = const Duration(seconds: 12),
}) => Stream<T>.multi((controller) {
  var receivedEvent = false;
  final timer = Timer(timeout, () {
    receivedEvent = true;
    controller.addError(
      TimeoutException('通知の取得に時間がかかっています。再試行してください。', timeout),
    );
  });
  final subscription = source.listen(
    (value) {
      receivedEvent = true;
      timer.cancel();
      controller.add(value);
    },
    onError: (Object error, StackTrace stack) {
      receivedEvent = true;
      timer.cancel();
      controller.addError(error, stack);
    },
    onDone: () {
      timer.cancel();
      if (!receivedEvent)
        controller.addError(StateError('通知を取得できませんでした。再試行してください。'));
      controller.close();
    },
  );
  controller.onCancel = () {
    timer.cancel();
    return subscription.cancel();
  };
});
