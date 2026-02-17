import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares PDF bytes in a cross-platform way (web + mobile/desktop).
Future<void> sharePdfBytes({
  required Uint8List pdfBytes,
  required String fileName,
  String? text,
}) async {
  final safeFileName = fileName.trim().isEmpty ? 'rutina.pdf' : fileName.trim();
  final normalizedFileName = safeFileName.toLowerCase().endsWith('.pdf')
      ? safeFileName
      : '$safeFileName.pdf';

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          pdfBytes,
          mimeType: 'application/pdf',
          name: normalizedFileName,
        ),
      ],
      text: text,
    ),
  );
}
