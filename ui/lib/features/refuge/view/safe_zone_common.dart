import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/permission_rationale_screen.dart';
import '../../../core/widgets/sheets_dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../domain/safe_zone_status.dart';
import '../viewmodel/command_note.dart';

/// Banner for the outcome of a command. A problem reads as a caution; it is
/// never worded as success.
class NoteBanner extends StatelessWidget {
  const NoteBanner({super.key, required this.note, this.onDismiss});

  final CommandNote note;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => StatusBanner(
    message: note.message,
    kind: note.isProblem
        ? StatusBannerKind.caution
        : StatusBannerKind.information,
    actionLabel: onDismiss == null ? null : 'Entendido',
    onAction: onDismiss,
  );
}

/// The feature needs the Android side; elsewhere the person is told so.
class SafeZoneUnavailableView extends StatelessWidget {
  const SafeZoneUnavailableView({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.phonelink_erase_outlined,
    title: 'Zona segura aún no conectada',
    message:
        'El menú ya funciona. Las alertas en segundo plano se conectan con '
        'los paquetes de Flutter (sin código Kotlin propio). Mientras tanto '
        'podés recorrer los demás módulos.',
  );
}

/// Calls [onResume] whenever the app returns to the foreground. The system
/// settings page of background location returns without a result.
class ResumeRefresh extends StatefulWidget {
  const ResumeRefresh({super.key, required this.onResume, required this.child});

  final VoidCallback onResume;
  final Widget child;

  @override
  State<ResumeRefresh> createState() => _ResumeRefreshState();
}

class _ResumeRefreshState extends State<ResumeRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onResume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Confirmation before any real SMS. Says it is real and may cost balance.
Future<bool> confirmRealSms(
  BuildContext context, {
  required int recipientCount,
}) => showConfirmationDialog(
  context: context,
  title: 'Enviar un SMS real',
  consequence:
      'Se enviará un SMS real a $recipientCount '
      '${recipientCount == 1 ? 'persona' : 'personas'} y puede costar saldo '
      'de tu chip. «Enviado» significa entregado a la red del operador, no '
      'que lo hayan recibido.',
  confirmLabel: 'Enviar SMS real',
  destructive: false,
);

/// Confirmation before the full pipeline, which also sends a real SMS.
Future<bool> confirmEndToEnd(
  BuildContext context, {
  required int recipientCount,
}) => showConfirmationDialog(
  context: context,
  title: 'Probar el proceso completo',
  consequence:
      'Se simula que saliste de casa: empieza la cuenta regresiva con su '
      'notificación y, si no la cancelas con tu PIN, se envía un SMS real a '
      '$recipientCount '
      '${recipientCount == 1 ? 'persona' : 'personas'}. Puede costar saldo '
      'de tu chip.',
  confirmLabel: 'Iniciar prueba con SMS real',
  destructive: false,
);

/// Rationale copy for each permission: one title, one paragraph, three bullets.
class _Rationale {
  const _Rationale(this.title, this.explanation, this.bullets);

  final String title;
  final String explanation;
  final List<String> bullets;
}

const _rationales = <PermissionKind, _Rationale>{
  PermissionKind.fineLocation: _Rationale(
    'Ubicación precisa para Refugio',
    'QHAWIX compara tu posición con la de tu casa para saber cuándo sales de '
        'la zona.',
    [
      'Se usa solo para detectar que saliste o volviste a casa.',
      'Tu ubicación se procesa en este teléfono y no se envía a ningún '
          'servidor.',
      'Si no la concedes, no se puede definir ni vigilar tu casa.',
    ],
  ),
  PermissionKind.backgroundLocation: _Rationale(
    'Ubicación todo el tiempo para Refugio',
    'Para avisar aunque la app esté cerrada, Android pide un permiso aparte. '
        'Al continuar te llevará a los ajustes de ubicación de QHAWIX: elige '
        '«Permitir todo el tiempo» y vuelve a la app.',
    [
      'Sin él solo se vigilaría con la app abierta.',
      'Se procesa en este teléfono; no se envía a ningún servidor.',
      'Si no lo concedes, el monitoreo no puede empezar.',
    ],
  ),
  PermissionKind.sendSms: _Rationale(
    'Enviar SMS para Refugio',
    'QHAWIX enviará por sí misma un SMS a las personas que elijas cuando se '
        'cumpla tu regla, aunque la app esté cerrada.',
    [
      'Se usa solo para estas alertas y para las pruebas que tú pidas.',
      'Los números y el mensaje se quedan en este teléfono; solo viajan como '
          'destino del SMS.',
      'Cada SMS puede costar saldo de tu chip. Sin el permiso no se puede '
          'avisar.',
    ],
  ),
  PermissionKind.notifications: _Rationale(
    'Notificaciones para Refugio',
    'Con cuenta regresiva, una notificación te deja cancelar el aviso antes '
        'de que se envíe.',
    [
      'Muestra la cuenta regresiva con un botón para cancelar con tu PIN.',
      'El texto de la notificación es neutro: no explica el motivo a quien '
          'mire tu pantalla.',
      'Sin ellas no verás la cuenta regresiva, y con cuenta regresiva el '
          'monitoreo no empieza.',
    ],
  ),
  PermissionKind.batteryOptimization: _Rationale(
    'Sin ahorro de batería para Refugio',
    'Algunos teléfonos detienen las apps en segundo plano para ahorrar '
        'batería, y entonces los avisos se retrasan o se cortan.',
    [
      'Android te mostrará una pantalla para que QHAWIX no sea optimizada.',
      'No da acceso a datos tuyos.',
      'Es opcional, pero sin él los avisos pueden retrasarse; algunos '
          'fabricantes igual pueden detener la app.',
    ],
  ),
};

/// Shows one rationale screen at a time for each of [kinds], in the order
/// given. "Continuar" calls [request]; "Ahora no" postpones that permission
/// and moves to the next. Nothing is requested before its rationale.
Future<void> runPermissionFlow(
  BuildContext context,
  List<PermissionKind> kinds,
  Future<void> Function(PermissionKind kind) request,
) async {
  for (final kind in kinds) {
    if (!context.mounted) return;
    final r = _rationales[kind]!;
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => PermissionRationaleScreen(
          title: r.title,
          explanation: r.explanation,
          bullets: r.bullets,
          onContinue: () => Navigator.of(routeContext).pop(true),
          onNotNow: () => Navigator.of(routeContext).pop(false),
        ),
      ),
    );
    if (accepted == true) await request(kind);
  }
}

/// A scrolling column centered at the content width with the gutter.
class SafeZonePage extends StatelessWidget {
  const SafeZonePage({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: space.maxContentWidth),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.symmetric(
            horizontal: space.gutter,
            vertical: space.md,
          ),
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: space.lg),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
