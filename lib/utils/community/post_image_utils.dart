import 'package:image_picker/image_picker.dart';

bool isGifXFile(XFile file) {
  final mime = file.mimeType?.toLowerCase();
  if (mime == 'image/gif') return true;
  final path = file.path.toLowerCase();
  final name = file.name.toLowerCase();
  return path.endsWith('.gif') || name.endsWith('.gif');
}

bool isGifUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.path.toLowerCase().endsWith('.gif');
}

String imageUploadExtension(XFile file) => isGifXFile(file) ? 'gif' : 'jpg';

String imageUploadContentType(XFile file) =>
    isGifXFile(file) ? 'image/gif' : 'image/jpeg';

bool isSupportedPostImageXFile(XFile file) {
  final mime = file.mimeType?.toLowerCase();
  if (mime != null) {
    return mime.startsWith('image/');
  }
  final lower = '${file.path} ${file.name}'.toLowerCase();
  return lower.contains('.gif') ||
      lower.contains('.jpg') ||
      lower.contains('.jpeg') ||
      lower.contains('.png') ||
      lower.contains('.webp') ||
      lower.contains('.heic') ||
      lower.contains('.heif');
}
