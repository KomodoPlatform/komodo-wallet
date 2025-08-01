import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/model/settings_menu_value.dart';

class SettingsMenuItem extends StatelessWidget {
  const SettingsMenuItem({
    Key? key,
    required this.menu,
    required this.isSelected,
    required this.onTap,
    required this.text,
    required this.isMobile,
    this.enabled = true,
  }) : super(key: key);

  final SettingsMenuValue menu;
  final String text;
  final bool isSelected;
  final bool enabled;
  final bool isMobile;
  final Function(SettingsMenuValue) onTap;

  @override
  Widget build(BuildContext context) {
    return isMobile ? _buildMobileItem(context) : _buildDesktopItem(context);
  }

  Widget _buildDesktopItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isSelected ? theme.custom.settingsMenuItemBackgroundColor : null,
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onTap: enabled ? () => onTap(menu) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 19, 0, 19),
          child: Text(
            text,

            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileItem(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onTap(menu) : null,
      borderRadius: BorderRadius.circular(18.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
