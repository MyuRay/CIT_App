/// Accept only the known widget destinations, including iOS's homeWidget flag.
String? homeWidgetDestination(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme == 'schedule') return '/home?tab=schedule';
  if (uri.scheme.isNotEmpty && uri.scheme != 'citapp') return null;
  final target = uri.scheme == 'citapp' ? uri.host : uri.path;
  return switch (target) {
    'schedule' || '/schedule' => '/home?tab=schedule',
    'bus' || '/bus' => '/bus',
    _ => null,
  };
}
