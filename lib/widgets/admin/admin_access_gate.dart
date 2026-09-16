import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/admin_provider.dart';
import '../../models/admin/admin_model.dart';

/// Creates protected content only after permissions are confirmed.
class AdminAccessGate extends ConsumerWidget {
  const AdminAccessGate({
    super.key,
    required this.title,
    required this.builder,
    this.allow,
  });
  final String title;
  final WidgetBuilder builder;
  final bool Function(AdminPermissions)? allow;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(currentUserAdminProvider)
      .when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        data:
            (permissions) =>
                permissions != null &&
                        (allow?.call(permissions) ?? permissions.isAdmin)
                    ? builder(context)
                    : _page(context, const Text('管理者権限が必要です')),
        loading: () => _page(context, const CircularProgressIndicator()),
        error:
            (_, __) => _page(
              context,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('管理者権限を確認できませんでした'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(currentUserAdminProvider),
                    child: const Text('再確認'),
                  ),
                ],
              ),
            ),
      );

  Widget _page(BuildContext context, Widget child) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}
