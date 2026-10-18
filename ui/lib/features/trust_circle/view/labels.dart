import 'package:flutter/material.dart';

import '../../../core/widgets/status_chip.dart';
import '../domain/alert_preferences.dart';
import '../domain/check_in.dart';
import '../domain/sos.dart';
import '../domain/trust_contact.dart';

/// Spanish wording, icon and tone of each domain value. Kept in the view layer
/// so `domain/` stays free of copy and Flutter types.

({String label, IconData icon, StatusTone tone}) contactStatusStyle(
  ContactStatus status,
) => switch (status) {
  ContactStatus.invited => (
    label: 'Invitación pendiente',
    icon: Icons.hourglass_empty,
    tone: StatusTone.caution,
  ),
  ContactStatus.active => (
    label: 'Activo',
    icon: Icons.check_circle_outline,
    tone: StatusTone.accent,
  ),
  ContactStatus.paused => (
    label: 'En pausa',
    icon: Icons.pause_circle_outline,
    tone: StatusTone.neutral,
  ),
};

({String label, IconData icon, StatusTone tone}) checkInStatusStyle(
  CheckInStatus? status,
) => switch (status) {
  null => (
    label: 'Sin ventana activa',
    icon: Icons.radio_button_unchecked,
    tone: StatusTone.neutral,
  ),
  CheckInStatus.waiting => (
    label: 'Esperando confirmación',
    icon: Icons.schedule,
    tone: StatusTone.caution,
  ),
  CheckInStatus.confirmed => (
    label: 'Llegada confirmada',
    icon: Icons.check_circle_outline,
    tone: StatusTone.accent,
  ),
  CheckInStatus.overdue => (
    label: 'Ventana vencida',
    icon: Icons.error_outline,
    tone: StatusTone.alert,
  ),
};

String alertChannelLabel(AlertChannel channel) => switch (channel) {
  AlertChannel.push => 'Notificación push',
  AlertChannel.sms => 'SMS',
  AlertChannel.whatsapp => 'WhatsApp',
};

String alertChoiceLabel(AlertChannelChoice choice) => switch (choice) {
  AlertChannelChoice.sms => 'SMS',
  AlertChannelChoice.whatsapp => 'WhatsApp',
};

String alertEventTitle(AlertEventKind kind) => switch (kind) {
  AlertEventKind.voiceCloneDetected => 'Voz clonada detectada',
  AlertEventKind.paymentHold => 'Pago retenido',
  AlertEventKind.refugeActivated => 'Refugio activado',
};

String alertEventDescription(AlertEventKind kind) => switch (kind) {
  AlertEventKind.voiceCloneDetected =>
    'Cuando EchoTrap marque una llamada como posible voz clonada.',
  AlertEventKind.paymentHold =>
    'Cuando Guardian Pay retenga un pago a la espera de tu verificación.',
  AlertEventKind.refugeActivated =>
    'Cuando se active el Refugio en tu teléfono.',
};

String sosDurationLabel(SosDuration duration) => switch (duration) {
  SosDuration.min15 => '15 minutos',
  SosDuration.min30 => '30 minutos',
  SosDuration.hour1 => '1 hora',
  SosDuration.hour2 => '2 horas',
};

String checkInWindowLabel(CheckInWindow window) => switch (window) {
  CheckInWindow.min30 => '30 minutos',
  CheckInWindow.hour1 => '1 hora',
  CheckInWindow.hour2 => '2 horas',
  CheckInWindow.hour4 => '4 horas',
};

/// `HH:mm` of [time] in the device's local zone.
String clockTime(DateTime time) {
  final local = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

/// "hace 10 min", "hace 2 h" or "hace un momento".
String elapsedLabel(Duration elapsed) {
  if (elapsed.inMinutes < 1) return 'hace un momento';
  if (elapsed.inMinutes < 60) return 'hace ${elapsed.inMinutes} min';
  if (elapsed.inHours < 24) return 'hace ${elapsed.inHours} h';
  return 'hace ${elapsed.inDays} d';
}
