import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/key_value_row.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/qhawix_inputs.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_status.dart';
import '../viewmodel/safe_zone_setup_view_model.dart';
import 'safe_zone_common.dart';
import 'safe_zone_labels.dart';

/// Body of each wizard step. They read the setup view model and never talk to
/// the platform themselves.

/// What is still needed to leave the step, as plain information.
class _Needs extends StatelessWidget {
  const _Needs({required this.step});

  final SetupStep step;

  @override
  Widget build(BuildContext context) {
    final issues = context.watch<SafeZoneSetupViewModel>().issuesFor(step);
    if (issues.isEmpty) return const SizedBox.shrink();
    return StatusBanner(
      message: [for (final i in issues) SafeZoneLabels.issue(i)].join(' '),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Padding(
      padding: EdgeInsets.only(bottom: space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: space.xs),
            child: Icon(
              Icons.circle,
              size: space.sm,
              color: context.qColors.accent,
            ),
          ),
          SizedBox(width: space.md),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child, this.note});

  final String label;
  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(label, style: context.text.labelMedium),
        ),
        SizedBox(height: space.sm),
        child,
        if (note != null) ...[
          SizedBox(height: space.sm),
          Text(
            note!,
            style: context.text.bodySmall?.copyWith(
              color: context.qColors.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}

// -- 1. What it does ---------------------------------------------------------

class IntroStep extends StatelessWidget {
  const IntroStep({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeader(
        title: 'Zona segura',
        subtitle:
            'Si te alejas de casa a deshora, enviamos un SMS a tu red. '
            'Todo queda en este teléfono.',
      ),
      SizedBox(height: context.space.lg),
      const _Bullet('Puede tardar unos minutos en detectar la salida.'),
      const _Bullet('Hace falta saldo SMS y no forzar el cierre de la app.'),
    ],
  );
}

// -- 2. Name and recipients --------------------------------------------------

class RecipientsStep extends StatefulWidget {
  const RecipientsStep({super.key});

  @override
  State<RecipientsStep> createState() => _RecipientsStepState();
}

class _RecipientsStepState extends State<RecipientsStep> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<SafeZoneSetupViewModel>().ownerName,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SafeZoneSetupViewModel>().refreshRecipients();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Quién recibe el aviso',
          subtitle: 'Elige personas de tu Red de Confianza.',
        ),
        SizedBox(height: space.lg),
        QhawixTextField(
          label: 'Tu nombre',
          controller: _name,
          onChanged: vm.setOwnerName,
        ),
        SizedBox(height: space.lg),
        Semantics(
          header: true,
          child: Text('Destinatarios', style: context.text.labelMedium),
        ),
        SizedBox(height: space.sm),
        if (vm.availableRecipients.isEmpty)
          const EmptyState(
            icon: Icons.group_outlined,
            title: 'Sin contactos',
            message: 'Agrégalos en la pestaña Red y vuelve aquí.',
          )
        else
          for (final r in vm.availableRecipients)
            CheckboxListTile(
              value: vm.selectedPhones.contains(r.phone),
              onChanged: (_) => vm.toggleRecipient(r.phone),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(r.name, style: context.text.bodyMedium),
              subtitle: Text(
                r.phone,
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
            ),
        SizedBox(height: space.md),
        const _Needs(step: SetupStep.recipients),
      ],
    );
  }
}

// -- 3. Home -----------------------------------------------------------------

class HomeStep extends StatefulWidget {
  const HomeStep({super.key});

  @override
  State<HomeStep> createState() => _HomeStepState();
}

class _HomeStepState extends State<HomeStep> {
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  bool _manual = false;
  String? _manualError;

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final vm = context.read<SafeZoneSetupViewModel>();
    if (!vm.permissions.fineLocation) {
      await runPermissionFlow(context, const [
        PermissionKind.fineLocation,
      ], vm.requestPermission);
      if (!mounted || !vm.permissions.fineLocation) return;
    }
    await vm.useCurrentLocation();
  }

  void _useManual() {
    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.trim().replaceAll(',', '.'));
    final ok =
        lat != null &&
        lng != null &&
        context.read<SafeZoneSetupViewModel>().setHomeManually(lat, lng);
    setState(
      () => _manualError = ok
          ? null
          : 'Escribe una latitud entre -90 y 90 y una longitud entre -180 y 180.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    final home = vm.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Tu casa',
          subtitle:
              'Ponte en casa y usa tu ubicación actual: ese punto será el '
              'centro de la zona.',
        ),
        SizedBox(height: space.lg),
        PrimaryButton(
          label: 'Usar mi ubicación actual',
          icon: Icons.my_location,
          loading: vm.running == SetupCommand.locate,
          onPressed: vm.busy ? null : _locate,
        ),
        SizedBox(height: space.sm),
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: space.iconSm,
              color: context.qColors.onSurfaceMuted,
            ),
            SizedBox(width: space.sm),
            Expanded(
              child: Text(
                'Tu ubicación se queda en este teléfono: no se envía a ningún '
                'servidor.',
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
        if (home != null) ...[
          SizedBox(height: space.lg),
          QhawixCard(
            child: Column(
              children: [
                KeyValueRow(
                  label: 'Latitud',
                  value: home.lat.toStringAsFixed(5),
                ),
                KeyValueRow(
                  label: 'Longitud',
                  value: home.lng.toStringAsFixed(5),
                ),
                if (vm.homeAccuracyMeters != null)
                  KeyValueRow(
                    label: 'Precisión del GPS',
                    value: 'unos ${vm.homeAccuracyMeters!.round()} m',
                  ),
              ],
            ),
          ),
        ],
        SizedBox(height: space.md),
        TertiaryButton(
          label: _manual ? 'Ocultar coordenadas' : 'Escribir coordenadas',
          icon: Icons.edit_location_alt_outlined,
          onPressed: () => setState(() => _manual = !_manual),
        ),
        if (_manual) ...[
          QhawixTextField(
            label: 'Latitud',
            controller: _lat,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          SizedBox(height: space.md),
          QhawixTextField(
            label: 'Longitud',
            controller: _lng,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            errorText: _manualError,
          ),
          SizedBox(height: space.md),
          SecondaryButton(
            label: 'Usar estas coordenadas',
            onPressed: _useManual,
          ),
        ],
        SizedBox(height: space.lg),
        const _Needs(step: SetupStep.home),
      ],
    );
  }
}

// -- 4. Parameters -----------------------------------------------------------

class ParametersStep extends StatelessWidget {
  const ParametersStep({super.key});

  static const _radiusSteps = [100, 200, 300, 500, 1000, 2000, 5000];
  static const _minAwaySteps = [0, 5, 10, 15, 30, 60];

  static List<int> _withCurrent(List<int> steps, int current) =>
      steps.contains(current) ? steps : ([...steps, current]..sort());

  Future<void> _pick(
    BuildContext context,
    int currentMinute,
    ValueChanged<int> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinute ~/ 60,
        minute: currentMinute % 60,
      ),
    );
    if (picked != null) onPicked(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    final inWindowMode = vm.mode == AlertMode.awayDuringWindow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Cuándo avisar',
          subtitle: 'Tú decides la distancia, la hora y cuánto tiempo fuera.',
        ),
        SizedBox(height: space.lg),
        _Labeled(
          label: 'Distancia desde casa',
          note:
              'El GPS puede tener errores de decenas de metros, por eso el '
              'mínimo es 100 m: con menos habría falsas alarmas.',
          child: SegmentedChoice<int>(
            semanticLabel: 'Distancia desde casa',
            options: [
              for (final m in _withCurrent(_radiusSteps, vm.radiusMeters))
                SegmentOption(value: m, label: SafeZoneLabels.distance(m)),
            ],
            selected: vm.radiusMeters,
            onChanged: vm.setRadius,
          ),
        ),
        SizedBox(height: space.lg),
        _Labeled(
          label: 'Cuándo se considera una anomalía',
          child: SegmentedChoice<AlertMode>(
            semanticLabel: 'Modo de alerta',
            options: [
              for (final m in AlertMode.values)
                SegmentOption(value: m, label: SafeZoneLabels.mode(m)),
            ],
            selected: vm.mode,
            onChanged: vm.setMode,
          ),
        ),
        SizedBox(height: space.sm),
        for (final m in AlertMode.values)
          Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${SafeZoneLabels.mode(m)}. ',
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.qColors.onSurfaceStrong,
                    ),
                  ),
                  TextSpan(
                    text: SafeZoneLabels.modeExplanation(m),
                    style: context.text.bodySmall?.copyWith(
                      color: context.qColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (inWindowMode) ...[
          SizedBox(height: space.md),
          _Labeled(
            label: 'Horario de alerta',
            note: vm.window.crossesMidnight
                ? 'El horario cruza la medianoche.'
                : null,
            child: Column(
              children: [
                _TimeRow(
                  label: 'Desde',
                  minute: vm.window.startMinute,
                  onTap: () =>
                      _pick(context, vm.window.startMinute, vm.setWindowStart),
                ),
                _TimeRow(
                  label: 'Hasta',
                  minute: vm.window.endMinute,
                  onTap: () =>
                      _pick(context, vm.window.endMinute, vm.setWindowEnd),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: space.lg),
        _Labeled(
          label: 'Minutos mínimos fuera de casa',
          note:
              'Solo se avisa si sigues fuera pasado este tiempo. Evita avisos '
              'por salidas cortas.',
          child: SegmentedChoice<int>(
            semanticLabel: 'Minutos mínimos fuera de casa',
            options: [
              for (final m in _withCurrent(_minAwaySteps, vm.minAwayMinutes))
                SegmentOption(value: m, label: SafeZoneLabels.minutes(m)),
            ],
            selected: vm.minAwayMinutes,
            onChanged: vm.setMinAway,
          ),
        ),
        SizedBox(height: space.lg),
        const _Needs(step: SetupStep.parameters),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minute,
    required this.onTap,
  });

  final String label;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final time = SafeZoneLabels.minuteOfDay(minute);
    return Semantics(
      button: true,
      label: '$label $time',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: space.touchMin),
          child: Row(
            children: [
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              Text(time, style: context.text.titleMedium),
              SizedBox(width: space.sm),
              Icon(
                Icons.schedule,
                size: space.iconMd,
                color: context.qColors.accentDeep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- 5. Sending --------------------------------------------------------------

class SendingStep extends StatefulWidget {
  const SendingStep({super.key});

  @override
  State<SendingStep> createState() => _SendingStepState();
}

class _SendingStepState extends State<SendingStep> {
  static const _countdownSteps = [0, 30, 60, 120];
  static const _limitSteps = [1, 2, 3, 5, 10];

  late final TextEditingController _message = TextEditingController(
    text: context.read<SafeZoneSetupViewModel>().message,
  );
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final vm = context.read<SafeZoneSetupViewModel>();
    await vm.savePin(_pin.text, _pinConfirm.text);
    if (vm.pinSet) {
      _pin.clear();
      _pinConfirm.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    final owner = vm.ownerName.trim();
    final preview =
        '${vm.message.trim()}${SafeZoneConfig.autoSuffix(owner.isEmpty ? '…' : owner)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Cómo se envía',
          subtitle:
              'Puedes dar unos segundos para cancelar antes de que salga el '
              'SMS.',
        ),
        SizedBox(height: space.lg),
        _Labeled(
          label: 'Cuenta regresiva',
          note:
              'Verás una notificación neutra con un botón para cancelar con '
              'tu PIN. Si no cancelas, el SMS se envía.',
          child: SegmentedChoice<int>(
            semanticLabel: 'Cuenta regresiva',
            options: [
              for (final s
                  in _countdownSteps.contains(vm.countdownSeconds)
                      ? _countdownSteps
                      : ([..._countdownSteps, vm.countdownSeconds]..sort()))
                SegmentOption(value: s, label: SafeZoneLabels.countdown(s)),
            ],
            selected: vm.countdownSeconds,
            onChanged: vm.setCountdown,
          ),
        ),
        if (vm.countdownSeconds > 0) ...[
          SizedBox(height: space.lg),
          Wrap(
            spacing: space.sm,
            runSpacing: space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('PIN para cancelar', style: context.text.labelMedium),
              if (vm.pinSet)
                const StatusChip(
                  label: 'PIN guardado',
                  icon: Icons.check_circle_outline,
                  tone: StatusTone.accent,
                ),
            ],
          ),
          SizedBox(height: space.sm),
          QhawixTextField(
            label: vm.pinSet ? 'Nuevo PIN (opcional)' : 'PIN (4 a 8 dígitos)',
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            helperText: 'Se guarda solo en este teléfono, cifrado.',
          ),
          SizedBox(height: space.md),
          QhawixTextField(
            label: 'Repite el PIN',
            controller: _pinConfirm,
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: space.md),
          SecondaryButton(
            label: vm.pinSet ? 'Cambiar PIN' : 'Guardar PIN',
            icon: Icons.pin_outlined,
            onPressed: vm.busy ? null : _savePin,
          ),
        ],
        SizedBox(height: space.lg),
        _Labeled(
          label: 'Límite diario',
          note: 'Máximo de salidas que avisan por día. Las demás no envían.',
          child: SegmentedChoice<int>(
            semanticLabel: 'Límite diario de alertas',
            options: [
              for (final l
                  in _limitSteps.contains(vm.dailyLimit)
                      ? _limitSteps
                      : ([..._limitSteps, vm.dailyLimit]..sort()))
                SegmentOption(value: l, label: '$l'),
            ],
            selected: vm.dailyLimit,
            onChanged: vm.setDailyLimit,
          ),
        ),
        SizedBox(height: space.lg),
        _Labeled(
          label: 'Mensaje',
          child: TextField(
            controller: _message,
            onChanged: vm.setMessage,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 6,
            maxLength: SafeZoneLimits.messageMax,
            style: context.text.bodyMedium?.copyWith(
              color: context.qColors.onSurfaceStrong,
            ),
            decoration: const InputDecoration(
              helperText: 'Se guarda solo en este teléfono.',
              helperMaxLines: 2,
            ),
          ),
        ),
        SizedBox(height: space.md),
        _Labeled(
          label: 'Así lo leerán',
          note:
              'El final lo agrega QHAWIX siempre y no se puede quitar, para '
              'que se sepa que es un mensaje automático.',
          child: QhawixCard(
            semanticLabel: 'Vista previa del SMS: $preview',
            child: ExcludeSemantics(
              child: Text(preview, style: context.text.bodyMedium),
            ),
          ),
        ),
        SizedBox(height: space.lg),
        const _Needs(step: SetupStep.sending),
      ],
    );
  }
}

// -- 6. Permissions ----------------------------------------------------------

class PermissionsStep extends StatelessWidget {
  const PermissionsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    final perms = vm.permissions;
    final pending = perms.missingAll;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Permisos',
          subtitle: 'Solo pedimos lo necesario para vigilar y avisar.',
        ),
        SizedBox(height: space.lg),
        for (final kind in PermissionKind.values)
          _PermissionRow(
            kind: kind,
            granted: perms.isGranted(kind),
            required:
                kind != PermissionKind.batteryOptimization &&
                (kind != PermissionKind.notifications ||
                    vm.countdownSeconds > 0),
            busy: vm.busy,
            onFix: () =>
                runPermissionFlow(context, [kind], vm.requestPermission),
          ),
        SizedBox(height: space.md),
        if (pending.isNotEmpty)
          SecondaryButton(
            label: 'Revisar permisos pendientes',
            icon: Icons.verified_user_outlined,
            onPressed: vm.busy
                ? null
                : () =>
                      runPermissionFlow(context, pending, vm.requestPermission),
          )
        else
          const StatusBanner(message: 'Todos los permisos están concedidos.'),
        if (vm.status != null && !vm.status!.playServicesAvailable) ...[
          SizedBox(height: space.md),
          const StatusBanner(
            kind: StatusBannerKind.caution,
            message:
                'Este teléfono no tiene servicios de Google Play, que se '
                'necesitan para vigilar la zona de casa.',
          ),
        ],
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.kind,
    required this.granted,
    required this.required,
    required this.busy,
    required this.onFix,
  });

  final PermissionKind kind;
  final bool granted;
  final bool required;
  final bool busy;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Padding(
      padding: EdgeInsets.only(bottom: space.md),
      child: QhawixCard(
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
                  style: context.text.titleMedium,
                ),
                StatusChip(
                  label: granted ? 'Concedido' : 'Falta',
                  icon: granted
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  tone: granted ? StatusTone.accent : StatusTone.caution,
                ),
              ],
            ),
            SizedBox(height: space.xs),
            Text(
              required ? 'Obligatorio' : 'Recomendado',
              style: context.text.bodySmall?.copyWith(
                color: context.qColors.onSurfaceMuted,
              ),
            ),
            if (!granted)
              TertiaryButton(
                label: SafeZoneLabels.permissionFix(kind),
                onPressed: busy ? null : onFix,
              ),
          ],
        ),
      ),
    );
  }
}

// -- 7. Auto-start (OEM) -----------------------------------------------------

class AutoStartStep extends StatelessWidget {
  const AutoStartStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Inicio automático',
          subtitle:
              'Sin esto, el SMS puede no salir con la app cerrada. Actívalo '
              'en el teléfono y confirma aquí.',
        ),
        SizedBox(height: space.lg),
        QhawixCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('En este teléfono (Honor)', style: context.text.titleMedium),
              SizedBox(height: space.sm),
              Text(
                'Ajustes → Apps → Inicio de apps → QHAWIX → gestión manual: '
                'Inicio automático, Inicio secundario y Segundo plano.',
                style: context.text.bodyMedium,
              ),
              SizedBox(height: space.md),
              Text(
                'Otras marcas: busca “Inicio automático” o “Sin restricciones '
                'de batería” para QHAWIX.',
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: space.lg),
        PrimaryButton(
          label: 'Ya lo activé en este teléfono',
          loading: vm.busy,
          onPressed: vm.busy ? () {} : vm.confirmAutoStart,
        ),
        if (vm.note != null) ...[
          SizedBox(height: space.md),
          StatusBanner(message: vm.note!.message),
        ],
      ],
    );
  }
}

// -- 8. Review ---------------------------------------------------------------

class ReviewStep extends StatefulWidget {
  const ReviewStep({super.key, required this.onSendTest});

  /// Asks for the real-SMS confirmation and runs the test.
  final VoidCallback onSendTest;

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SafeZoneSetupViewModel>().refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    final home = vm.home;
    final missing = vm.missingRequired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Revisa y empieza',
          subtitle: 'Una prueba de SMS y listo.',
        ),
        SizedBox(height: space.lg),
        QhawixCard(
          child: Column(
            children: [
              KeyValueRow(label: 'Tu nombre', value: vm.ownerName.trim()),
              KeyValueRow(
                label: 'Destinatarios',
                value: [
                  for (final r in vm.selectedRecipients) r.name,
                ].join(', '),
              ),
              KeyValueRow(
                label: 'Casa',
                value: home == null
                    ? 'Sin definir'
                    : '${home.lat.toStringAsFixed(4)}, ${home.lng.toStringAsFixed(4)}',
              ),
              KeyValueRow(
                label: 'Distancia',
                value: SafeZoneLabels.distance(vm.radiusMeters),
              ),
              KeyValueRow(label: 'Modo', value: SafeZoneLabels.mode(vm.mode)),
              if (vm.mode == AlertMode.awayDuringWindow)
                KeyValueRow(
                  label: 'Horario',
                  value: SafeZoneLabels.window(vm.window),
                ),
              KeyValueRow(
                label: 'Minutos fuera',
                value: SafeZoneLabels.minutes(vm.minAwayMinutes),
              ),
              KeyValueRow(
                label: 'Cuenta regresiva',
                value: SafeZoneLabels.countdownLong(vm.countdownSeconds),
              ),
              KeyValueRow(label: 'Límite diario', value: '${vm.dailyLimit}'),
            ],
          ),
        ),
        SizedBox(height: space.lg),
        if (missing.isNotEmpty)
          StatusBanner(
            kind: StatusBannerKind.caution,
            message:
                'No se puede iniciar: faltan permisos obligatorios '
                '(${[for (final k in missing) SafeZoneLabels.permission(k)].join(', ')}). '
                'Vuelve al paso de permisos.',
            actionLabel: 'Ir a permisos',
            onAction: () => vm.goTo(SetupStep.permissions),
          ),
        if (!vm.autoStartConfirmed) ...[
          SizedBox(height: space.md),
          StatusBanner(
            kind: StatusBannerKind.caution,
            message: 'Confirma el inicio automático antes de activar.',
            actionLabel: 'Ir a ese paso',
            onAction: () => vm.goTo(SetupStep.autoStart),
          ),
        ],
        if (vm.allIssues.isNotEmpty) ...[
          SizedBox(height: space.md),
          StatusBanner(
            kind: StatusBannerKind.caution,
            message: [
              for (final i in vm.allIssues) SafeZoneLabels.issue(i),
            ].join(' '),
          ),
        ],
        SizedBox(height: space.lg),
        SecondaryButton(
          label: 'Enviar mensaje de prueba',
          icon: Icons.sms_outlined,
          onPressed: vm.busy ? null : widget.onSendTest,
        ),
        if (vm.running == SetupCommand.sendTest)
          Padding(
            padding: EdgeInsets.only(top: space.sm),
            child: const LinearProgressIndicator(),
          ),
        if (vm.testResults.isNotEmpty) ...[
          SizedBox(height: space.md),
          QhawixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resultado de la prueba', style: context.text.titleMedium),
                for (final r in vm.testResults)
                  KeyValueRow(
                    label: _nameFor(vm, r.phone),
                    value: SafeZoneLabels.sendOutcome(r.outcome),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _nameFor(SafeZoneSetupViewModel vm, String phone) {
    for (final r in vm.availableRecipients) {
      if (r.phone == phone) return r.name;
    }
    return phone;
  }
}
