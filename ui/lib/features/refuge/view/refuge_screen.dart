import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/key_value_row.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_app_bar.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/sheets_dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/clock.dart';
import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_status.dart';
import '../viewmodel/safe_zone_setup_view_model.dart';
import '../viewmodel/safe_zone_status_view_model.dart';
import 'safe_zone_common.dart';
import 'safe_zone_labels.dart';
import 'safe_zone_onboarding_screen.dart';

/// Entry screen of the Refugio module: the safe-zone hub. Until something is
/// configured, its entry is the onboarding.
class RefugeScreen extends StatelessWidget {
  const RefugeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneStatusViewModel>();
    if (vm.loading) {
      return Scaffold(
        appBar: QhawixAppBar(title: 'Refugio'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (vm.unavailable) {
      return Scaffold(
        appBar: QhawixAppBar(title: 'Refugio'),
        body: const SafeZoneUnavailableView(),
      );
    }
    if (vm.status == null) {
      return Scaffold(
        appBar: QhawixAppBar(title: 'Refugio'),
        body: Padding(
          padding: context.space.screenPadding,
          child: ErrorState(
            message: 'No se pudo leer el estado de las alertas de zona segura.',
            onRetry: vm.refresh,
          ),
        ),
      );
    }
    if (!vm.configured) {
      return SafeZoneOnboardingScreen(onFinished: vm.refresh);
    }
    return ResumeRefresh(onResume: vm.refresh, child: const _Hub());
  }
}

class _Hub extends StatelessWidget {
  const _Hub();

  Future<void> _edit(BuildContext context, SetupStep step) async {
    final vm = context.read<SafeZoneStatusViewModel>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SafeZoneOnboardingScreen(initialStep: step),
      ),
    );
    await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneStatusViewModel>();
    final status = vm.status!;
    final config = vm.config!;
    final clock = context.read<Clock>();
    return Scaffold(
      appBar: QhawixAppBar(title: 'Refugio'),
      body: SafeArea(
        child: SafeZonePage(
          children: [
            const PageHeader(
              title: 'Alertas de zona segura',
              subtitle:
                  'QHAWIX envía un SMS por sí misma cuando estás lejos de casa '
                  'en el horario que elegiste.',
            ),
            if (vm.note != null)
              NoteBanner(note: vm.note!, onDismiss: vm.dismissNote),
            _MonitoringCard(status: status, config: config),
            _HealthCard(vm: vm, status: status, config: config),
            const StatusBanner(message: SafeZoneLabels.limits),
            _ConfigCard(config: config, onEdit: (s) => _edit(context, s)),
            _HistoryCard(vm: vm, now: clock.now()),
            _Actions(vm: vm, config: config),
          ],
        ),
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard({required this.status, required this.config});

  final SafeZoneStatus status;
  final SafeZoneConfig config;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final away = status.awaySince;
    final clock = context.read<Clock>();
    return QhawixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: space.sm,
            runSpacing: space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Monitoreo', style: context.text.titleMedium),
              StatusChip(
                label: status.monitoring ? 'Activo' : 'Detenido',
                icon: status.monitoring
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                tone: status.monitoring
                    ? StatusTone.accent
                    : StatusTone.caution,
              ),
            ],
          ),
          SizedBox(height: space.sm),
          KeyValueRow(
            label: 'Ahora',
            value: away == null
                ? 'En casa o sin salida pendiente'
                : 'Fuera de casa desde ${SafeZoneLabels.when(away, clock.now())}',
          ),
          KeyValueRow(
            label: 'Avisos de hoy',
            value: '${status.sentTodayEpisodes} de ${config.dailyLimit}',
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.vm,
    required this.status,
    required this.config,
  });

  final SafeZoneStatusViewModel vm;
  final SafeZoneStatus status;
  final SafeZoneConfig config;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final perms = status.permissions;
    return QhawixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado de los permisos', style: context.text.titleMedium),
          SizedBox(height: space.sm),
          if (!status.playServicesAvailable)
            Padding(
              padding: EdgeInsets.only(bottom: space.sm),
              child: const StatusBanner(
                kind: StatusBannerKind.error,
                message:
                    'Falta Google Play Services: sin él no se puede vigilar '
                    'la zona de casa.',
              ),
            ),
          for (final kind in PermissionKind.values)
            _HealthRow(
              kind: kind,
              granted: perms.isGranted(kind),
              advice:
                  kind == PermissionKind.batteryOptimization ||
                  (kind == PermissionKind.notifications &&
                      !config.hasCountdown),
              busy: vm.busy,
              onFix: () =>
                  runPermissionFlow(context, [kind], vm.requestPermission),
            ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.kind,
    required this.granted,
    required this.advice,
    required this.busy,
    required this.onFix,
  });

  final PermissionKind kind;
  final bool granted;

  /// Missing is a recommendation, not a blocker.
  final bool advice;
  final bool busy;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: space.sm,
            runSpacing: space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                SafeZoneLabels.permission(kind),
                style: context.text.bodyMedium,
              ),
              StatusChip(
                label: granted
                    ? 'Concedido'
                    : advice
                    ? 'Recomendado'
                    : 'Falta',
                icon: granted
                    ? Icons.check_circle_outline
                    : advice
                    ? Icons.info_outline
                    : Icons.error_outline,
                tone: granted
                    ? StatusTone.accent
                    : advice
                    ? StatusTone.neutral
                    : StatusTone.alert,
              ),
            ],
          ),
          if (!granted)
            TertiaryButton(
              label: SafeZoneLabels.permissionFix(kind),
              onPressed: busy ? null : onFix,
            ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.config, required this.onEdit});

  final SafeZoneConfig config;
  final ValueChanged<SetupStep> onEdit;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return QhawixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuración', style: context.text.titleMedium),
          SizedBox(height: space.sm),
          KeyValueRow(
            label: 'Destinatarios',
            value: [for (final r in config.recipients) r.name].join(', '),
          ),
          TertiaryButton(
            label: 'Editar destinatarios',
            onPressed: () => onEdit(SetupStep.recipients),
          ),
          KeyValueRow(
            label: 'Casa',
            value:
                '${config.home.lat.toStringAsFixed(4)}, '
                '${config.home.lng.toStringAsFixed(4)}',
          ),
          TertiaryButton(
            label: 'Editar casa',
            onPressed: () => onEdit(SetupStep.home),
          ),
          KeyValueRow(
            label: 'Distancia',
            value: SafeZoneLabels.distance(config.radiusMeters),
          ),
          KeyValueRow(label: 'Modo', value: SafeZoneLabels.mode(config.mode)),
          if (config.mode == AlertMode.awayDuringWindow)
            KeyValueRow(
              label: 'Horario',
              value: SafeZoneLabels.window(config.window),
            ),
          KeyValueRow(
            label: 'Minutos fuera',
            value: SafeZoneLabels.minutes(config.minAwayMinutes),
          ),
          TertiaryButton(
            label: 'Editar parámetros',
            onPressed: () => onEdit(SetupStep.parameters),
          ),
          KeyValueRow(
            label: 'Cuenta regresiva',
            value: SafeZoneLabels.countdownLong(config.countdownSeconds),
          ),
          KeyValueRow(label: 'Límite diario', value: '${config.dailyLimit}'),
          TertiaryButton(
            label: 'Editar envío',
            onPressed: () => onEdit(SetupStep.sending),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.vm, required this.now});

  final SafeZoneStatusViewModel vm;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final muted = context.text.bodySmall?.copyWith(
      color: context.qColors.onSurfaceMuted,
    );
    return QhawixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos eventos', style: context.text.titleMedium),
          SizedBox(height: space.sm),
          if (vm.events.isEmpty)
            Text('Todavía no hay eventos.', style: muted)
          else
            for (final e in vm.events.take(10))
              Padding(
                padding: EdgeInsets.symmetric(vertical: space.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      SafeZoneLabels.eventIcon(e.type),
                      size: space.iconMd,
                      color: context.qColors.accentDeep,
                    ),
                    SizedBox(width: space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SafeZoneLabels.eventTitle(e.type),
                            style: context.text.bodyMedium,
                          ),
                          Text(
                            '${SafeZoneLabels.when(e.at, now)}'
                            '${e.test ? ' · prueba' : ''}'
                            '${e.detail == null ? '' : ' · ${e.detail}'}',
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          SizedBox(height: space.sm),
          Text(
            'Muestra los eventos recibidos con la app abierta y el último que '
            'guardó el teléfono.',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.vm, required this.config});

  final SafeZoneStatusViewModel vm;
  final SafeZoneConfig config;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final count = config.recipients.length;
    final busy = vm.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!vm.monitoring)
          PrimaryButton(
            label: 'Reanudar monitoreo',
            icon: Icons.play_arrow,
            loading: vm.running == StatusCommand.resume,
            onPressed: busy ? null : vm.resumeMonitoring,
          ),
        if (!vm.monitoring) SizedBox(height: space.sm),
        SecondaryButton(
          label: 'Enviar mensaje de prueba',
          icon: Icons.sms_outlined,
          onPressed: busy
              ? null
              : () async {
                  if (await confirmRealSms(context, recipientCount: count)) {
                    await vm.sendTestMessage();
                  }
                },
        ),
        if (vm.running == StatusCommand.sendTest)
          Padding(
            padding: EdgeInsets.only(top: space.sm),
            child: const LinearProgressIndicator(),
          ),
        if (vm.testResults.isNotEmpty) ...[
          SizedBox(height: space.sm),
          QhawixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resultado de la prueba', style: context.text.titleMedium),
                for (final r in vm.testResults)
                  KeyValueRow(
                    label: _nameFor(config, r.phone),
                    value: SafeZoneLabels.sendOutcome(r.outcome),
                  ),
                Text(
                  'Entregado a la red del operador no confirma que la persona '
                  'lo haya recibido: pregúntale.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.qColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: space.sm),
        SecondaryButton(
          label: 'Probar el proceso completo',
          icon: Icons.route_outlined,
          onPressed: busy
              ? null
              : () async {
                  if (await confirmEndToEnd(context, recipientCount: count)) {
                    await vm.runEndToEndTest();
                  }
                },
        ),
        if (vm.monitoring) ...[
          SizedBox(height: space.sm),
          SecondaryButton(
            label: 'Detener monitoreo',
            icon: Icons.stop_circle_outlined,
            onPressed: busy
                ? null
                : () async {
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: 'Detener el monitoreo',
                      consequence:
                          'Nadie recibirá un aviso automático si te alejas de '
                          'casa hasta que lo reanudes.',
                      confirmLabel: 'Detener monitoreo',
                    );
                    if (confirmed) await vm.stopMonitoring();
                  },
          ),
        ],
      ],
    );
  }

  static String _nameFor(SafeZoneConfig config, String phone) {
    for (final r in config.recipients) {
      if (r.phone == phone) return r.name;
    }
    return phone;
  }
}
