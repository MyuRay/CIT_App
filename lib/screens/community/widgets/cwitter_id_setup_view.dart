import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/schedule_provider.dart';
import '../../../services/community/cwitter_service.dart';
import 'cwitter_profile_screen.dart';

class CwitterIdSetupView extends ConsumerStatefulWidget {
  const CwitterIdSetupView({super.key});

  @override
  ConsumerState<CwitterIdSetupView> createState() => _CwitterIdSetupViewState();
}

class _CwitterIdSetupViewState extends ConsumerState<CwitterIdSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  bool _isSubmitting = false;
  bool? _isAvailable;
  String? _availabilityMessage;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final raw = _idController.text.trim();
    if (!CwitterService.isValidCwitterIdFormat(raw)) {
      setState(() {
        _isAvailable = null;
        _availabilityMessage = null;
      });
      return;
    }

    try {
      final available = await CwitterService.isCwitterIdAvailable(raw);
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
        _availabilityMessage = available
            ? 'このIDは利用できます'
            : AppConstants.errorCwitterIdTaken;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAvailable = null;
        _availabilityMessage = '確認に失敗しました';
      });
    }
  }

  Future<void> _submit(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final id = await CwitterService.claimCwitterId(
        uid: uid,
        rawId: _idController.text.trim(),
      );
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const CwitterProfileScreen(showInitialProfileSetup: true),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cwitter ID @$id を設定しました')),
      );
    } on CwitterIdAlreadyTakenException {
      if (!mounted) return;
      setState(() {
        _isAvailable = false;
        _availabilityMessage = AppConstants.errorCwitterIdTaken;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.errorCwitterIdTaken)),
      );
    } on CwitterIdAlreadySetException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          Icons.alternate_email,
          size: 56,
          color: colorScheme.brightness == Brightness.dark
              ? const Color(0xFF81C784)
              : const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 16),
        Text(
          'Cwitter IDを設定',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Cwitterを使うには、Cwitter内で使うIDの設定が必要です。\n'
          '半角英数字で3〜10文字で作成してください。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: 'Cwitter ID',
                      hintText: '例: cit2024',
                      prefixText: '@',
                      helperText: AppConstants.cwitterIdInputHelper,
                      suffixIcon: _isAvailable == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : _isAvailable == false
                              ? const Icon(Icons.cancel, color: Colors.red)
                              : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]'),
                      ),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      setState(() {
                        _isAvailable = null;
                        _availabilityMessage = null;
                      });
                    },
                    onFieldSubmitted: (_) => _checkAvailability(),
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) {
                        return 'Cwitter IDを入力してください';
                      }
                      if (!CwitterService.isValidCwitterIdFormat(raw)) {
                        return AppConstants.errorCwitterIdFormat;
                      }
                      return null;
                    },
                  ),
                  if (_availabilityMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _availabilityMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isAvailable == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _checkAvailability,
                    child: const Text('利用可能か確認'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final uid = ref.read(currentUserIdProvider);
                            if (uid == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ログインが必要です'),
                                ),
                              );
                              return;
                            }
                            await _submit(uid);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('IDを設定してはじめる'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
