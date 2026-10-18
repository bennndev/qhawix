import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../core/widgets/sheets_dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/toggle_row.dart';
import '../domain/action_result.dart';
import '../domain/trust_contact.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'labels.dart';
import 'trust_circle_scaffold.dart';

/// Permissions, channel order, pause and removal of one contact. Removing pops
/// the screen with the result sentence so the list can show it.
class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  ActionResult? _result;

  Future<void> _run(Future<ActionResult> Function() command) async {
    final result = await command();
    if (!mounted) return;
    setState(() => _result = result);
  }

  Future<void> _remove(TrustCircleViewModel vm, TrustContact contact) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Quitar a ${contact.name}',
      consequence:
          'Dejará de recibir tus avisos y de ver tu ubicación temporal. '
          'Para volver a incluirla tendrás que invitarla de nuevo y ella '
          'tendrá que aceptar. No se puede deshacer.',
      confirmLabel: 'Quitar de mi red',
    );
    if (!confirmed || !mounted) return;
    final result = await vm.removeContact(contact.id);
    if (!mounted) return;
    Navigator.of(context).pop(result.message);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrustCircleViewModel>();
    final contact = vm.contactById(widget.contactId);
    if (contact == null) {
      return const TrustCircleScaffold(
        title: 'Contacto',
        children: [
          EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Este contacto ya no está en tu red',
            message: 'Vuelve a la lista para ver tus contactos.',
          ),
        ],
      );
    }
    final space = context.space;
    final style = contactStatusStyle(contact.status);
    final paused = contact.status == ContactStatus.paused;
    final permissions = contact.permissions;
    return TrustCircleScaffold(
      title: contact.name,
      children: [
        Row(
          children: [
            InitialsAvatar(name: contact.name),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: context.text.headlineSmall),
                  Text(
                    contact.phone,
                    style: context.text.bodySmall?.copyWith(
                      color: context.qColors.onSurfaceMuted,
                    ),
                  ),
                  SizedBox(height: space.xs),
                  StatusChip(
                    label: style.label,
                    icon: style.icon,
                    tone: style.tone,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (contact.status == ContactStatus.invited)
          const StatusBanner(
            message:
                'Aún no aceptó la invitación. No recibe avisos ni ve nada '
                'hasta que acepte.',
            kind: StatusBannerKind.caution,
          ),
        if (paused)
          const StatusBanner(
            message: 'Contacto en pausa: no recibe ningún aviso.',
          ),
        SectionCard(
          title: 'Permisos',
          children: [
            ToggleRow(
              title: 'Recibir mis alertas',
              description: 'Voz clonada, pago retenido y Refugio activado.',
              value: permissions.receiveAlerts,
              onChanged: (v) => _run(
                () => vm.updatePermissions(
                  contact.id,
                  permissions.copyWith(receiveAlerts: v),
                ),
              ),
            ),
            ToggleRow(
              title: 'Puede pedir mi Refugio',
              description:
                  'Solo puede pedirlo: tú verificas y apruebas cada vez.',
              value: permissions.mayRequestRemoteRefuge,
              onChanged: (v) => _run(
                () => vm.updatePermissions(
                  contact.id,
                  permissions.copyWith(mayRequestRemoteRefuge: v),
                ),
              ),
            ),
            ToggleRow(
              title: 'Puede ver mi ubicación temporal',
              description: 'Solo durante un SOS y por el tiempo que elijas.',
              value: permissions.maySeeTemporaryLocation,
              showDivider: false,
              onChanged: (v) => _run(
                () => vm.updatePermissions(
                  contact.id,
                  permissions.copyWith(maySeeTemporaryLocation: v),
                ),
              ),
            ),
          ],
        ),
        SectionCard(
          title: 'Canales de aviso',
          children: [
            Text(
              '1.º ${alertChannelLabel(AlertChannel.push)}. Si no se puede '
              'entregar, 2.º el canal que elijas:',
              style: context.text.bodySmall,
            ),
            SizedBox(height: space.sm),
            SegmentedChoice<AlertChannel>(
              semanticLabel: 'Canal de respaldo',
              selected: contact.fallbackChannel,
              options: const [
                SegmentOption(value: AlertChannel.sms, label: 'SMS'),
                SegmentOption(value: AlertChannel.whatsapp, label: 'WhatsApp'),
              ],
              onChanged: (c) =>
                  _run(() => vm.setContactFallback(contact.id, c)),
            ),
            SizedBox(height: space.sm),
            Text(
              'La entrega depende de que la persona tenga la app o un '
              'número que funcione.',
              style: context.text.bodySmall?.copyWith(
                color: context.qColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
        if (_result != null) ActionResultBanner(result: _result!),
        SecondaryButton(
          label: paused ? 'Reanudar contacto' : 'Pausar contacto',
          icon: paused ? Icons.play_arrow_outlined : Icons.pause_outlined,
          onPressed: () =>
              _run(() => vm.setContactPaused(contact.id, paused: !paused)),
        ),
        SecondaryButton(
          label: 'Quitar de mi red',
          icon: Icons.person_remove_outlined,
          onPressed: () => _remove(vm, contact),
        ),
      ],
    );
  }
}
