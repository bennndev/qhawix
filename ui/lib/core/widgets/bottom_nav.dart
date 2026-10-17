import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// One of the five app tabs.
enum QhawixTab {
  inicio('Inicio', Icons.home_outlined, Icons.home),
  analizar('Analizar', Icons.document_scanner_outlined, Icons.document_scanner),
  refugio('Refugio', Icons.shield_outlined, Icons.shield),
  red('Red', Icons.group_outlined, Icons.group),
  bitacora('Bitácora', Icons.menu_book_outlined, Icons.menu_book);

  const QhawixTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom navigation with the five tabs.
///
/// Surface fill, 80 dp minimum height that grows with the text scale, a 24 dp
/// icon above a label that wraps instead of being dropped, and a teal-tint
/// pill behind the selected icon. [labels] lets the caller override a label
/// (for example under the discreet appearance).
class QhawixBottomNav extends StatelessWidget {
  const QhawixBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
    this.labels = const {},
  });

  final QhawixTab selected;
  final ValueChanged<QhawixTab> onSelected;
  final Map<QhawixTab, String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    return Material(
      color: context.scheme.surface,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.space.bottomNavHeight),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tab in QhawixTab.values)
                  Expanded(
                    child: _NavItem(
                      tab: tab,
                      label: labels[tab] ?? tab.label,
                      selected: tab == selected,
                      colors: colors,
                      onTap: () => onSelected(tab),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final QhawixTab tab;
  final String label;
  final bool selected;
  final QhawixColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final fg = selected ? colors.accentDeep : colors.onSurfaceMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: space.touchMin),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: space.xs,
              vertical: space.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: selected ? colors.accentTint : Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: space.md,
                      vertical: space.xs,
                    ),
                    child: Icon(
                      selected ? tab.selectedIcon : tab.icon,
                      size: space.iconMd,
                      color: fg,
                    ),
                  ),
                ),
                SizedBox(height: space.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: context.text.labelSmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
