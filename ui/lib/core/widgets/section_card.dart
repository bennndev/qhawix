import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// Surface card: 16 dp radius, 1 dp Mist border, 16 dp padding, no shadow.
///
/// With [onTap] the whole card is the tap target and at least 48 dp tall.
class QhawixCard extends StatelessWidget {
  const QhawixCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.minHeight,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final inner = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight ?? (onTap != null ? context.space.touchMin : 0),
      ),
      child: Padding(padding: padding ?? context.space.cardPadding, child: child),
    );
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? inner : InkWell(onTap: onTap, child: inner),
    );
    if (semanticLabel == null) return card;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: card,
    );
  }
}

/// A titled group inside one card (Headline small title, then the content).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return QhawixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.text.titleMedium),
          ),
          SizedBox(height: space.sm),
          ...children,
        ],
      ),
    );
  }
}
