import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/toggle_row.dart';
import '../domain/action_result.dart';
import '../domain/sos.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'labels.dart';
import 'trust_circle_scaffold.dart';

/// Choose recipients and how long the temporary location is shared, consent
/// explicitly and send. "Cancelar" is always visible. The wording never
/// promises an emergency response.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Set<String>? _selected;
  SosDuration _duration = SosDuration.min30;
  bool _consent = false;
  bool _sending = false;
  ActionResult? _result;

  Future<void> _send(TrustCircleViewModel vm, Set<String> ids) async {
    setState(() => _sending = true);
    final result = await vm.sendSos(contactIds: ids, duration: _duration);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrustCircleViewModel>();
    final reachable = vm.reachableContacts;
    final selected = {
      for (final c in reachable)
        if (_selected?.contains(c.id) ?? true) c.id,
    };
    final done = _result != null && !_result!.isRejected;
    final canSend = selected.isNotEmpty && _consent && !done;
    final space = context.space;
    return TrustCircleScaffold(
      title: 'SOS',
      children: [
        const PageHeader(
          title: 'Pedir ayuda a tu red',
          subtitle:
              'Elige a quién avisar y por cuánto tiempo compartir tu ubicación.',
        ),
        const StatusBanner(
          message:
              'QHAWIX avisa a las personas que elijas, pero no garantiza una '
              'respuesta de emergencia. Si estás en peligro, llama también a '
              'los servicios de emergencia. A quien no tiene la app el '
              'mensaje se le prepara en tu teléfono y lo envías tú.',
          kind: StatusBannerKind.caution,
        ),
        SectionCard(
          title: 'A quién avisar',
          children: [
            if (reachable.isEmpty)
              Text(
                'No tienes contactos activos que reciban alertas.',
                style: context.text.bodySmall,
              )
            else
              for (var i = 0; i < reachable.length; i++)
                ToggleRow(
                  title: reachable[i].name,
                  description: recipientCapability(reachable[i]),
                  value: selected.contains(reachable[i].id),
                  showDivider: i < reachable.length - 1,
                  onChanged: done
                      ? null
                      : (on) => setState(() {
                          final next = {...selected};
                          on
                              ? next.add(reachable[i].id)
                              : next.remove(reachable[i].id);
                          _selected = next;
                        }),
                ),
          ],
        ),
        SectionCard(
          title: 'Ubicación temporal',
          children: [
            Text(
              'Con la app, se comparte en vivo solo con quienes tienen ese '
              'permiso y se detiene sola al terminar el tiempo. Por SMS o '
              'WhatsApp va solo la ubicación del momento del envío.',
              style: context.text.bodySmall,
            ),
            SizedBox(height: space.sm),
            SegmentedChoice<SosDuration>(
              semanticLabel: 'Duración de la ubicación',
              selected: _duration,
              options: [
                for (final d in SosDuration.values)
                  SegmentOption(value: d, label: sosDurationLabel(d)),
              ],
              onChanged: done ? null : (d) => setState(() => _duration = d),
            ),
          ],
        ),
        ToggleRow(
          title:
              'Acepto compartir mi ubicación durante '
              '${sosDurationLabel(_duration)}',
          description: 'Solo con las personas elegidas que tienen ese permiso.',
          value: _consent,
          showDivider: false,
          onChanged: done ? null : (v) => setState(() => _consent = v),
        ),
        if (_result != null) ActionResultBanner(result: _result!),
        if (done)
          PrimaryButton(
            label: 'Listo',
            onPressed: () => Navigator.of(context).pop(),
          )
        else
          PrimaryButton(
            label: 'Enviar SOS',
            icon: Icons.sos_outlined,
            loading: _sending,
            onPressed: canSend ? () => _send(vm, selected) : null,
          ),
        if (!done)
          SecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }
}
