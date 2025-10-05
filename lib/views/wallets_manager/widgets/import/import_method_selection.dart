import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

enum ImportMethod { secretPhrase, seedFile }

class ImportMethodSelection extends StatelessWidget {
  const ImportMethodSelection({required this.onMethodSelected, super.key});

  final void Function(ImportMethod method) onMethodSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.importMethodTitle.tr(),
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Text(
          LocaleKeys.importMethodMostPopular.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _ImportMethodCard(
          key: const Key('import-method-secret-phrase'),
          icon: Icons.vpn_key_outlined,
          title: LocaleKeys.importMethodSecretPhrase.tr(),
          onTap: () => onMethodSelected(ImportMethod.secretPhrase),
        ),
        const SizedBox(height: 12),
        _ImportMethodCard(
          key: const Key('import-method-seed-file'),
          icon: Icons.insert_drive_file_outlined,
          title: LocaleKeys.importMethodSeedFile.tr(),
          onTap: () => onMethodSelected(ImportMethod.seedFile),
        ),
      ],
    );
  }
}

class _ImportMethodCard extends StatelessWidget {
  const _ImportMethodCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
