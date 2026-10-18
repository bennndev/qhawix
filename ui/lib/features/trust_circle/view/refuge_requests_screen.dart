import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../domain/action_result.dart';
import '../domain/clock.dart';
import '../domain/refuge_request.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'labels.dart';
import 'refuge_verification_screen.dart';
import 'trust_circle_scaffold.dart';

/// Contacts who ask to activate the person's Refuge. Approving goes through
/// the verification step; denying is always one tap away.
class RefugeRequestsScreen extends StatefulWidget {
  const RefugeRequestsScreen({super.key});

  @override
  State<RefugeRequestsScreen> createState() => _RefugeRequestsScreenState();
}

class _RefugeRequestsScreenState extends State<RefugeRequestsScreen> {
  ActionResult? _result;

  Future<void> _deny(TrustCircleViewModel vm, RefugeRequest request) async {
    final result = await vm.resolveRefugeRequest(request.id, approve: false);
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrustCircleViewModel>();
    final clock = context.read<Clock>();
    final requests = vm.pendingRequests;
    return TrustCircleScaffold(
      title: 'Solicitudes de Refugio',
      children: [
        const PageHeader(
          title: 'Solicitudes de tus contactos',
          subtitle:
              'Nadie activa tu Refugio por su cuenta: tú verificas y decides.',
        ),
        if (_result != null) ActionResultBanner(result: _result!),
        if (requests.isEmpty)
          const EmptyState(
            icon: Icons.shield_outlined,
            title: 'Sin solicitudes pendientes',
            message:
                'Cuando un contacto con permiso pida activar tu Refugio, '
                'aparecerá aquí.',
          )
        else
          for (final request in requests)
            _RequestCard(
              name: vm.contactById(request.contactId)?.name ?? 'Un contacto',
              ago: elapsedLabel(clock.now().difference(request.requestedAt)),
              onApprove: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RefugeVerificationScreen(requestId: request.id),
                ),
              ),
              onDeny: () => _deny(vm, request),
            ),
        const StatusBanner(
          message:
              'Aprobar activa tu Refugio en este teléfono. Puedes rechazar '
              'cualquier solicitud sin dar explicaciones.',
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.name,
    required this.ago,
    required this.onApprove,
    required this.onDeny,
  });

  final String name;
  final String ago;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return SectionCard(
      title: '$name pide activar tu Refugio',
      children: [
        Text(
          'Solicitud $ago.',
          style: context.text.bodySmall?.copyWith(
            color: context.qColors.onSurfaceMuted,
          ),
        ),
        SizedBox(height: space.md),
        PrimaryButton(
          label: 'Verificar y aprobar',
          icon: Icons.verified_user_outlined,
          onPressed: onApprove,
        ),
        SizedBox(height: space.sm),
        SecondaryButton(label: 'Rechazar solicitud', onPressed: onDeny),
      ],
    );
  }
}
