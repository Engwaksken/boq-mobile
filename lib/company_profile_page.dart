import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'l10n/app_localizations.dart';
import 'app_errors.dart';
import 'theme/app_theme.dart';
import 'widgets/widgets.dart';

/// The user's own company identity, used to brand and watermark their BOQ PDFs.
class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    for (final key in CompanyProfile.keys) key: TextEditingController(),
  };

  Map<String, String> _countries = const {};
  String? _logoUrl;
  String? _newLogoPath;
  bool _removeLogo = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  /// Editing is limited to organisation admins and personal accounts.
  bool get _canEdit => widget.api.canManageCompanyProfile;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// Label, hint and keyboard for each profile field.
  Map<String, (String, String, TextInputType)> get _labels {
    final l10n = _l10n;
    return {
      'company_name': (
        l10n.coCompanyNameLabel,
        l10n.coCompanyNameHint,
        TextInputType.text,
      ),
      'registration_number': (
        l10n.coRegistrationNumber,
        '80020001234567',
        TextInputType.text,
      ),
      'tin': (l10n.coTin, '1000123456', TextInputType.text),
      'city': (l10n.coCity, l10n.coCityHint, TextInputType.text),
      'physical_address': (
        l10n.coPhysicalAddress,
        l10n.coPhysicalAddressHint,
        TextInputType.streetAddress,
      ),
      'postal_address': (
        l10n.coPostalAddress,
        l10n.coPostalAddressHint,
        TextInputType.text,
      ),
      'telephone': (l10n.coTelephone, '+256 700 000 000', TextInputType.phone),
      'alt_telephone': (
        l10n.coAltTelephone,
        '+256 700 000 001',
        TextInputType.phone,
      ),
      'email': (l10n.coEmail, 'info@example.com', TextInputType.emailAddress),
      'website': (l10n.coWebsite, 'https://example.com', TextInputType.url),
      'description': (
        l10n.coDescription,
        l10n.coDescriptionHint,
        TextInputType.multiline,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.addListener(() => setState(() {}));
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.api.companyProfile(),
        widget.api.countries(),
      ]);
      final profile = results[0] as CompanyProfile?;
      _countries = results[1] as Map<String, String>;
      if (profile != null) {
        for (final key in CompanyProfile.keys) {
          _controllers[key]!.text = profile.fields[key] ?? '';
        }
        _logoUrl = profile.logoUrl;
      }
    } on Object catch (error) {
      _loadError = friendlyError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      if (await File(picked.path).length() > 2 * 1024 * 1024) {
        if (mounted) _snack(_l10n.coLogoTooLarge);
        return;
      }
      if (!mounted) return;
      setState(() {
        _newLogoPath = picked.path;
        _removeLogo = false;
      });
    } on Object {
      if (mounted) _snack(_l10n.coPhotoLibraryDenied);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.api.saveCompanyProfile(
        {
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
        },
        logoPath: _newLogoPath,
        removeLogo: _removeLogo,
      );
      if (!mounted) return;
      setState(() {
        _logoUrl = saved.logoUrl;
        _newLogoPath = null;
        _removeLogo = false;
      });
      _snack(_l10n.coSaved);
    } on Object catch (error) {
      _snack(friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget? _logoImage({double size = 72}) {
    if (_newLogoPath != null) {
      return Image.file(
        File(_newLogoPath!),
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    if (_logoUrl != null && !_removeLogo) {
      return Image.network(
        _logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: size / 2),
      );
    }
    return null;
  }

  static const _fieldIcons = <String, IconData>{
    'company_name': Icons.business_outlined,
    'registration_number': Icons.numbers,
    'tin': Icons.receipt_outlined,
    'country': Icons.public,
    'city': Icons.location_city_outlined,
    'physical_address': Icons.location_on_outlined,
    'postal_address': Icons.markunread_mailbox_outlined,
    'telephone': Icons.phone_outlined,
    'alt_telephone': Icons.phone_forwarded_outlined,
    'email': Icons.email_outlined,
    'website': Icons.language,
    'description': Icons.notes_outlined,
  };

  /// Visual grouping of [CompanyProfile.keys]; any key not listed here is
  /// still rendered, in the last section.
  List<(String, IconData, List<String>)> get _sections => [
    (
      _l10n.coCompanyDetails,
      Icons.business_outlined,
      ['company_name', 'registration_number', 'tin', 'description'],
    ),
    (
      _l10n.coLocation,
      Icons.place_outlined,
      ['country', 'city', 'physical_address', 'postal_address'],
    ),
    (
      _l10n.coContact,
      Icons.contact_phone_outlined,
      ['telephone', 'alt_telephone', 'email', 'website'],
    ),
  ];

  Widget _field(String key) =>
      key == 'country' ? _countryField() : _textField(key);

  List<Widget> _formSections() {
    final sections = _sections;
    final grouped = {for (final section in sections) ...section.$3};
    final leftovers = CompanyProfile.keys
        .where((key) => !grouped.contains(key))
        .toList();
    final widgets = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final (title, icon, keys) = sections[i];
      final sectionKeys = [
        ...keys.where(CompanyProfile.keys.contains),
        if (i == sections.length - 1) ...leftovers,
      ];
      if (sectionKeys.isEmpty) continue;
      widgets
        ..add(
          SectionCard(
            title: title,
            icon: icon,
            spacing: AppSpacing.lg,
            children: [for (final key in sectionKeys) _field(key)],
          ),
        )
        ..add(const SizedBox(height: AppSpacing.lg));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.acctCompanyProfile)),
      body: _loading
          ? const LoadingState()
          : _loadError != null
          ? ErrorState(error: _loadError, onRetry: _load)
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(
                          title: l10n.coPreviewTitle,
                          subtitle: l10n.coPreviewSubtitle,
                        ),
                        _preview(context),
                        const SizedBox(height: AppSpacing.sectionGap),
                        SectionCard(
                          title: l10n.coLogo,
                          icon: Icons.image_outlined,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerLow,
                                    border: Border.all(
                                      color: scheme.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child:
                                      _logoImage() ??
                                      Text(
                                        l10n.coNoLogo,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if (_canEdit) ...[
                                        OutlinedButton.icon(
                                          onPressed: _pickLogo,
                                          icon: const Icon(Icons.upload),
                                          label: Text(l10n.coChooseLogo),
                                        ),
                                        if (_logoImage() != null)
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: scheme.error,
                                            ),
                                            onPressed: () => setState(() {
                                              _newLogoPath = null;
                                              _removeLogo = true;
                                            }),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: Text(l10n.coRemove),
                                          ),
                                      ] else
                                        Text(
                                          l10n.coLogoManaged,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ..._formSections(),
                        const SizedBox(height: AppSpacing.sm),
                        if (_canEdit)
                          LoadingButton(
                            label: l10n.coSaveProfile,
                            icon: Icons.save_outlined,
                            loading: _saving,
                            onPressed: _save,
                          )
                        else
                          InfoBanner(message: l10n.coProfileManaged),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.coDetailsKept,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _textField(String key) {
    final (label, hint, type) = _labels[key]!;
    return TextFormField(
      controller: _controllers[key],
      enabled: _canEdit,
      keyboardType: type,
      maxLines: key == 'description' ? 4 : 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: key == 'description' ? null : Icon(_fieldIcons[key]),
        alignLabelWithHint: key == 'description',
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (key == 'company_name' && text.isEmpty) {
          return _l10n.coNameRequired;
        }
        if (text.isEmpty) return null;
        if (key == 'email' &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return _l10n.commonInvalidEmail;
        }
        if ((key == 'telephone' || key == 'alt_telephone') &&
            !RegExp(r'^\+?[0-9 ()-]{6,40}$').hasMatch(text)) {
          return _l10n.coInvalidPhone;
        }
        return null;
      },
    );
  }

  Widget _countryField() {
    final current = _controllers['country']!.text;
    return DropdownButtonFormField<String>(
      initialValue: _countries.containsKey(current) ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: _l10n.coCountry,
        prefixIcon: Icon(_fieldIcons['country']),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(_l10n.coSelect)),
        for (final entry in _countries.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _canEdit
          ? (value) => _controllers['country']!.text = value ?? ''
          : null,
    );
  }

  /// Letterhead preview matching the PDF header.
  Widget _preview(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String field(String key) => _controllers[key]!.text.trim();
    final lines = [
      [
        field('physical_address'),
        field('city'),
        _countries[field('country')] ?? '',
      ].where((v) => v.isNotEmpty).join(', '),
      field('postal_address'),
      [
        field('telephone'),
        field('alt_telephone'),
      ].where((v) => v.isNotEmpty).join(' / '),
      [field('email'), field('website')].where((v) => v.isNotEmpty).join(' · '),
    ].where((line) => line.isNotEmpty);
    final logo = _logoImage(size: 48);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logo != null) ...[
                  logo,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field('company_name').isEmpty
                            ? _l10n.coYourCompanyName
                            : field('company_name'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      for (final line in lines)
                        Text(
                          line,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _l10n.coBillOfQuantities,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: Stack(
              children: [
                if (logo != null)
                  Center(
                    child: Opacity(opacity: .07, child: _logoImage(size: 80)),
                  ),
                Center(
                  child: Text(
                    _l10n.coPdfPreview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
