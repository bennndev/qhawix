import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../domain/check_in.dart';
import '../viewmodel/family_keyword_view_model.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'add_contact_screen.dart';
import 'alert_preferences_screen.dart';
import 'check_in_screen.dart';
import 'contact_detail_screen.dart';
import 'contact_row.dart';
import 'family_keyword_screen.dart';
import 'labels.dart';
import 'sos_screen.dart';
import 'trust_circle_onboarding_screen.dart';
import 'trust_circle_scaffold.dart';

/// Entry screen of the Red de Confianza module.
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
    if (!vm.setupComplete) {
      return const TrustCircleOnboardingScreen();
    }
    final contacts = vm.contacts;
    return TrustCircleScaffold(
      title: 'Red de Confianza',
      children: [
        SectionCard(
          title: 'Contactos',
          children: [
            if (contacts.isEmpty)
              const EmptyState(
                icon: Icons.group_add_outlined,
                title: 'Sin contactos',
                message: 'Agrega a alguien de confianza desde tu teléfono.',
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
        SectionCard(
          title: 'Más',
          children: [
            ListRow(
              leadingIcon: Icons.sos_outlined,
              title: 'SOS',
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
                  ? 'Creada'
                  : null,
              onTap: () => _open<void>(context, const FamilyKeywordScreen()),
            ),
            ListRow(
              leadingIcon: Icons.notifications_outlined,
              title: 'Preferencias de alertas',
              showDivider: false,
              onTap: () => _open<void>(context, const AlertPreferencesScreen()),
            ),
          ],
        ),
        const StatusBanner(
          message:
              'QHAWIX avisa a tus contactos, pero no garantiza que alguien '
              'responda.',
          kind: StatusBannerKind.caution,
        ),
      ],
    );
  }

  static String? _checkInSummary(TrustCircleViewModel vm) {
    final checkIn = vm.checkIn;
    if (checkIn == null || vm.checkInStatus == CheckInStatus.confirmed) {
      return null;
    }
    return '${checkInStatusStyle(vm.checkInStatus).label} · '
        '${clockTime(checkIn.dueAt)}';
  }
}
