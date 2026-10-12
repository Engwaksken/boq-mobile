import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';
import 'app_errors.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'widgets/widgets.dart';

enum BoqShareAction { preview, download, email, whatsapp, device }

List<(BoqShareAction, IconData, String)> _shareOptions(
  AppLocalizations l10n,
) => [
  (BoqShareAction.preview, Icons.visibility_outlined, l10n.sharePreviewPdf),
  (BoqShareAction.download, Icons.download_outlined, l10n.shareDownloadPdf),
  (BoqShareAction.email, Icons.email_outlined, l10n.shareByEmail),
  (BoqShareAction.whatsapp, Icons.chat_outlined, l10n.shareOnWhatsapp),
  (BoqShareAction.device, Icons.share_outlined, l10n.shareToOtherApps),
];

/// App-bar menu with every way to get a BOQ out of the app. The PDF is built
/// by the server and always carries the BOQ owner's company branding.
class BoqShareMenu extends StatelessWidget {
  const BoqShareMenu({
    super.key,
    required this.api,
    required this.boqId,
    required this.title,
  });

  final ApiClient api;
  final int boqId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<BoqShareAction>(
      icon: const Icon(Icons.picture_as_pdf_outlined),
      tooltip: l10n.sharePdfAndSharing,
      onSelected: (action) => BoqShareActions(
        api: api,
        boqId: boqId,
        title: title,
      ).run(context, action),
      itemBuilder: (context) => [
        for (final (action, icon, label) in _shareOptions(l10n))
          PopupMenuItem(
            value: action,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Opens the same choices as a bottom sheet (e.g. from a "Share" button).
Future<void> showBoqShareSheet(
  BuildContext context,
  ApiClient api,
  int boqId,
  String title,
) {
  final actions = BoqShareActions(api: api, boqId: boqId, title: title);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sharePdfAndSharing,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              for (final (action, icon, label) in _shareOptions(l10n))
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  leading: IconTile(icon: icon, size: 40),
                  title: Text(label),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    actions.run(context, action);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class BoqShareActions {
  const BoqShareActions({
    required this.api,
    required this.boqId,
    required this.title,
  });

  final ApiClient api;
  final int boqId;
  final String title;

  Future<void> run(BuildContext context, BoqShareAction action) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case BoqShareAction.preview:
        await _guard(context, l10n.shareOpeningPreview, () async {
          final link = await api.boqShareLink(boqId);
          final opened = await launchUrl(
            Uri.parse(link.url),
            mode: LaunchMode.inAppBrowserView,
          );
          if (!opened) {
            throw ApiException(l10n.sharePreviewFailed);
          }
        });
      case BoqShareAction.download:
        await _guard(context, l10n.shareDownloading, () async {
          final file = await _savePdf(permanent: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.shareSaved(file.uri.pathSegments.last)),
                action: SnackBarAction(
                  label: l10n.shareOpenSaveTo,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path, mimeType: 'application/pdf')],
                    ),
                  ),
                ),
              ),
            );
          }
        });
      case BoqShareAction.email:
        await _emailDialog(context, l10n);
      case BoqShareAction.whatsapp:
        await _guard(context, l10n.sharePreparingWhatsapp, () async {
          final link = await api.boqShareLink(boqId);
          final opened = await launchUrl(
            Uri.parse(link.whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!opened) {
            // WhatsApp not installed: fall back to the device share sheet.
            await SharePlus.instance.share(
              ShareParams(text: link.message, subject: title),
            );
          }
        });
      case BoqShareAction.device:
        await _guard(context, l10n.sharePreparingPdf, () async {
          final link = await api.boqShareLink(boqId);
          final file = await _savePdf(
            permanent: false,
            filename: link.filename,
          );
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/pdf')],
              text: link.message,
              subject: title,
            ),
          );
        });
    }
  }

  Future<File> _savePdf({required bool permanent, String? filename}) async {
    final bytes = await api.pdf(boqId);
    final directory = permanent
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final file = File('${directory.path}/${filename ?? 'boq-$boqId.pdf'}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _emailDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final email = TextEditingController();
    final subject = TextEditingController(text: l10n.shareEmailSubject(title));
    final message = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: const Icon(Icons.email_outlined),
          title: Text(l10n.shareByEmail),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.shareRecipientEmail,
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                    validator: (value) =>
                        value != null &&
                            RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())
                        ? null
                        : l10n.commonInvalidEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: subject,
                    decoration: InputDecoration(
                      labelText: l10n.shareSubject,
                      prefixIcon: const Icon(Icons.subject),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: message,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.shareMessageOptional,
                      hintText: l10n.shareMessageHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoBanner(
                    message: l10n.sharePdfAttached,
                    tone: BannerTone.info,
                    icon: Icons.attach_file,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              onPressed: sending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => sending = true);
                      try {
                        final result = await api.shareBoqByEmail(
                          boqId,
                          email: email.text.trim(),
                          subject: subject.text,
                          message: message.text,
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(result)));
                        }
                      } on Object catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => sending = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyError(error))),
                          );
                        }
                      }
                    },
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(l10n.shareSend),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows progress, and a friendly message if anything fails (no raw errors).
  Future<void> _guard(
    BuildContext context,
    String progress,
    Future<void> Function() task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(progress), duration: const Duration(seconds: 20)),
    );
    try {
      await task();
      messenger.hideCurrentSnackBar();
    } on Object catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }
}
