import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/permission_rationale_screen.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/status_banner.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'trust_circle_scaffold.dart';

/// First-run setup for Red de Confianza: notifications, then ready.
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
      _note = status.isGranted ? null : 'Puedes activar notificaciones después.';
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
        title: 'Notificaciones',
        explanation:
            'Para avisarte de alertas de tu círculo cuando la app no está '
            'abierta. Es opcional.',
        bullets: const [
          'No leemos tu agenda: eliges un contacto con el selector del sistema.',
        ],
        onContinue: _busy ? () {} : _requestNotifications,
        onNotNow: () => setState(() => _step = 2),
      );
    }

    return TrustCircleScaffold(
      title: 'Red de Confianza',
      children: [
        if (_step == 0) ...[
          const PageHeader(
            title: 'Tu círculo',
            subtitle:
                'Personas de confianza. No necesitan tener QHAWIX. Los SMS '
                'salen de tu celular.',
          ),
          PrimaryButton(
            label: 'Continuar',
            onPressed: () => setState(() => _step = 1),
          ),
        ],
        if (_step == 2) ...[
          const PageHeader(
            title: 'Listo',
            subtitle: 'Agrega a tu primera persona de confianza.',
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
