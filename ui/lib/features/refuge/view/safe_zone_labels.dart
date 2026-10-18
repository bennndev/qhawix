import 'package:flutter/material.dart';

import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_status.dart';

/// Spanish copy for domain values. Wording is honest: `sent` is "entregado a
/// la red del operador", never "entregado" to the person.
abstract final class SafeZoneLabels {
  static String minuteOfDay(int minute) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String distance(int meters) => meters >= 1000 && meters % 1000 == 0
      ? '${meters ~/ 1000} km'
      : '$meters m';

  static String countdown(int seconds) =>
      seconds == 0 ? 'Enviar directo' : '$seconds s';

  static String countdownLong(int seconds) => seconds == 0
      ? 'Se envía directo, sin cuenta regresiva'
      : '$seconds segundos';

  static String minutes(int minutes) =>
      minutes == 0 ? 'Al salir' : '$minutes min';

  static String window(AlertWindow w) =>
      'de ${minuteOfDay(w.startMinute)} a ${minuteOfDay(w.endMinute)}'
      '${w.crossesMidnight ? ' (cruza la medianoche)' : ''}';

  static String mode(AlertMode mode) => switch (mode) {
    AlertMode.awayDuringWindow => 'Lejos de casa en el horario',
    AlertMode.awayAnytime => 'Lejos de casa a cualquier hora',
  };

  static String modeExplanation(AlertMode mode) => switch (mode) {
    AlertMode.awayDuringWindow =>
      'Se avisa solo si estás fuera de la zona y la hora está dentro del '
          'horario. Es lo más preciso y evita avisos innecesarios.',
    AlertMode.awayAnytime =>
      'Se avisa si estás fuera de la zona a cualquier hora, sin mirar el '
          'horario. Habrá más avisos.',
  };

  static String permission(PermissionKind kind) => switch (kind) {
    PermissionKind.fineLocation => 'Ubicación precisa',
    PermissionKind.backgroundLocation => 'Ubicación todo el tiempo',
    PermissionKind.sendSms => 'Enviar SMS',
    PermissionKind.notifications => 'Notificaciones',
    PermissionKind.batteryOptimization => 'Sin ahorro de batería',
  };

  static String permissionFix(PermissionKind kind) => switch (kind) {
    PermissionKind.fineLocation => 'Conceder ubicación',
    PermissionKind.backgroundLocation => 'Abrir ajustes de ubicación',
    PermissionKind.sendSms => 'Conceder SMS',
    PermissionKind.notifications => 'Conceder notificaciones',
    PermissionKind.batteryOptimization => 'Abrir ajustes de batería',
  };

  static String issue(ConfigIssue issue) => switch (issue) {
    ConfigIssue.ownerName => 'Escribe tu nombre (hasta 60 caracteres).',
    ConfigIssue.home => 'Falta definir tu casa.',
    ConfigIssue.radius => 'La distancia debe estar entre 100 m y 5 km.',
    ConfigIssue.window => 'Las horas del horario no son válidas.',
    ConfigIssue.windowIsAlways =>
      'El inicio y el fin del horario no pueden ser iguales. Elige otro '
          'horario o avisa a cualquier hora.',
    ConfigIssue.minAway => 'Los minutos fuera deben estar entre 0 y 60.',
    ConfigIssue.countdown => 'La cuenta regresiva debe durar entre 15 y 300 s.',
    ConfigIssue.dailyLimit => 'El límite diario debe estar entre 1 y 10.',
    ConfigIssue.message =>
      'Escribe un mensaje de hasta ${SafeZoneLimits.messageMax} caracteres.',
    ConfigIssue.recipientsMissing => 'Elige al menos una persona.',
    ConfigIssue.recipientsTooMany =>
      'Puedes elegir hasta ${SafeZoneLimits.maxRecipients} personas.',
    ConfigIssue.pinRequired =>
      'Con cuenta regresiva necesitas un PIN para poder cancelarla.',
  };

  static String eventTitle(SafeZoneEventType type) => switch (type) {
    SafeZoneEventType.monitoringStarted => 'Monitoreo iniciado',
    SafeZoneEventType.monitoringStopped => 'Monitoreo detenido',
    SafeZoneEventType.exitDetected => 'Android detectó que saliste de casa',
    SafeZoneEventType.enteredHome => 'Android detectó que volviste a casa',
    SafeZoneEventType.windowOpenedWhileAway =>
      'Empezó el horario de alerta y estabas fuera de casa',
    SafeZoneEventType.awayConfirmed => 'Se confirmó que sigues fuera de casa',
    SafeZoneEventType.suppressedOutsideWindow =>
      'No se avisó: estabas fuera del horario de alerta',
    SafeZoneEventType.suppressedDailyLimit =>
      'No se avisó: se alcanzó el límite diario',
    SafeZoneEventType.suppressedAlreadyAlerted =>
      'No se avisó otra vez: ya se avisó en esta salida',
    SafeZoneEventType.countdownStarted => 'Empezó la cuenta regresiva',
    SafeZoneEventType.countdownCancelled => 'Cancelaste la cuenta regresiva',
    SafeZoneEventType.smsSent =>
      'SMS entregado a la red del operador (no confirma que lo recibieran)',
    SafeZoneEventType.smsFailed => 'El SMS no se pudo enviar',
    SafeZoneEventType.permissionLost =>
      'Se perdió un permiso: el monitoreo puede no funcionar',
    SafeZoneEventType.unknown => 'Evento desconocido',
  };

  static IconData eventIcon(SafeZoneEventType type) => switch (type) {
    SafeZoneEventType.monitoringStarted => Icons.play_circle_outline,
    SafeZoneEventType.monitoringStopped => Icons.pause_circle_outline,
    SafeZoneEventType.exitDetected => Icons.logout,
    SafeZoneEventType.enteredHome => Icons.home_outlined,
    SafeZoneEventType.windowOpenedWhileAway => Icons.schedule,
    SafeZoneEventType.awayConfirmed => Icons.place_outlined,
    SafeZoneEventType.suppressedOutsideWindow ||
    SafeZoneEventType.suppressedDailyLimit ||
    SafeZoneEventType.suppressedAlreadyAlerted =>
      Icons.do_not_disturb_on_outlined,
    SafeZoneEventType.countdownStarted => Icons.timer_outlined,
    SafeZoneEventType.countdownCancelled => Icons.cancel_outlined,
    SafeZoneEventType.smsSent => Icons.sms_outlined,
    SafeZoneEventType.smsFailed => Icons.error_outline,
    SafeZoneEventType.permissionLost => Icons.warning_amber_outlined,
    SafeZoneEventType.unknown => Icons.help_outline,
  };

  static String sendOutcome(SendOutcome outcome) => switch (outcome) {
    SendOutcome.sent => 'Entregado a la red del operador',
    SendOutcome.permissionDenied => 'Sin permiso para enviar SMS',
    SendOutcome.failed => 'No se pudo enviar',
  };

  /// "hoy 14:05", "ayer 09:30" or "17/10 14:05", relative to [now].
  static String when(DateTime at, DateTime now) {
    final hhmm =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'hoy $hhmm';
    if (diff == 1) return 'ayer $hhmm';
    return '${at.day.toString().padLeft(2, '0')}/'
        '${at.month.toString().padLeft(2, '0')} $hhmm';
  }

  /// The limits the person must know, shown where they matter.
  static const limits =
      'Los eventos pueden tardar varios minutos en llegar. El fabricante del '
      'teléfono puede detener la app en segundo plano. Hace falta saldo en '
      'el chip. «Enviado» significa entregado a la red del operador, no que '
      'la persona lo haya recibido.';
}
