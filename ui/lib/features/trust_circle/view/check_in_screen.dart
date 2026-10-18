import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/summary_panel.dart';
import '../domain/action_result.dart';
import '../domain/check_in.dart';
import '../domain/clock.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'labels.dart';
import 'trust_circle_scaffold.dart';

/// Safe arrival: schedule a window, see whether it is waiting, confirmed or
/// overdue, and read what happens when it is overdue.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  CheckInWindow _window = CheckInWindow.hour1;
  ActionResult? _result;
  Timer? _dueTimer;
  DateTime? _timerFor;

  @override
  void dispose() {
    _dueTimer?.cancel();
    super.dispose();
  }

  /// Rebuilds exactly when a waiting window becomes overdue.
  void _scheduleDueRebuild(CheckIn? checkIn, Clock clock) {
    if (checkIn == null || checkIn.statusAt(clock) != CheckInStatus.waiting) {
      _dueTimer?.cancel();
      _timerFor = null;
      return;
    }
    if (_timerFor == checkIn.dueAt) return;
    _dueTimer?.cancel();
    _timerFor = checkIn.dueAt;
    _dueTimer = Timer(checkIn.dueAt.difference(clock.now()), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _run(Future<ActionResult> Function() command) async {
    final result = await command();
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrustCircleViewModel>();
    final clock = context.read<Clock>();
    final checkIn = vm.checkIn;
    final status = vm.checkInStatus;
    _scheduleDueRebuild(checkIn, clock);
    final style = checkInStatusStyle(status);
    final active =
        status == CheckInStatus.waiting || status == CheckInStatus.overdue;
    final recipients = vm.reachableContacts.length;
    final space = context.space;
    return TrustCircleScaffold(
      title: 'Llegada segura',
      children: [
        const PageHeader(
          title: 'Avisa que llegaste bien',
          subtitle: 'Programa una ventana y confirma antes de que termine.',
        ),
        SummaryPanel(
          icon: style.icon,
          label: 'Estado',
          value: style.label,
          caption: checkIn == null || status == CheckInStatus.confirmed
              ? null
              : 'Vence a las ${clockTime(checkIn.dueAt)}',
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusChip(
            label: style.label,
            icon: style.icon,
            tone: style.tone,
          ),
        ),
        if (status == CheckInStatus.overdue)
          const StatusBanner(
            message:
                'La ventana venció. Confirma tu llegada para cerrarla. '
                'En esta demostración no se avisó a nadie.',
            kind: StatusBannerKind.caution,
          ),
        if (!active)
          SectionCard(
            title: 'Programar una ventana',
            children: [
              SegmentedChoice<CheckInWindow>(
                semanticLabel: 'Duración de la ventana',
                selected: _window,
                options: [
                  for (final w in CheckInWindow.values)
                    SegmentOption(value: w, label: checkInWindowLabel(w)),
                ],
                onChanged: (w) => setState(() => _window = w),
              ),
            ],
          ),
        SectionCard(
          title: 'Qué pasa si vence',
          children: [
            Text(
              recipients == 0
                  ? 'Hoy no hay contactos activos que reciban alertas, así '
                        'que no se avisaría a nadie.'
                  : 'Si no confirmas a tiempo, el aviso está pensado para '
                        '$recipients ${recipients == 1 ? 'contacto activo' : 'contactos activos'}.',
              style: context.text.bodySmall,
            ),
            SizedBox(height: space.sm),
            Text(
              'La entrega depende de la app y del número de cada contacto. '
              'No garantiza que alguien responda ni que llegue ayuda.',
              style: context.text.bodySmall?.copyWith(
                color: context.qColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
        if (_result != null) ActionResultBanner(result: _result!),
        if (active) ...[
          PrimaryButton(
            label: 'Confirmar que llegué',
            icon: Icons.check_circle_outline,
            onPressed: () => _run(vm.confirmCheckIn),
          ),
          SecondaryButton(
            label: 'Cancelar ventana',
            onPressed: () => _run(vm.cancelCheckIn),
          ),
        ] else
          PrimaryButton(
            label: 'Iniciar ventana',
            icon: Icons.schedule,
            onPressed: () => _run(() => vm.startCheckIn(_window)),
          ),
      ],
    );
  }
}
