import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

/// Spanish text for the time left, so time is never only visual.
String remainingTimeLabel(Duration remaining) {
  if (remaining <= Duration.zero) return 'Ya puedes continuar';
  final minutes = (remaining.inSeconds + 59) ~/ 60;
  if (remaining.inSeconds < 60) return 'Falta menos de un minuto';
  return minutes == 1 ? 'Falta 1 minuto' : 'Faltan $minutes minutos';
}

/// Full-screen pause that covers a wallet app when concealment is active.
///
/// Canvas background, no red, no alarm wording, no padlock imagery and no
/// QHAWIX wordmark, so it does not announce why it appeared. It states that it
/// cannot block a payment inside another app. With reduce motion the thin
/// progress line is omitted and only the text remains.
class WalletGateScreen extends StatelessWidget {
  const WalletGateScreen({
    super.key,
    required this.remaining,
    required this.total,
    required this.onVerify,
    this.onRequestApproval,
    this.title = 'Pausa antes de continuar',
    this.message =
        'Tómate un momento antes de abrir tu billetera. QHAWIX no puede '
        'bloquear un pago dentro de otra app; esta pausa te da tiempo para '
        'verificar con calma.',
  });

  final Duration remaining;
  final Duration total;
  final VoidCallback onVerify;

  /// When null the trusted-contact link is not shown.
  final VoidCallback? onRequestApproval;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final progress = total.inMilliseconds <= 0
        ? 1.0
        : (1 - remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final timeLabel = remainingTimeLabel(remaining);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: SingleChildScrollView(
              padding: space.screenPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium,
                    ),
                  ),
                  SizedBox(height: space.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge,
                  ),
                  SizedBox(height: space.xl),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      timeLabel,
                      textAlign: TextAlign.center,
                      style: context.text.titleSmall,
                    ),
                  ),
                  if (!context.motion.reduced(context)) ...[
                    SizedBox(height: space.sm),
                    ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value: progress,
                        borderRadius: context.shapes.pillRadius,
                      ),
                    ),
                  ],
                  SizedBox(height: space.xl),
                  PrimaryButton(
                    label: 'Verificar con huella o PIN',
                    onPressed: onVerify,
                  ),
                  if (onRequestApproval != null) ...[
                    SizedBox(height: space.sm),
                    TertiaryButton(
                      label: 'Pedir aprobación a un contacto',
                      onPressed: onRequestApproval,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
