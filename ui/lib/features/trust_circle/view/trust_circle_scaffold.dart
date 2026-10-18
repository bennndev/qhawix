import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/mock_data_banner.dart';
import '../../../core/widgets/qhawix_app_bar.dart';
import '../../../core/widgets/status_banner.dart';
import '../domain/action_result.dart';

/// Frame shared by every Trust Circle screen: app bar, the example-data banner
/// above the content, a centered column of at most the content width and the
/// gutter. Children are separated by the large spacing step.
class TrustCircleScaffold extends StatelessWidget {
  const TrustCircleScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      appBar: QhawixAppBar(title: title),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: space.gutter,
                vertical: space.md,
              ),
              children: [
                const MockDataBanner(),
                for (final child in children) ...[
                  SizedBox(height: space.lg),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows what a command really did, word for word. A rejection reads as a
/// caution; an example-only result reads as information, never as success.
class ActionResultBanner extends StatelessWidget {
  const ActionResultBanner({super.key, required this.result});

  final ActionResult result;

  @override
  Widget build(BuildContext context) => StatusBanner(
    message: result.message,
    kind: result.isRejected
        ? StatusBannerKind.caution
        : StatusBannerKind.information,
  );
}
