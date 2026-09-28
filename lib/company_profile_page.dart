import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'app_errors.dart';

/// The user's own company identity, used to brand and watermark their BOQ PDFs.
class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {for (final key in CompanyProfile.keys) key: TextEditingController()};

  Map<String, String> _countries = const {};
  String? _logoUrl;
  String? _newLogoPath;
  bool _removeLogo = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  static const _labels = {
    'company_name': ('Company Name *', 'e.g. Riverside Builders Ltd', TextInputType.text),
    'registration_number': ('Registration Number', 'e.g. 80020001234567', TextInputType.text),
    'tin': ('TIN (if applicable)', 'e.g. 1000123456', TextInputType.text),
    'city': ('District/City', 'e.g. city, town or market', TextInputType.text),
    'physical_address': ('Physical Address', 'e.g. Plot 1, Main Street', TextInputType.streetAddress),
    'postal_address': ('Postal Address', 'e.g. P.O. Box 1234', TextInputType.text),
    'telephone': ('Telephone', '+256 700 000 000', TextInputType.phone),
    'alt_telephone': ('Alternative Telephone', '+256 700 000 001', TextInputType.phone),
    'email': ('Email', 'info@example.com', TextInputType.emailAddress),
    'website': ('Website', 'https://example.com', TextInputType.url),
    'description': ('Company Description', 'A short description of your business', TextInputType.multiline),
  };

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
      final results = await Future.wait([widget.api.companyProfile(), widget.api.countries()]);
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
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);
      if (picked == null) return;
      if (await File(picked.path).length() > 2 * 1024 * 1024) {
        _snack('The logo must be 2 MB or smaller.');
        return;
      }
      setState(() {
        _newLogoPath = picked.path;
        _removeLogo = false;
      });
    } on Object {
      _snack('The photo library could not be opened. Check the app\'s photo permission.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.api.saveCompanyProfile(
        {for (final entry in _controllers.entries) entry.key: entry.value.text.trim()},
        logoPath: _newLogoPath,
        removeLogo: _removeLogo,
      );
      setState(() {
        _logoUrl = saved.logoUrl;
        _newLogoPath = null;
        _removeLogo = false;
      });
      _snack('Company profile saved. New BOQ exports will use these details.');
    } on Object catch (error) {
      _snack(friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget? _logoImage({double size = 72}) {
    if (_newLogoPath != null) {
      return Image.file(File(_newLogoPath!), width: size, height: size, fit: BoxFit.contain);
    }
    if (_logoUrl != null && !_removeLogo) {
      return Image.network(
        _logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, size: size / 2),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _preview(context),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: _logoImage() ?? const Text('No logo', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.upload), label: const Text('Choose logo')),
                                if (_logoImage() != null)
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _newLogoPath = null;
                                      _removeLogo = true;
                                    }),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final key in CompanyProfile.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: key == 'country' ? _countryField() : _textField(key),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Company Profile'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'BOQs keep the company details they were first exported with, even if you change this profile later.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
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
      keyboardType: type,
      maxLines: key == 'description' ? 4 : 1,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (key == 'company_name' && text.isEmpty) return 'Company name is required.';
        if (text.isEmpty) return null;
        if (key == 'email' && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Enter a valid email address.';
        if ((key == 'telephone' || key == 'alt_telephone') && !RegExp(r'^\+?[0-9 ()-]{6,40}$').hasMatch(text)) {
          return 'Enter a valid phone number, including the country code.';
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
      decoration: const InputDecoration(labelText: 'Country'),
      items: [
        const DropdownMenuItem(value: '', child: Text('Select...')),
        for (final entry in _countries.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (value) => _controllers['country']!.text = value ?? '',
    );
  }

  /// Letterhead preview matching the PDF header.
  Widget _preview(BuildContext context) {
    String field(String key) => _controllers[key]!.text.trim();
    final lines = [
      [field('physical_address'), field('city'), _countries[field('country')] ?? ''].where((v) => v.isNotEmpty).join(', '),
      field('postal_address'),
      [field('telephone'), field('alt_telephone')].where((v) => v.isNotEmpty).join(' / '),
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
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF05645B), width: 2))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logo != null) ...[logo, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field('company_name').isEmpty ? 'Your Company Name' : field('company_name'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      for (final line in lines) Text(line, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const Text('BILL OF\nQUANTITIES', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF05645B))),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: Stack(
              children: [
                if (logo != null) Center(child: Opacity(opacity: .07, child: _logoImage(size: 80))),
                const Center(child: Text('PDF preview', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
