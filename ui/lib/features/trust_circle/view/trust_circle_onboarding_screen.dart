import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/permission_rationale_screen.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_banner.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'trust_circle_scaffold.dart';

/// First-run setup for Red de Confianza: explain limits, then notifications.
class TrustCircleOnboardingScreen extends StatefulWidget {
  const TrustCircleOnboardingScreen({super.key});

  @override
  State<TrustCircleOnboardingScreen> createState() =>
      _TrustCircleOnboardingScreenState();
}

class _TrustCircleOnboardingScreenState
    extends State<TrustCircleOnboardingScreen> {
  var _step = 0;
  var _busy = false;
  String? _note;

  Future<void> _requestNotifications() async {
    setState(() {
      _busy = true;
      _note = null;
    });
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = status.isGranted
          ? 'Notificaciones permitidas.'
          : 'Sin notificaciones: las alertas en la app seguirán, '
              'pero el sistema no te avisará afuera.';
      _step = 2;
    });
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await context.read<TrustCircleViewModel>().completeSetup();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return PermissionRationaleScreen(
        title: 'Notificaciones para Red de Confianza',
        explanation:
            'Las usamos para avisarte de alertas de tu círculo cuando la app '
            'no está abierta. Los contactos sin app reciben SMS o WhatsApp '
            'desde tu propio celular, no desde nuestros servidores.',
        bullets: const [
          'Avisos de alertas en este teléfono.',
          'No leemos tu lista de contactos: eliges uno con el selector del sistema.',
          'Si dices que no, el módulo sigue; solo faltan avisos del sistema.',
        ],
        onContinue: _busy ? () {} : _requestNotifications,
        onNotNow: () => setState(() => _step = 2),
      );
    }

    final space = context.space;
    return TrustCircleScaffold(
      title: 'Red de Confianza',
      children: [
        if (_step == 0) ...[
          const PageHeader(
            title: 'Tu círculo seguro',
            subtitle:
                'Agrega personas de confianza eligiendo un contacto del '
                'teléfono. No necesitan tener QHAWIX.',
          ),
          QhawixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qué pediremos', style: context.text.titleMedium),
                SizedBox(height: space.sm),
                Text(
                  '• Notificaciones (opcional pero recomendado).\n'
                  '• Selector de contactos del sistema (sin permiso de leer '
                  'toda tu agenda).',
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          ),
          const StatusBanner(
            message:
                'QHAWIX no envía mensajes desde el servidor a quien no '
                'instaló la app. Los SMS o WhatsApp salen de tu celular.',
          ),
          PrimaryButton(
            label: 'Continuar',
            onPressed: () => setState(() => _step = 1),
          ),
        ],
        if (_step == 2) ...[
          const PageHeader(
            title: 'Listo para agregar contactos',
            subtitle:
                'Elige personas desde tus contactos. Puedes avisarles que '
                'pueden recibir mensajes desde tu teléfono.',
          ),
          if (_note != null) StatusBanner(message: _note!),
          PrimaryButton(
            label: 'Empezar',
            loading: _busy,
            onPressed: _finish,
          ),
        ],
      ],
    );
  }
}
