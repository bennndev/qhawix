import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/status_banner.dart';
import '../domain/action_result.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'trust_circle_scaffold.dart';

/// Placeholder for the person's biometric or PIN check before approving a
/// remote Refuge request. It says plainly that the real verification is not
/// there yet; the approval below is example data only.
class RefugeVerificationScreen extends StatefulWidget {
  const RefugeVerificationScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<RefugeVerificationScreen> createState() =>
      _RefugeVerificationScreenState();
}

class _RefugeVerificationScreenState extends State<RefugeVerificationScreen> {
  ActionResult? _result;
  bool _working = false;

  Future<void> _approve(TrustCircleViewModel vm) async {
    setState(() => _working = true);
    final result = await vm.resolveRefugeRequest(
      widget.requestId,
      approve: true,
    );
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = result;
    });
  }

  Future<void> _deny(TrustCircleViewModel vm) async {
    final result = await vm.resolveRefugeRequest(
      widget.requestId,
      approve: false,
    );
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TrustCircleViewModel>();
    final done = _result != null;
    return TrustCircleScaffold(
      title: 'Verificación',
      children: [
        const PageHeader(
          title: 'Confirma que eres tú',
          subtitle:
              'Antes de activar el Refugio vas a usar tu huella, tu rostro '
              'o tu PIN.',
        ),
        const StatusBanner(
          message:
              'La verificación se agregará aquí. Por ahora este paso no '
              'comprueba quién eres.',
          kind: StatusBannerKind.unverifiable,
        ),
        Icon(
          Icons.fingerprint,
          size: context.space.iconXl,
          color: context.qColors.onSurfaceMuted,
          semanticLabel: 'Verificación pendiente de agregar',
        ),
        if (_result != null) ActionResultBanner(result: _result!),
        if (done)
          PrimaryButton(
            label: 'Listo',
            onPressed: () => Navigator.of(context).pop(),
          )
        else ...[
          PrimaryButton(
            label: 'Aprobar (ejemplo)',
            loading: _working,
            onPressed: () => _approve(vm),
          ),
          SecondaryButton(
            label: 'Rechazar solicitud',
            onPressed: () => _deny(vm),
          ),
          TertiaryButton(
            label: 'Volver',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }
}
