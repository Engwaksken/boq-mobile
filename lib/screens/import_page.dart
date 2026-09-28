part of '../main.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  late Future<List<ProjectSummary>> _projects = widget.api.projects(
    perPage: 100,
  );
  int? _projectId;
  bool _uploading = false;

  /// Formats the server accepts; it converts them to a standard format.
  static const _extensions = [
    'xlsx',
    'xlsm',
    'ods',
    'xls',
    'csv',
    'tsv',
    'txt',
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Photos are re-encoded as JPEG by the picker (also converts HEIC on iOS).
  Future<void> _pickImage(ImageSource source) async {
    if (_projectId == null || _uploading) return;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: scanMaxSide.toDouble(),
        maxHeight: scanMaxSide.toDouble(),
        imageQuality: 80,
        requestFullMetadata: false,
      );
    } on Object {
      _showMessage(
        source == ImageSource.camera
            ? 'The camera could not be opened. Allow camera access in Settings and try again.'
            : 'Your photos could not be opened. Allow photo access in Settings and try again.',
      );
      return;
    }
    if (picked == null) return;
    final photo = picked;
    await _runUpload(photo.name, () async {
      final bytes = await photo.readAsBytes();
      return widget.api.uploadBoqFromBytes(
        projectId: _projectId!,
        fileName: _photoName(photo.name),
        bytes: bytes,
      );
    });
  }

  /// Picker output is JPEG; keep a readable name with a `.jpg` extension.
  String _photoName(String original) {
    final base = original.contains('.')
        ? original.substring(0, original.lastIndexOf('.'))
        : original;
    return '${base.isEmpty ? 'scan' : base}.jpg';
  }

  Future<void> _upload() async {
    if (_projectId == null || _uploading) return;
    FilePickerResult? selected;
    try {
      selected = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensions,
        // Phones upload from the file path so large files are not held in memory.
        withData: kIsWeb,
      );
    } on Object {
      // Some devices reject custom extension filters: fall back to any file.
      try {
        selected = await FilePicker.platform.pickFiles(withData: kIsWeb);
      } on Object {
        _showMessage('Files could not be opened on this device. Try again.');
        return;
      }
    }
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.single;
    final extension = (file.extension ?? '').toLowerCase();
    if (extension.isNotEmpty && !_extensions.contains(extension)) {
      _showMessage(
        'This file type is not supported. Upload Excel, CSV, PDF or a photo.',
      );
      return;
    }
    if (file.size > 20 * 1024 * 1024) {
      _showMessage('The file is larger than 20 MB. Choose a smaller file.');
      return;
    }
    final bytes = file.bytes;
    final path = kIsWeb ? null : file.path;
    if (bytes == null && path == null) {
      _showMessage('The file could not be read. Choose it again.');
      return;
    }
    await _runUpload(file.name, () async {
      // Photos are resized to JPEG and text files gzipped before upload.
      final prepared = await prepareUpload(
        name: file.name,
        path: path,
        bytes: path == null ? bytes : null,
      );
      if (prepared.compressed) {
        _showMessage(
          'Compressed ${describeCompression(prepared)}, uploading...',
        );
      }
      final preparedPath = prepared.path;
      return preparedPath != null
          ? widget.api.uploadBoq(
              projectId: _projectId!,
              filePath: preparedPath,
              name: prepared.name,
            )
          : widget.api.uploadBoqFromBytes(
              projectId: _projectId!,
              fileName: prepared.name,
              bytes: prepared.bytes!,
            );
    });
  }

  Future<void> _runUpload(
    String displayName,
    Future<BoqSummary> Function() upload,
  ) async {
    setState(() => _uploading = true);
    try {
      final boq = await upload();
      _showMessage('${widget.l10n.imported}: $displayName');
      await _reviewUploadedBoq(boq);
    } on Object catch (error) {
      _showMessage(friendlyError(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Auto-processes the uploaded BOQ ("Generate BOQ") then opens its
  /// review page so the user can verify items and fetch prices. Falls back
  /// to the project page when processing fails so nothing is lost.
  Future<void> _reviewUploadedBoq(BoqSummary boq) async {
    if (!mounted) return;
    final projectId = _projectId;
    try {
      final imported = await widget.api.processBoq(boq.id);
      if (!mounted) return;
      if (imported > 0) _showMessage('Imported $imported BOQ items');
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BoqItemsPage(api: widget.api, boqId: boq.id, title: boq.name),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage('${friendlyError(error)} (open the project to retry)');
      if (projectId == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProjectDetailPage(api: widget.api, projectId: projectId),
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
                        return ErrorState(
                          error: snapshot.error,
                          compact: true,
                          onRetry: () => setState(
                            () => _projects = widget.api.projects(perPage: 100),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: LinearProgressIndicator(),
                        );
                      }
                      final projects = snapshot.data!;
                      if (projects.isEmpty) {
                        return EmptyState(
                          compact: true,
                          icon: Icons.folder_open_outlined,
                          title: l10n.noProjects,
                          message:
                              'Create a project first, then import its BOQ.',
                        );
                      }
                      final selected = projects.any((p) => p.id == _projectId)
                          ? _projectId
                          : null;
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.projects,
                          prefixIcon: const Icon(Icons.folder_outlined),
                        ),
                        isEmpty: selected == null,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selected,
                            isExpanded: true,
                            isDense: true,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            items: [
                              for (final project in projects)
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
                    onTap: canUpload
                        ? () => _pickImage(ImageSource.camera)
                        : null,
                  ),
                  _ImportOptionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Choose photo',
                    subtitle: 'Pick a BOQ photo from your gallery',
                    tone: StatusTone.info,
                    onTap: canUpload
                        ? () => _pickImage(ImageSource.gallery)
                        : null,
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
