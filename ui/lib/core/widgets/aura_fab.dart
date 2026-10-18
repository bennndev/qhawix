import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_extensions.dart';

/// Entry point to the AURA assistant (`/aura`): a 56 dp teal-tint circle with
/// the `visibility_outlined` icon. Flat, no gradient or shadow.
class AuraFab extends StatelessWidget {
  const AuraFab({super.key});

  static const label = 'Abrir AURA, tu asistente';

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    final space = context.space;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: colors.accentTint,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/aura'),
            child: SizedBox.square(
              dimension: space.fab,
              child: Icon(
                Icons.visibility_outlined,
                size: space.iconMd,
                color: colors.accentDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
