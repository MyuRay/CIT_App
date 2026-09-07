import 'package:image_picker/image_picker.dart';

bool isGifXFile(XFile file) {
  final mime = file.mimeType?.toLowerCase();
  if (mime == 'image/gif') return true;
  final path = file.path.toLowerCase();
  final name = file.name.toLowerCase();
  return path.endsWith('.gif') || name.endsWith('.gif');
}

bool isHeicXFile(XFile file) {
  final mime = file.mimeType?.toLowerCase();
  if (mime == 'image/heic' || mime == 'image/heif') return true;
  final lower = '${file.path} ${file.name}'.toLowerCase();
  return lower.contains('.heic') || lower.contains('.heif');
}

bool isGifUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.path.toLowerCase().endsWith('.gif');
}

String imageUploadExtension(XFile file) {
  if (isGifXFile(file)) return 'gif';

  final mime = file.mimeType?.toLowerCase();
  if (mime == 'image/png') return 'png';
  if (mime == 'image/webp') return 'webp';
  if (mime == 'image/jpeg' || mime == 'image/jpg') return 'jpg';

  final lower = '${file.path} ${file.name}'.toLowerCase();
  if (lower.contains('.png')) return 'png';
  if (lower.contains('.webp')) return 'webp';
  return 'jpg';
}

String imageUploadContentType(XFile file) {
  return switch (imageUploadExtension(file)) {
    'gif' => 'image/gif',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

bool isSupportedPostImageXFile(XFile file) {
  if (isHeicXFile(file)) return false;

  final mime = file.mimeType?.toLowerCase();
  if (mime != null) {
    return mime.startsWith('image/');
  }
  final lower = '${file.path} ${file.name}'.toLowerCase();
  return lower.contains('.gif') ||
      lower.contains('.jpg') ||
      lower.contains('.jpeg') ||
      lower.contains('.png') ||
      lower.contains('.webp');
}
