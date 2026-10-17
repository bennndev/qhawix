import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One 48 dp action icon of the app bar. Tooltip and semantic label are
/// required so the icon is never unlabeled.
class QhawixAction {
  const QhawixAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

/// 56 dp app bar: canvas fill, Headline small title on the left, the standard
/// 48 dp back button when the route can pop, and at most two actions.
class QhawixAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QhawixAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
  }) : assert(actions.length <= 2, 'The app bar shows at most two actions.');

  final String title;
  final List<QhawixAction> actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(QhawixDimensions.appBarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: automaticallyImplyLeading,
    title: Semantics(header: true, child: Text(title)),
    actions: [
      for (final action in actions)
        IconButton(
          icon: Icon(action.icon),
          tooltip: action.tooltip,
          onPressed: action.onPressed,
        ),
    ],
  );
}
