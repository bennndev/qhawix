import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/models/qr_scan_payload.dart';
import '../viewmodel/qr_shield_view_model.dart';

class QrCandidateSelectionScreen extends StatelessWidget {
  const QrCandidateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QrShieldViewModel>();
    final candidates = viewModel.pendingCandidates;
    if (candidates.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Códigos detectados')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/m/qr-shield'),
            style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
            child: const Text('Volver a Escudo QR'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Códigos detectados'),
        leading: IconButton(
          tooltip: 'Cancelar selección',
          icon: const Icon(Icons.close),
          onPressed: () {
            viewModel.clearReview();
            context.go('/m/qr-shield');
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Se detectó más de un QR. Elige cuál quieres revisar; '
                  'ninguno se abrió ni se envió automáticamente.',
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < candidates.length; index++)
                  Card(
                    child: ListTile(
                      minVerticalPadding: 12,
                      leading: CircleAvatar(
                        child: Text((index + 1).toString()),
                      ),
                      title: Text('Código ${index + 1}'),
                      subtitle: Text(
                        _candidateDescription(candidates[index]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine:
                          candidates[index]
                              .inspection
                              .urlAssessment
                              ?.parsedUri !=
                          null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        viewModel.selectCandidate(index);
                        context.go('/m/qr-shield/review');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _candidateDescription(QrCandidateOption candidate) {
  final payload = candidate.inspection.payload;
  if (!payload.isAccepted) {
    return switch (payload.errorCode) {
      'payload_too_large' => 'Contenido supera 8 KiB',
      'empty_payload' => 'Contenido vacío',
      _ => 'Contenido no válido',
    };
  }
  if (payload.kind == QrPayloadKind.url) {
    final assessment = candidate.inspection.urlAssessment;
    return assessment == null || assessment.parsedUri == null
        ? 'Enlace web con estructura pendiente de revisar'
        : 'Enlace web · ${escapeControlCharacters(assessment.host)}\n${assessment.displayValue}';
  }
  return switch (payload.kind) {
    QrPayloadKind.url => 'Enlace web',
    QrPayloadKind.text => 'Texto',
    QrPayloadKind.vCard => 'Contacto',
    QrPayloadKind.calendar => 'Evento o calendario',
    QrPayloadKind.geocoordinates => 'Coordenadas geográficas',
    QrPayloadKind.wifi => 'Datos de red Wi-Fi',
    QrPayloadKind.phone => 'Número de teléfono',
    QrPayloadKind.sms => 'Mensaje SMS',
    QrPayloadKind.email => 'Correo electrónico',
    QrPayloadKind.payment => 'Enlace de pago',
    QrPayloadKind.unsupported => 'Formato no admitido',
  };
}
