import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/config/qr_shield_policy.dart';
import '../domain/models/qr_reputation_result.dart';
import '../domain/models/qr_scan_payload.dart';
import '../domain/models/qr_url_assessment.dart';
import '../viewmodel/qr_shield_view_model.dart';

class QrReviewScreen extends StatelessWidget {
  const QrReviewScreen({super.key, this.expectedRevision});

  final int? expectedRevision;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QrShieldViewModel>();
    final review = viewModel.review;
    if (review == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revisión del QR')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/qr'),
            child: const Text('Volver a Escudo QR'),
          ),
        ),
      );
    }

    final payload = review.payload;
    if (expectedRevision != null && review.revision != expectedRevision) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/qr');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión del QR'),
        leading: IconButton(
          tooltip: 'Volver a Escudo QR',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            viewModel.clearReview();
            context.go('/qr');
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!payload.isAccepted)
                  _InvalidPayloadCard(errorCode: payload.errorCode)
                else if (payload.kind == QrPayloadKind.url)
                  _UrlReview(review: review)
                else
                  _StaticContentReview(payload: payload),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    viewModel.clearReview();
                    context.go('/qr');
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Revisar otro código'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
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

class _UrlReview extends StatelessWidget {
  const _UrlReview({required this.review});

  final QrShieldReview review;

  @override
  Widget build(BuildContext context) {
    final assessment = review.urlAssessment!;
    final reputation = review.reputation;
    final isKnownThreat = reputation?.status == QrReputationStatus.knownThreat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerdictCard(reputation: reputation, checking: review.isCheckingReputation),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destino', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(
                  assessment.host.isEmpty ? 'No se pudo extraer el dominio' : assessment.host,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SelectableText(assessment.displayValue),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    assessment.signals.contains(QrUrlSignal.embeddedCredentials)
                        ? 'Mostrar enlace completo (credenciales ocultas)'
                        : 'Mostrar enlace completo (puede incluir datos privados)',
                  ),
                  children: [SelectableText(assessment.fullDisplayValue)],
                ),
                if (assessment.asciiHost != assessment.unicodeHost &&
                    assessment.asciiHost.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Nombre del dominio en Unicode y ASCII (IDNA):'),
                  SelectableText(assessment.unicodeHost),
                  SelectableText(assessment.asciiHost),
                ],
                if (assessment.fragmentOmittedFromReputation) ...[
                  const SizedBox(height: 8),
                  const Text('El fragmento del enlace no se enviaría al proveedor.'),
                ],
              ],
            ),
          ),
        ),
        if (assessment.hasWarnings) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Señales locales', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final signal in assessment.signals)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_signalLabel(signal))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (context.read<QrShieldViewModel>().canRequestReputation &&
            assessment.isEligibleForReputation) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: review.isCheckingReputation ? null : () => _confirmReputationCheck(context),
            icon: const Icon(Icons.cloud_done_outlined),
            label: const Text('Consultar reputación en línea'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
        if (!isKnownThreat && assessment.canOpenExternally) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('open-external-url'),
            onPressed: review.isCheckingReputation ? null : () => _confirmAndOpen(context),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir en navegador externo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ] else if (isKnownThreat)
          const _KnownThreatBlockedCard(),
        const SizedBox(height: 8),
        const Text(
          'El estado de reputación no confirma que el QR pertenezca al negocio '
          'esperado ni garantiza protección frente a sitios nuevos.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _confirmAndOpen(BuildContext context) async {
    final host = review.urlAssessment!.host;
    final warning = _reputationWarning();
    final localSignals = review.urlAssessment!.signals
        .map(_signalLabel)
        .join(' ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Antes de abrir'),
        content: Text(
          'Destino: $host. $warning${localSignals.isEmpty ? '' : ' Señales locales: $localSignals'} Abrirlo puede exponer tus datos. ¿Quieres continuar en el navegador externo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;

    final result = await context
        .read<QrShieldViewModel>()
        .openExternally(userConfirmed: true);
    if (!context.mounted || result == QrOpenResult.opened) return;
    final message = switch (result) {
      QrOpenResult.blockedByKnownThreat => 'Se bloqueó la apertura de una amenaza conocida.',
      QrOpenResult.localPolicyBlocked => 'La política local no permite abrir este destino.',
      QrOpenResult.reputationExpired => 'La revisión venció; vuelve a comprobar el enlace.',
      QrOpenResult.reputationPending => 'Espera a que termine la comprobación antes de abrir el enlace.',
      QrOpenResult.browserUnavailable => 'No se pudo abrir un navegador externo.',
      QrOpenResult.confirmationRequired => 'Confirma la advertencia para continuar.',
      QrOpenResult.notAUrl => 'El contenido no es un enlace web.',
      QrOpenResult.opened => '',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _reputationWarning() {
    final reputation = review.reputation;
    return switch (reputation?.status) {
      QrReputationStatus.knownThreat =>
        'Una fuente reportó una amenaza conocida en este destino.',
      QrReputationStatus.noKnownThreats =>
        'La fuente configurada no reportó coincidencias, pero eso no garantiza que sea seguro.',
      QrReputationStatus.unverifiable =>
        'No se pudo verificar este enlace. Esto no significa que sea seguro.',
      null => 'No se ha verificado la reputación de este enlace.',
    };
  }

  Future<void> _confirmReputationCheck(BuildContext context) async {
    final viewModel = context.read<QrShieldViewModel>();
    final providerName = viewModel.reputationProviderName ?? 'el proveedor configurado';
    final disclosure = viewModel.reputationPrivacyDisclosure ??
        'Revisa las condiciones de privacidad del proveedor antes de enviar el enlace.';
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Consultar reputación'),
        content: Text(
          'Se enviará la URL, sin el fragmento, a $providerName para revisar su reputación. $disclosure ¿Autorizas esta consulta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Solo análisis local'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Autorizar consulta'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    await context.read<QrShieldViewModel>().checkReputation(
          userConsented: consent == true,
        );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.reputation, required this.checking});

  final QrReputationResult? reputation;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final status = reputation?.status;
    final title = checking
        ? 'Comprobando enlace'
        : switch (status) {
            QrReputationStatus.knownThreat => 'Amenaza conocida',
            QrReputationStatus.noKnownThreats => 'Sin amenazas detectadas',
            QrReputationStatus.unverifiable || null => 'No verificable',
          };
    final detail = checking
        ? 'La consulta está en curso.'
        : switch (reputation?.reasonCode) {
            'provider_not_configured' =>
              'La consulta de reputación en línea no está configurada. Esto no significa que el enlace sea seguro.',
            'check_not_requested' =>
              'No se ha consultado un proveedor de reputación. El enlace no está verificado.',
            'reputation_expired' =>
              'La revisión anterior venció y debe repetirse antes de continuar.',
            'redirect_not_resolved' =>
              'La fuente no reportó coincidencias en el acortador, pero QHAWIX no resolvió el destino final. El resultado no es verificable.',
            'local_warning_present' =>
              'La fuente no reportó coincidencias, pero hay señales locales que requieren cautela. El enlace no se considera verificado.',
            'consent_not_granted' =>
              'No se envió el enlace porque no se autorizó la consulta externa.',
            'provider_error' =>
              'La consulta falló. El resultado no puede interpretarse como ausencia de amenazas.',
            _ => switch (status) {
                QrReputationStatus.knownThreat =>
                  'La fuente configurada reportó una coincidencia vigente.',
                QrReputationStatus.noKnownThreats =>
                  'La cobertura configurada no reportó coincidencias vigentes. Esto no garantiza seguridad.',
                _ => 'No se pudo confirmar la reputación del enlace.',
              },
          };
    final icon = checking
        ? Icons.hourglass_top
        : switch (status) {
            QrReputationStatus.knownThreat => Icons.gpp_bad_outlined,
            QrReputationStatus.noKnownThreats => Icons.fact_check_outlined,
            QrReputationStatus.unverifiable || null => Icons.help_outline,
          };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(detail),
                  if (reputation?.provider case final provider?) ...[
                    const SizedBox(height: 8),
                    Text('Fuente: $provider'),
                  ],
                  if (reputation?.checkedAt case final checkedAt?)
                    Text('Consultado: ${checkedAt.toLocal()}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticContentReview extends StatefulWidget {
  const _StaticContentReview({required this.payload});

  final QrScanPayload payload;

  @override
  State<_StaticContentReview> createState() => _StaticContentReviewState();
}

class _StaticContentReviewState extends State<_StaticContentReview> {
  bool _showContent = false;

  @override
  Widget build(BuildContext context) {
    final kind = widget.payload.kind;
    final sensitive = const {
      QrPayloadKind.vCard,
      QrPayloadKind.calendar,
      QrPayloadKind.wifi,
      QrPayloadKind.phone,
      QrPayloadKind.sms,
      QrPayloadKind.email,
      QrPayloadKind.payment,
      QrPayloadKind.coordinates,
    }.contains(kind);
    final content = _showContent
        ? widget.payload.safeDisplayValue
        : sensitive
            ? 'El contenido puede incluir datos personales o credenciales.'
            : widget.payload.safeDisplayValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kindLabel(kind), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Este contenido se muestra de forma estática. QHAWIX no '
                  'llamará, enviará mensajes, conectará redes ni iniciará pagos.',
                ),
                const SizedBox(height: 12),
                SelectableText(content),
                if (sensitive) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _showContent = !_showContent),
                    icon: Icon(_showContent ? Icons.visibility_off : Icons.visibility),
                    label: Text(_showContent ? 'Ocultar contenido' : 'Mostrar contenido'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (kind == QrPayloadKind.unsupported) ...[
          const SizedBox(height: 12),
          const _UnsupportedContentCard(),
        ],
      ],
    );
  }
}

class _InvalidPayloadCard extends StatelessWidget {
  const _InvalidPayloadCard({required this.errorCode});

  final String? errorCode;

  String get _message => switch (errorCode) {
        'payload_too_large' =>
          'No se puede analizar este QR: el contenido supera el límite de ${QrShieldPolicy.maxPayloadBytes ~/ 1024} KiB. No se abrió ni se envió a ningún servicio.',
        'invalid_text_encoding' =>
          'No se puede analizar este QR porque contiene texto malformado. No se abrió ni se envió a ningún servicio.',
        _ => 'No se puede analizar este QR. No se abrió ni se envió a ningún servicio.',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _message,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedContentCard extends StatelessWidget {
  const _UnsupportedContentCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Este formato no se puede ejecutar desde Escudo QR. No se abrirán '
          'apps, archivos, instalaciones ni acciones del sistema.',
        ),
      ),
    );
  }
}

class _KnownThreatBlockedCard extends StatelessWidget {
  const _KnownThreatBlockedCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.block),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Se bloqueó la apertura desde Escudo QR porque una fuente '
                'autorizada reportó este destino.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _kindLabel(QrPayloadKind kind) => switch (kind) {
      QrPayloadKind.url => 'Enlace web',
      QrPayloadKind.text => 'Texto',
      QrPayloadKind.vCard => 'Contacto',
      QrPayloadKind.calendar => 'Evento o calendario',
      QrPayloadKind.wifi => 'Datos de red Wi-Fi',
      QrPayloadKind.phone => 'Número de teléfono',
      QrPayloadKind.sms => 'Mensaje SMS',
      QrPayloadKind.email => 'Correo electrónico',
      QrPayloadKind.payment => 'Enlace de pago',
      QrPayloadKind.coordinates => 'Coordenadas',
      QrPayloadKind.unsupported => 'Formato no admitido',
    };

String _signalLabel(QrUrlSignal signal) => switch (signal) {
      QrUrlSignal.insecureHttp => 'El enlace usa HTTP sin cifrado TLS.',
      QrUrlSignal.punycode => 'El dominio usa una representación punycode; revisa sus caracteres.',
      QrUrlSignal.mixedScripts => 'El dominio mezcla alfabetos en una misma etiqueta.',
      QrUrlSignal.knownShortener => 'Es un acortador conocido; el destino final no se resolvió.',
      QrUrlSignal.unusualPort => 'El enlace usa un puerto distinto al estándar.',
      QrUrlSignal.embeddedCredentials => 'El enlace incluye credenciales antes del dominio.',
      QrUrlSignal.localOrNonPublicHost => 'El destino no es un dominio público verificable.',
      QrUrlSignal.sensitiveQuery => 'El enlace contiene parámetros que parecen secretos.',
      QrUrlSignal.controlCharacters => 'El enlace incluye caracteres de control.',
      QrUrlSignal.unsupportedScheme => 'El esquema del enlace no está admitido.',
      QrUrlSignal.invalidStructure => 'El enlace no tiene una estructura web válida.',
    };
