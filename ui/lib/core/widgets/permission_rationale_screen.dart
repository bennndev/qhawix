import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

/// Shown before the system permission prompt, never on app start.
///
/// The caller supplies Spanish copy that states only what the platform
/// guarantees: [title] names the one permission and the one module (for example
/// "Cámara para el Escudo QR"), [explanation] is the Body large paragraph and
/// [bullets] are the three short points (use, what stays on the device, what
/// happens if the person refuses). "Ahora no" returns with the manual
/// alternative visible.
class PermissionRationaleScreen extends StatelessWidget {
  const PermissionRationaleScreen({
    super.key,
    required this.title,
    required this.explanation,
    required this.bullets,
    required this.onContinue,
    required this.onNotNow,
  }) : assert(bullets.length == 3, 'Show exactly three bullets.');

  final String title;
  final String explanation;
  final List<String> bullets;
  final VoidCallback onContinue;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: context.text.headlineMedium),
                        ),
                        SizedBox(height: space.md),
                        Text(explanation, style: context.text.bodyLarge),
                        SizedBox(height: space.lg),
                        for (final bullet in bullets)
                          Padding(
                            padding: EdgeInsets.only(bottom: space.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: space.sm,
                                  color: context.qColors.accent,
                                ),
                                SizedBox(width: space.md),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: context.text.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(label: 'Continuar', onPressed: onContinue),
                      SizedBox(height: space.sm),
                      SecondaryButton(label: 'Ahora no', onPressed: onNotNow),
                    ],
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
