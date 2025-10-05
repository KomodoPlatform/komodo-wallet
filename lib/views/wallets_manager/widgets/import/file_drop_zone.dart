import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FileDropZone extends StatefulWidget {
  const FileDropZone({
    required this.onFileSelected,
    this.acceptedExtensions = const ['.dat', '.json', '.txt'],
    super.key,
  });

  final void Function(String fileName, String fileContent) onFileSelected;
  final List<String> acceptedExtensions;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;
  String? _selectedFileName;
  bool _isLoading = false;

  Future<void> _handleFilePick() async {
    setState(() => _isLoading = true);

    try {
      await FileLoader.fromPlatform().upload(
        onUpload: (fileName, fileData) {
          if (fileData != null && fileData.isNotEmpty) {
            setState(() {
              _selectedFileName = fileName;
              _isLoading = false;
            });
            widget.onFileSelected(fileName, fileData);
          } else {
            setState(() => _isLoading = false);
            _showError(LocaleKeys.importFileEmptyError.tr());
          }
        },
        onError: (String error) {
          setState(() => _isLoading = false);
          log(
            error,
            path: 'file_drop_zone => _handleFilePick => onError',
            isError: true,
          );
          _showError(error);
        },
        fileType: LoadFileType.text,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      log(
        e.toString(),
        path: 'file_drop_zone => _handleFilePick',
        isError: true,
      );
      _showError(LocaleKeys.importFileError.tr());
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _isLoading ? null : _handleFilePick,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isDragging = true),
        onExit: (_) => setState(() => _isDragging = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: _isDragging ? 2 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _isDragging
                ? theme.colorScheme.primary.withOpacity(0.05)
                : theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedFileName != null
                    ? Icons.check_circle_outline
                    : Icons.cloud_upload_outlined,
                size: 48,
                color: _selectedFileName != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              if (_selectedFileName != null) ...[
                Text(
                  _selectedFileName!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.importFileSelected.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  _isLoading
                      ? LocaleKeys.pleaseWait.tr()
                      : LocaleKeys.importFileDropZoneTitle.tr(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.importFileDropZoneDescription.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              if (!_isLoading && _selectedFileName == null)
                TextButton.icon(
                  onPressed: _handleFilePick,
                  icon: const Icon(Icons.folder_open),
                  label: Text(LocaleKeys.importFileChooseFile.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              if (_isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
