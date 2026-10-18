import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_app_bar.dart';
import '../../../core/widgets/status_banner.dart';

/// Entry screen for the Sentinel module. Placeholder until the module UI lands.
class SentinelScreen extends StatelessWidget {
  const SentinelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      appBar: QhawixAppBar(title: 'Sentinel'),
      body: SafeArea(
        child: Padding(
          padding: space.screenPadding,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Sentinel',
                subtitle:
                    'Aquí pegarás o compartirás mensajes para analizar señales '
                    'de engaño.',
              ),
              StatusBanner(
                message:
                    'Pantalla en construcción. El análisis aún no está conectado.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
