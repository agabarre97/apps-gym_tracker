import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gym_tracker/l10n/app_localizations.dart';

/// Shows a modal bottom sheet with "Copy to clipboard" and "Share" options.
///
/// Shared between routine detail and mobility routine detail screens
/// to avoid duplicating the export UI.
void showExportSheet(
  BuildContext context, {
  required String jsonString,
  Future<void> Function()? onExportPdf,
}) {
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.routineExportCopy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.routineExportCopied)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.routineExportShare),
              onTap: () {
                Navigator.of(ctx).pop();
                SharePlus.instance.share(
                  ShareParams(text: jsonString),
                );
              },
            ),
            if (onExportPdf != null)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(l10n.routineExportPdf),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await onExportPdf();
                },
              ),
          ],
        ),
      ),
    ),
  );
}
