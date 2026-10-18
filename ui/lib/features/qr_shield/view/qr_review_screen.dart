import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/models/qr_reputation_result.dart';
import '../domain/models/qr_scan_payload.dart';
import '../domain/models/qr_url_assessment.dart';
import '../viewmodel/qr_shield_view_model.dart';

class QrReviewScreen extends StatelessWidget {
  const QrReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QrShieldViewModel>();
    final review = viewModel.review;
    if (review == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revisión del QR')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/m/qr-shield'),
            child: const Text('Volver a Escudo QR'),
          ),
        ),
      );
    }

    final payload = review.payload;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión del QR'),
        leading: IconButton(
          tooltip: 'Volver a Escudo QR',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            viewModel.clearReview();
            context.go('/m/qr-shield');
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
                  _UrlReview(
                    review: review,
                    canOpenExternally: viewModel.canOpenCurrentReview,
                  )
                else
                  _StaticContentReview(
                    payload: payload,
                    revision: review.revision,
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    viewModel.clearReview();
                    context.go('/m/qr-shield');
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

class _UrlReview extends StatefulWidget {
  const _UrlReview({required this.review, required this.canOpenExternally});

  final QrShieldReview review;
  final bool canOpenExternally;

  @override
  State<_UrlReview> createState() => _UrlReviewState();
}

class _UrlReviewState extends State<_UrlReview> {
  bool _showFullUrl = false;
  int? _alertedThreatRevision;

  QrShieldReview get review => widget.review;

  @override
  void didUpdateWidget(covariant _UrlReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.revision != widget.review.revision) {
      _showFullUrl = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    _scheduleThreatAlert();
    final assessment = review.urlAssessment!;
    final reputation = review.reputation;
    final isKnownThreat = reputation?.status == QrReputationStatus.knownThreat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerdictCard(
          reputation: reputation,
          reviewExpiresAt: review.reputationReviewExpiresAt,
          checking: review.isCheckingReputation,
        ),
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
                  assessment.host.isEmpty
                      ? 'No se pudo extraer el dominio'
                      : assessment.host,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SelectableText(assessment.displayValue),
                TextButton.icon(
                  onPressed: () => setState(() => _showFullUrl = !_showFullUrl),
                  icon: Icon(
                    _showFullUrl ? Icons.visibility_off : Icons.visibility,
                  ),
                  label: Text(
                    _showFullUrl
                        ? 'Ocultar URL completa'
                        : 'Mostrar URL completa',
                  ),
                ),
                if (_showFullUrl)
                  SelectableText(
                    escapeControlCharacters(assessment.originalValue),
                  ),
                if (assessment.asciiHost != assessment.unicodeHost &&
                    assessment.asciiHost.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Nombre Unicode y forma ASCII calculada localmente (Punycode):',
                  ),
                  SelectableText(
                    escapeControlCharacters(assessment.unicodeHost),
                  ),
                  SelectableText(assessment.asciiHost),
                ],
                if (assessment.fragmentOmittedFromReputation) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'El fragmento del enlace no se enviaría al proveedor.',
                  ),
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
                  Text(
                    'Señales locales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
            key: const Key('check-url-reputation'),
            onPressed: review.isCheckingReputation
                ? null
                : () => _confirmReputationCheck(context),
            icon: const Icon(Icons.cloud_done_outlined),
            label: const Text('Verificar antes de abrir'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
        if (widget.canOpenExternally &&
            !isKnownThreat &&
            assessment.canOpenExternally) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('open-external-url'),
            onPressed: review.isCheckingReputation
                ? null
                : () => _confirmAndOpen(context),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir en navegador externo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ] else if (isKnownThreat)
          const _KnownThreatBlockedCard(),
        if (!widget.canOpenExternally &&
            !isKnownThreat &&
            !review.isCheckingReputation)
          const _UnverifiedBlockedCard(),
        const SizedBox(height: 8),
        const Text(
          'El estado de reputación no confirma que el QR pertenezca al negocio '
          'esperado ni garantiza protección frente a sitios nuevos.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _scheduleThreatAlert() {
    final currentReview = review;
    final reputation = currentReview.reputation;
    if (currentReview.isCheckingReputation ||
        reputation?.status != QrReputationStatus.knownThreat ||
        _alertedThreatRevision == currentReview.revision) {
      return;
    }

    final revision = currentReview.revision;
    _alertedThreatRevision = revision;
    final categories = reputation!.categories;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.review.revision != revision) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            Icons.gpp_bad_outlined,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Alerta: amenaza conocida'),
          content: Text(
            categories.isEmpty
                ? 'La fuente de reputación reportó este destino como una amenaza. Escudo QR bloqueó su apertura.'
                : 'La fuente de reputación reportó este destino como una amenaza (${categories.join(', ')}). Escudo QR bloqueó su apertura.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmAndOpen(BuildContext context) async {
    final currentReview = review;
    final expectedRevision = currentReview.revision;
    final host = currentReview.urlAssessment!.host;
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

    final result = await context.read<QrShieldViewModel>().openExternally(
      userConfirmed: true,
      expectedRevision: expectedRevision,
    );
    if (!context.mounted || result == QrOpenResult.opened) return;
    final message = switch (result) {
      QrOpenResult.blockedByKnownThreat =>
        'Se bloqueó la apertura de una amenaza conocida.',
      QrOpenResult.blockedByUnverified =>
        'No se abrió el enlace porque no se pudo confirmar que esté libre de amenazas.',
      QrOpenResult.localPolicyBlocked =>
        'La política local no permite abrir este destino.',
      QrOpenResult.reviewChanged =>
        'La revisión cambió. Revisa el QR actual antes de abrirlo.',
      QrOpenResult.reputationPending =>
        'Espera a que termine la consulta de reputación.',
      QrOpenResult.reputationExpired =>
        'La revisión venció; vuelve a comprobar el enlace.',
      QrOpenResult.browserUnavailable =>
        'No se pudo abrir un navegador externo.',
      QrOpenResult.confirmationRequired =>
        'Confirma la advertencia para continuar.',
      QrOpenResult.notAUrl => 'El contenido no es un enlace web.',
      QrOpenResult.opened => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _reputationWarning() {
    final reputation = review.reputation;
    return switch (reputation?.status) {
      QrReputationStatus.knownThreat =>
        'Una fuente reportó una amenaza conocida en este destino.',
      QrReputationStatus.noKnownThreats =>
        'La fuente configurada no reportó coincidencias, pero eso no garantiza que sea seguro.',
      QrReputationStatus.suspiciousOrUnverified =>
        'El enlace tiene señales de riesgo o no se pudo verificar. Esto no significa que sea seguro.',
      null => 'No se ha verificado la reputación de este enlace.',
    };
  }

  Future<void> _confirmReputationCheck(BuildContext context) async {
    final currentReview = review;
    final assessment = currentReview.urlAssessment;
    final urlForProvider = assessment?.reputationUri;
    if (assessment == null || urlForProvider == null) return;

    final viewModel = context.read<QrShieldViewModel>();
    final providerName =
        viewModel.reputationProviderName ?? 'el proveedor configurado';
    final disclosure =
        viewModel.reputationPrivacyDisclosure ??
        'Revisa las condiciones de privacidad del proveedor antes de enviar el enlace.';
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Consultar reputación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta URL exacta se enviará, sin el fragmento, a $providerName para revisar su reputación:',
              ),
              const SizedBox(height: 8),
              SelectableText(urlForProvider.toString()),
              const SizedBox(height: 12),
              Text(disclosure),
              const SizedBox(height: 8),
              const Text(
                'QHAWIX oculta señales de secretos reconocibles, pero no puede '
                'detectar todos los tokens. Revisa el enlace antes de autorizar.',
              ),
              const SizedBox(height: 8),
              const Text('¿Autorizas esta consulta?'),
            ],
          ),
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
      expectedRevision: currentReview.revision,
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.reputation,
    required this.reviewExpiresAt,
    required this.checking,
  });

  final QrReputationResult? reputation;
  final DateTime? reviewExpiresAt;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final reputationResult = reputation;
    final status = reputationResult?.status;
    final title = checking
        ? 'Comprobando enlace'
        : switch (status) {
            QrReputationStatus.knownThreat => 'Amenaza conocida',
            QrReputationStatus.noKnownThreats => 'Sin amenazas detectadas',
            QrReputationStatus.suspiciousOrUnverified ||
            null => 'Sospechoso o no verificable',
          };
    final detail = checking
        ? 'La consulta está en curso.'
        : switch (reputationResult?.reasonCode) {
            'provider_not_configured' =>
              'La consulta de reputación en línea no está configurada. Esto no significa que el enlace sea seguro.',
            'check_not_requested' =>
              'No se ha consultado un proveedor de reputación. El enlace no está verificado.',
            'reputation_expired' =>
              'La revisión anterior venció y debe repetirse antes de continuar.',
            'negative_review_expired' =>
              'La revisión sin coincidencias venció. Vuelve a comprobar este enlace antes de abrirlo.',
            'local_signal' =>
              'La fuente no reportó coincidencias, pero hay señales locales que requieren cautela.',
            'sensitive_path' =>
              'El enlace parece incluir un secreto de autenticación en la ruta y no se enviará ni abrirá.',
            'invalid_provider_response' =>
              'La respuesta no incluyó una cobertura o vigencia válida; no se considera un resultado limpio.',
            'coverage_incomplete' =>
              'La cobertura de la consulta fue incompleta. No se interpreta como ausencia de amenazas.',
            'scope_missing' =>
              'La respuesta no informó qué categorías revisó; no se interpreta como ausencia de amenazas.',
            'provider_timeout' =>
              'La consulta superó el límite de espera. El enlace no está verificado.',
            'offline' =>
              'No hay conexión con el proveedor. El enlace no está verificado.',
            'quota_exceeded' =>
              'El proveedor alcanzó su cuota. El enlace no está verificado.',
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
            QrReputationStatus.suspiciousOrUnverified ||
            null => Icons.help_outline,
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
                  if (reputationResult?.provider case final provider?) ...[
                    const SizedBox(height: 8),
                    Text('Fuente: $provider'),
                  ],
                  if (reputationResult?.checkedAt case final checkedAt?)
                    Text('Consultado: ${checkedAt.toLocal()}'),
                  if (reputationResult?.expiresAt case final expiresAt?)
                    Text(
                      'Vigencia informada por la fuente hasta: ${expiresAt.toLocal()}',
                    ),
                  if (status == QrReputationStatus.noKnownThreats) ...[
                    if (reviewExpiresAt case final reviewExpiry?)
                      Text(
                        'Revisión local disponible hasta: ${reviewExpiry.toLocal()}',
                      ),
                    const Text(
                      'La respuesta sin coincidencias no incluye una vigencia '
                      'del proveedor. Esta revisión local dura como máximo '
                      '60 segundos y no garantiza seguridad.',
                    ),
                  ],
                  if (reputationResult != null)
                    Text('Cobertura: ${_coverageLabel(reputationResult)}'),
                  if (reputationResult != null)
                    Text(
                      'Estado del proveedor: ${_providerStateLabel(reputationResult.providerState)}',
                    ),
                  if (reputationResult != null)
                    Text(
                      'Categorías consultadas: ${reputationResult.checkedCategories.isEmpty ? 'no reportadas' : reputationResult.checkedCategories.join(', ')}',
                    ),
                  if (status == QrReputationStatus.knownThreat &&
                      reputationResult != null &&
                      reputationResult.categories.isNotEmpty)
                    Text(
                      'Categorías reportadas: ${reputationResult.categories.join(', ')}',
                    ),
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
  const _StaticContentReview({required this.payload, required this.revision});

  final QrScanPayload payload;
  final int revision;

  @override
  State<_StaticContentReview> createState() => _StaticContentReviewState();
}

class _StaticContentReviewState extends State<_StaticContentReview> {
  bool _showContent = false;

  @override
  void didUpdateWidget(covariant _StaticContentReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _showContent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.payload.kind;
    final sensitive = widget.payload.mayContainSensitiveContent;
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
                Text(
                  _kindLabel(kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                    onPressed: () =>
                        setState(() => _showContent = !_showContent),
                    icon: Icon(
                      _showContent ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(
                      _showContent ? 'Ocultar contenido' : 'Mostrar contenido',
                    ),
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
                errorCode == 'payload_too_large'
                    ? 'No se puede analizar este QR: el contenido supera el límite de 8 KiB.'
                          ' No se abrió ni se envió a ningún servicio.'
                    : errorCode == 'empty_payload'
                    ? 'El contenido está vacío. Pega o escanea otro código QR.'
                    : 'No se pudo leer el contenido de forma segura. Pega o escanea otro código.',
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
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.gpp_bad_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enlace bloqueado: amenaza conocida',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'La fuente de reputación reportó este destino. No se abrirá en el navegador.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnverifiedBlockedCard extends StatelessWidget {
  const _UnverifiedBlockedCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.block),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enlace bloqueado: no se pudo confirmar que esté libre de amenazas. Verifícalo antes de intentar abrirlo.',
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
  QrPayloadKind.geocoordinates => 'Coordenadas geográficas',
  QrPayloadKind.wifi => 'Datos de red Wi-Fi',
  QrPayloadKind.phone => 'Número de teléfono',
  QrPayloadKind.sms => 'Mensaje SMS',
  QrPayloadKind.email => 'Correo electrónico',
  QrPayloadKind.payment => 'Enlace de pago',
  QrPayloadKind.unsupported => 'Formato no admitido',
};

String _signalLabel(QrUrlSignal signal) => switch (signal) {
  QrUrlSignal.insecureHttp => 'El enlace usa HTTP sin cifrado TLS.',
  QrUrlSignal.punycode =>
    'El dominio usa una representación punycode; revisa sus caracteres.',
  QrUrlSignal.mixedScripts =>
    'El dominio mezcla alfabetos en una misma etiqueta.',
  QrUrlSignal.knownShortener =>
    'Es un acortador conocido; el destino final no se resolvió.',
  QrUrlSignal.identifiableRedirect =>
    'El enlace parece redirigir a otro destino; QHAWIX no siguió esa redirección.',
  QrUrlSignal.fragmentPresent =>
    'El fragmento se conserva solo en el dispositivo y puede contener datos sensibles.',
  QrUrlSignal.unusualPort => 'El enlace usa un puerto distinto al estándar.',
  QrUrlSignal.embeddedCredentials =>
    'El enlace incluye credenciales antes del dominio.',
  QrUrlSignal.localOrNonPublicHost =>
    'El destino no es un dominio público verificable.',
  QrUrlSignal.sensitiveQuery =>
    'El enlace contiene parámetros que parecen secretos.',
  QrUrlSignal.sensitivePath =>
    'La ruta parece contener un secreto de autenticación; se ocultó y no se enviará.',
  QrUrlSignal.controlCharacters => 'El enlace incluye caracteres de control.',
  QrUrlSignal.unsupportedScheme => 'El esquema del enlace no está admitido.',
  QrUrlSignal.invalidStructure =>
    'El enlace no tiene una estructura web válida.',
};

String _coverageLabel(QrReputationResult result) {
  if (result.coverageComplete) return 'completa';
  return result.checkedAt == null ? 'no disponible' : 'incompleta';
}

String _providerStateLabel(QrProviderState state) => switch (state) {
  QrProviderState.notConfigured => 'no configurado',
  QrProviderState.notRequested => 'no consultado',
  QrProviderState.available => 'respuesta recibida',
  QrProviderState.offline => 'sin conexión',
  QrProviderState.timeout => 'tiempo de espera agotado',
  QrProviderState.quotaExceeded => 'cuota agotada',
  QrProviderState.failed => 'falló',
  QrProviderState.invalidResponse => 'respuesta inválida',
};
