import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/guardian_mascot/guardian_mascot.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_app_bar.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../viewmodel/aura_view_model.dart';

/// Bounded, on-device help using the existing QHAWIX safety guidance.
class AuraScreen extends StatefulWidget {
  const AuraScreen({super.key});

  @override
  State<AuraScreen> createState() => _AuraScreenState();
}

class _AuraScreenState extends State<AuraScreen> {
  final _viewModel = AuraViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      appBar: QhawixAppBar(title: 'AURA'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                final guide = _viewModel.guide;
                return ListView(
                  padding: space.screenPadding,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: PageHeader(title: '¿En qué te ayudo?'),
                        ),
                        SizedBox(width: space.sm),
                        GuardianMascot(
                          // A selected concern calls for attention, not a risk verdict.
                          state: guide == null
                              ? GuardianMascotState.idle
                              : GuardianMascotState.alert,
                          size: space.moduleCardHeight + space.lg,
                          bodyColor: context.qColors.accent,
                          lineColor: context.scheme.onPrimary,
                        ),
                      ],
                    ),
                    SizedBox(height: space.md),
                    const Text(
                      'Guías locales para decidir tu próximo paso. '
                      'AURA no analiza mensajes ni confirma identidades aquí.',
                    ),
                    SizedBox(height: space.lg),
                    if (guide == null)
                      for (final topic in AuraGuide.values) ...[
                        SecondaryButton(
                          label: topic.label,
                          onPressed: () => _viewModel.select(topic),
                        ),
                        SizedBox(height: space.sm),
                      ]
                    else ...[
                      Semantics(
                        liveRegion: true,
                        child: SectionCard(
                          title: guide.title,
                          children: [
                            for (final step in guide.steps) ...[
                              Text(step),
                              SizedBox(height: space.md),
                            ],
                            Text(guide.basis, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      SizedBox(height: space.md),
                      SecondaryButton(
                        label: 'Volver a las opciones',
                        onPressed: () => _viewModel.select(null),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
