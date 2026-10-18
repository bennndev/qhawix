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

/// Permissions, channels, pause and removal of one contact. Removing pops the
/// screen with the result sentence so the list can show it. A contact without
/// the app can be invited to install it, as an optional action.
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
          'Dejará de estar entre las personas a las que avisas y no se le '
          'preparará ningún mensaje ni ubicación. Para volver a incluirla '
          'tendrás que agregarla de nuevo. No se puede deshacer.',
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
    final kind = contactKindStyle(contact.kind);
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
                  Wrap(
                    spacing: space.sm,
                    runSpacing: space.xs,
                    children: [
                      StatusChip(
                        label: kind.label,
                        icon: kind.icon,
                        tone: kind.tone,
                      ),
                      StatusChip(
                        label: style.label,
                        icon: style.icon,
                        tone: style.tone,
                      ),
                      if (contact.installInvitePending)
                        StatusChip(
                          label: installInvitePendingStyle.label,
                          icon: installInvitePendingStyle.icon,
                          tone: installInvitePendingStyle.tone,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (paused)
          const StatusBanner(
            message: 'Contacto en pausa: no se le prepara ningún aviso.',
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
              description: contact.canRequestRemoteRefuge
                  ? 'Solo puede pedirlo: tú verificas y apruebas cada vez.'
                  : 'Necesita la app: sin ella no puede pedirlo.',
              value:
                  contact.canRequestRemoteRefuge &&
                  permissions.mayRequestRemoteRefuge,
              showDivider: contact.hasApp,
              onChanged: contact.canRequestRemoteRefuge
                  ? (v) => _run(
                      () => vm.updatePermissions(
                        contact.id,
                        permissions.copyWith(mayRequestRemoteRefuge: v),
                      ),
                    )
                  : null,
            ),
            if (!contact.hasApp && !contact.installInvitePending)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TertiaryButton(
                  label: 'Invitar a instalar QHAWIX',
                  icon: Icons.install_mobile_outlined,
                  onPressed: () => _run(() => vm.inviteToInstall(contact.id)),
                ),
              ),
            if (!contact.hasApp && contact.installInvitePending)
              Padding(
                padding: EdgeInsets.symmetric(vertical: space.sm),
                child: Text(
                  'Invitación a instalar pendiente.',
                  style: context.text.bodySmall,
                ),
              ),
            if (!contact.hasApp) Divider(color: context.qColors.mist),
            ToggleRow(
              title: contact.hasApp
                  ? 'Puede ver mi ubicación temporal'
                  : 'Incluir mi ubicación en los mensajes de SOS',
              description: contact.hasApp
                  ? 'Solo durante un SOS y por el tiempo que elijas.'
                  : 'Solo la ubicación del momento del envío. '
                        'La ubicación en vivo requiere la app.',
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
              contact.hasApp
                  ? '1.º ${alertChannelLabel(AlertChannel.push)}. Si no se '
                        'puede entregar, 2.º el canal que elijas:'
                  : 'Sin la app, los avisos van por SMS o WhatsApp. Se '
                        'preparan en tu teléfono y los envías tú:',
              style: context.text.bodySmall,
            ),
            SizedBox(height: space.sm),
            SegmentedChoice<AlertChannel>(
              semanticLabel: contact.hasApp ? 'Canal de respaldo' : 'Canal',
              selected: contact.channel,
              options: [
                for (final c in contact.availableChannels)
                  if (c != AlertChannel.push)
                    SegmentOption(value: c, label: alertChannelLabel(c)),
              ],
              onChanged: (c) => _run(() => vm.setContactChannel(contact.id, c)),
            ),
            SizedBox(height: space.sm),
            Text(
              contact.hasApp
                  ? 'La entrega depende de que la persona tenga la app o un '
                        'número que funcione.'
                  : 'QHAWIX no envía estos mensajes desde un servidor: '
                        'depende de que tú los envíes y de que el número '
                        'funcione.',
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
