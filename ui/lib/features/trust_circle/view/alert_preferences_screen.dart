import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/toggle_row.dart';
import '../domain/action_result.dart';
import '../domain/alert_preferences.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'labels.dart';
import 'trust_circle_scaffold.dart';

/// Which event notifies whom, and the channel used when push cannot be
/// delivered. States the delivery limit up front.
class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({super.key});

  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  ActionResult? _result;

  Future<void> _run(Future<ActionResult> Function() command) async {
    final result = await command();
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrustCircleViewModel>();
    final prefs = vm.alertPreferences;
    final reachable = vm.reachableContacts;
    return TrustCircleScaffold(
      title: 'Preferencias de alertas',
      children: [
        const PageHeader(
          title: 'A quién avisar',
          subtitle: 'Elige qué evento avisa a cada persona de tu red.',
        ),
        const StatusBanner(
          message:
              'La entrega depende de que tu contacto tenga la app o un número '
              'que funcione, y de que tú envíes los mensajes SMS o WhatsApp. '
              'QHAWIX no puede garantizar que alguien lea el aviso.',
          kind: StatusBannerKind.caution,
        ),
        for (final kind in const [
          AlertEventKind.voiceCloneDetected,
        ])
          SectionCard(
            title: alertEventTitle(kind),
            children: [
              Text(
                alertEventDescription(kind),
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
              if (reachable.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.space.sm),
                  child: Text(
                    'Aún no tienes contactos activos que reciban alertas.',
                    style: context.text.bodySmall,
                  ),
                )
              else
                for (var i = 0; i < reachable.length; i++)
                  ToggleRow(
                    title: reachable[i].name,
                    description: reachable[i].hasApp
                        ? null
                        : 'Sin la app: SMS o WhatsApp que envías tú desde tu '
                              'teléfono.',
                    value: prefs.recipientsOf(kind).contains(reachable[i].id),
                    showDivider: i < reachable.length - 1,
                    onChanged: (on) {
                      final ids = {...prefs.recipientsOf(kind)};
                      on
                          ? ids.add(reachable[i].id)
                          : ids.remove(reachable[i].id);
                      _run(() => vm.setAlertRecipients(kind, ids));
                    },
                  ),
            ],
          ),
        SectionCard(
          title: 'Si la notificación push no llega',
          children: [
            Text(
              'Para quien tiene la app, primero va una notificación push. Si '
              'no se puede entregar, se usa este canal. Quien no tiene la app '
              'usa siempre el canal de su ficha.',
              style: context.text.bodySmall,
            ),
            SizedBox(height: context.space.sm),
            SegmentedChoice<AlertChannelChoice>(
              semanticLabel: 'Canal de respaldo',
              selected: prefs.fallbackChannel,
              options: [
                for (final c in AlertChannelChoice.values)
                  SegmentOption(value: c, label: alertChoiceLabel(c)),
              ],
              onChanged: (c) => _run(() => vm.setAlertFallback(c)),
            ),
          ],
        ),
        if (_result != null) ActionResultBanner(result: _result!),
      ],
    );
  }
}
