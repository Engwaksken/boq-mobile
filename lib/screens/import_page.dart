part of '../main.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  late final Future<List<ProjectSummary>> _projects = widget.api.projects();
  int? _projectId;
  bool _uploading = false;
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = picked);
      _uploadPickedImage();
    }
  }

  Future<void> _uploadPickedImage() async {
    if (_projectId == null) return;
    final bytes = await _pickedImage!.readAsBytes();
    setState(() => _uploading = true);
    try {
      final boq = await widget.api.uploadBoqFromBytes(
        projectId: _projectId!,
        fileName: _pickedImage!.name,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.l10n.imported}: ${_pickedImage!.name}'),
        ),
      );
      await _reviewUploadedBoq(boq);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed: check the file and try again'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
      if (mounted) setState(() => _pickedImage = null);
    }
  }

  Future<void> _upload() async {
    if (_projectId == null) return;
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.single;
    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return;
    setState(() => _uploading = true);
    try {
      final boq = bytes != null
          ? await widget.api.uploadBoqFromBytes(
              projectId: _projectId!,
              fileName: file.name,
              bytes: bytes,
            )
          : await widget.api.uploadBoq(
              projectId: _projectId!,
              filePath: path!,
              name: file.name,
            );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.l10n.imported}: ${file.name}')),
      );
      await _reviewUploadedBoq(boq);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed: check the file and try again'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Auto-processes the uploaded BOQ ("Generate BOQ") then opens its
  /// review page so the user can verify items and fetch prices. Falls back
  /// to the project page when processing fails so nothing is lost.
  Future<void> _reviewUploadedBoq(BoqSummary boq) async {
    if (!mounted) return;
    try {
      final imported = await widget.api.processBoq(boq.id);
      if (!mounted) return;
      if (imported > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imported $imported BOQ items')));
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BoqItemsPage(api: widget.api, boqId: boq.id, title: boq.name),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${error.message} (open the project to retry)')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProjectDetailPage(api: widget.api, projectId: _projectId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final canUpload = _projectId != null && !_uploading;
    return ListView(
      padding: AppSpacing.page,
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconTile(icon: Icons.cloud_upload_outlined, size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.importTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.importDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              SectionCard(
                title: 'Choose project',
                icon: Icons.looks_one_outlined,
                children: [
                  FutureBuilder<List<ProjectSummary>>(
                    future: _projects,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return ErrorState(error: snapshot.error, compact: true);
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: LinearProgressIndicator(),
                        );
                      }
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.projects,
                          prefixIcon: const Icon(Icons.folder_outlined),
                        ),
                        isEmpty: _projectId == null,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _projectId,
                            isExpanded: true,
                            isDense: true,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            items: [
                              for (final project in snapshot.data!)
                                DropdownMenuItem(
                                  value: project.id,
                                  child: Text(
                                    project.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _projectId = value),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'Add your BOQ',
                icon: Icons.looks_two_outlined,
                spacing: AppSpacing.md,
                children: [
                  _ImportOptionCard(
                    icon: Icons.upload_file_outlined,
                    title: l10n.uploadDocument,
                    subtitle: l10n.supportedFiles,
                    onTap: canUpload ? _upload : null,
                  ),
                  _ImportOptionCard(
                    icon: Icons.document_scanner_outlined,
                    title: l10n.scanPages,
                    tone: StatusTone.info,
                    onTap: canUpload ? _pickImage : null,
                  ),
                ],
              ),
              if (_uploading) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  label: 'Uploading',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: const LinearProgressIndicator(minHeight: 6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Large tappable card for one way of bringing a BOQ into the app.
class _ImportOptionCard extends StatelessWidget {
  const _ImportOptionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone = StatusTone.brand,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconTile(icon: icon, tone: tone, size: 48),
                    const SizedBox(width: AppSpacing.md + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: theme.textTheme.titleSmall),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(subtitle!, style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
