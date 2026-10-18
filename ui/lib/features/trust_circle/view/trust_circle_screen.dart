import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/summary_panel.dart';
import '../domain/check_in.dart';
import '../domain/trust_contact.dart';
import '../viewmodel/family_keyword_view_model.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'add_contact_screen.dart';
import 'alert_preferences_screen.dart';
import 'check_in_screen.dart';
import 'contact_detail_screen.dart';
import 'contact_row.dart';
import 'family_keyword_screen.dart';
import 'labels.dart';
import 'refuge_requests_screen.dart';
import 'sos_screen.dart';
import 'trust_circle_scaffold.dart';

/// Entry screen of the Red de Confianza module: circle status, contacts and
/// their consent state, quick actions and the requests waiting for the person.
class TrustCircleScreen extends StatelessWidget {
  const TrustCircleScreen({super.key});

  static Future<T?> _open<T>(BuildContext context, Widget screen) =>
      Navigator.of(
        context,
      ).push<T>(MaterialPageRoute<T>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrustCircleViewModel>();
    if (vm.snapshot == null) {
      return TrustCircleScaffold(
        title: 'Red de Confianza',
        children: [
          if (vm.failed)
            ErrorState(
              message: 'No pudimos leer tu red de confianza.',
              onRetry: vm.load,
            )
          else
            const LoadingSkeleton(),
        ],
      );
    }
    final contacts = vm.contacts;
    final active = contacts.where((c) => c.isActive).length;
    final withApp = contacts.where((c) => c.hasApp).length;
    final paused = contacts
        .where((c) => c.status == ContactStatus.paused)
        .length;
    return TrustCircleScaffold(
      title: 'Red de Confianza',
      children: [
        const PageHeader(
          title: 'Tu red de confianza',
          subtitle:
              'Personas que elegiste para avisarles y coordinar contigo. '
              'No necesitan tener la app.',
        ),
        SummaryPanel(
          icon: Icons.group_outlined,
          label: 'Estado del círculo',
          value: '$active de ${contacts.length} activos',
          caption:
              '$withApp con la app · ${contacts.length - withApp} sin la app · '
              '$paused en pausa',
        ),
        if (vm.pendingRequests.isNotEmpty)
          SectionCard(
            title: 'Esperan tu respuesta',
            children: [
              ListRow(
                leadingIcon: Icons.shield_outlined,
                title: vm.pendingRequests.length == 1
                    ? '1 solicitud de Refugio'
                    : '${vm.pendingRequests.length} solicitudes de Refugio',
                subtitle: 'Pendiente: necesitas verificarte para aprobar.',
                showDivider: false,
                onTap: () => _open<void>(context, const RefugeRequestsScreen()),
              ),
            ],
          ),
        SectionCard(
          title: 'Acciones rápidas',
          children: [
            ListRow(
              leadingIcon: Icons.sos_outlined,
              title: 'SOS',
              subtitle: 'Avisa ahora a las personas que elijas.',
              onTap: () => _open<void>(context, const SosScreen()),
            ),
            ListRow(
              leadingIcon: Icons.schedule,
              title: 'Llegada segura',
              subtitle: _checkInSummary(vm),
              onTap: () => _open<void>(context, const CheckInScreen()),
            ),
            ListRow(
              leadingIcon: Icons.key_outlined,
              title: 'Palabra clave familiar',
              subtitle: context.watch<FamilyKeywordViewModel>().hasKeyword
                  ? 'Creada. Solo tú decides cuándo verla.'
                  : 'Aún no la creaste.',
              onTap: () => _open<void>(context, const FamilyKeywordScreen()),
            ),
            ListRow(
              leadingIcon: Icons.notifications_outlined,
              title: 'Preferencias de alertas',
              subtitle: 'Qué evento avisa a quién.',
              showDivider: false,
              onTap: () => _open<void>(context, const AlertPreferencesScreen()),
            ),
          ],
        ),
        SectionCard(
          title: 'Contactos',
          children: [
            if (contacts.isEmpty)
              const EmptyState(
                icon: Icons.group_add_outlined,
                title: 'Aún no tienes contactos',
                message:
                    'Agrega a alguien de confianza con su nombre y su número. '
                    'No necesita tener la app.',
              )
            else
              for (var i = 0; i < contacts.length; i++)
                ContactRow(
                  contact: contacts[i],
                  showDivider: i < contacts.length - 1,
                  onTap: () async {
                    final message = await _open<String>(
                      context,
                      ContactDetailScreen(contactId: contacts[i].id),
                    );
                    if (message != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                ),
          ],
        ),
        PrimaryButton(
          label: 'Agregar contacto',
          icon: Icons.person_add_alt_outlined,
          onPressed: () => _open<void>(context, const AddContactScreen()),
        ),
        const StatusBanner(
          message:
              'QHAWIX avisa a tus contactos, pero no garantiza que alguien '
              'responda ni que llegue una ayuda de emergencia.',
          kind: StatusBannerKind.caution,
        ),
      ],
    );
  }

  static String _checkInSummary(TrustCircleViewModel vm) {
    final style = checkInStatusStyle(vm.checkInStatus);
    final checkIn = vm.checkIn;
    if (checkIn == null || vm.checkInStatus == CheckInStatus.confirmed) {
      return style.label;
    }
    return '${style.label} · vence a las ${clockTime(checkIn.dueAt)}';
  }
}
