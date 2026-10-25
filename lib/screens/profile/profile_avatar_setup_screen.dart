import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user/profile_avatar_crop.dart';
import '../../services/user/profile_image_service.dart';
import '../../widgets/profile/profile_avatar_crop_editor.dart';
import '../../widgets/profile/profile_avatar_crop_view.dart';

enum _AvatarSetupStep { adjust, preview }

/// 画像選択後：位置調整 → プレビュー → 確定アップロード。
class ProfileAvatarSetupScreen extends StatefulWidget {
  const ProfileAvatarSetupScreen({
    super.key,
    required this.uid,
    required this.imageFile,
  });

  final String uid;
  final XFile imageFile;

  @override
  State<ProfileAvatarSetupScreen> createState() =>
      _ProfileAvatarSetupScreenState();
}

class _ProfileAvatarSetupScreenState extends State<ProfileAvatarSetupScreen> {
  _AvatarSetupStep _step = _AvatarSetupStep.adjust;
  ProfileAvatarCrop _crop = const ProfileAvatarCrop();
  Uint8List? _imageBytes;
  Uint8List? _previewBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    final bytes = await widget.imageFile.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  ImageProvider? get _imageProvider {
    final bytes = _imageBytes;
    if (bytes == null) return null;
    return MemoryImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == _AvatarSetupStep.adjust ? 'アイコンの位置調整' : 'アイコンのプレビュー',
        ),
        leading: BackButton(
          onPressed: _uploading ? null : _handleBack,
        ),
      ),
      body: SafeArea(
        child:
            imageProvider == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step == _AvatarSetupStep.adjust)
                        ProfileAvatarCropEditor(
                          image: imageProvider,
                          initialCrop: _crop,
                          viewportSize: _viewportSize(context),
                          onCropChanged: (crop) => _crop = crop,
                        )
                      else ...[
                        Text(
                          'この見た目でアイコンを設定します',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child:
                              _previewBytes != null
                                  ? ClipOval(
                                    child: Image.memory(
                                      _previewBytes!,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : ProfileAvatarCropView(
                                    image: imageProvider,
                                    crop: _crop,
                                    viewportSize: _viewportSize(context),
                                    previewSize: 160,
                                  ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '丸枠で囲んだ原画像の部分が、プロフィールアイコンとして表示されます。',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_step == _AvatarSetupStep.adjust)
                        FilledButton(
                          onPressed: _goToPreview,
                          child: const Text('プレビュー'),
                        )
                      else
                        FilledButton(
                          onPressed: _uploading ? null : _confirmUpload,
                          child:
                              _uploading
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('決定'),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  double _viewportSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 24;
    return width.clamp(300.0, 420.0);
  }

  void _handleBack() {
    if (_step == _AvatarSetupStep.preview) {
      setState(() => _step = _AvatarSetupStep.adjust);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _goToPreview() async {
    setState(() {
      _previewBytes = null;
      _step = _AvatarSetupStep.preview;
    });
    try {
      final bytes = await ProfileImageService.renderCroppedAvatarJpeg(
        file: widget.imageFile,
        crop: _crop,
      );
      if (!mounted) return;
      setState(() => _previewBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プレビューの生成に失敗しました')),
      );
    }
  }

  Future<void> _confirmUpload() async {
    setState(() => _uploading = true);
    try {
      final bytes =
          _previewBytes ??
          await ProfileImageService.renderCroppedAvatarJpeg(
            file: widget.imageFile,
            crop: _crop,
          );
      await ProfileImageService.uploadAvatarBytes(
        uid: widget.uid,
        jpegBytes: bytes,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイコンの保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
