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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.importTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(l10n.importDescription),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: Color(0xFF1D4ED8),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ProjectSummary>>(
                future: _projects,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return DropdownButton<int>(
                    value: _projectId,
                    hint: Text(l10n.projects),
                    items: [
                      for (final project in snapshot.data!)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _projectId == null || _uploading ? null : _upload,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.uploadDocument),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.supportedFiles,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _projectId == null || _uploading ? null : _pickImage,
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(l10n.scanPages),
          ),
        ),
      ],
    );
  }
}
