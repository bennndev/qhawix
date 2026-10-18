import 'package:flutter/material.dart';

/// Stable id for a product module (routing and activation).
enum AppModuleId {
  sentinel,
  qrShield,
  echoTrap,
  refuge,
  guardianPay,
  trustCircle,
  logbook,
  aura,
  privacy,
}

/// One Android (or OEM) permission the person may need for a module.
class ModulePermissionNeed {
  const ModulePermissionNeed({
    required this.title,
    required this.why,
    this.opensSystemSettings = false,
  });

  /// Short Spanish label (sentence case).
  final String title;

  /// One sentence: why this module needs it.
  final String why;

  /// True when the grant lives in a manufacturer or system settings page.
  final bool opensSystemSettings;
}

/// Catalog entry shown on Inicio / Analizar and used by module onboarding.
class ModuleCatalogEntry {
  const ModuleCatalogEntry({
    required this.id,
    required this.name,
    required this.purpose,
    required this.icon,
    required this.permissions,
    required this.routePath,
    this.limitNote,
    this.usesOwnOnboarding = false,
    this.skipActivationGate = false,
  });

  final AppModuleId id;
  final String name;
  final String purpose;
  final IconData icon;
  final List<ModulePermissionNeed> permissions;
  final String routePath;
  final String? limitNote;

  /// Module already has a dedicated wizard (for example Refugio zona segura).
  final bool usesOwnOnboarding;

  /// Open the module screen without the generic activation gate.
  final bool skipActivationGate;
}

/// Product modules for the shell menus. Copy follows README / DESIGN.md names.
abstract final class ModuleCatalog {
  static const List<ModuleCatalogEntry> all = [
    ModuleCatalogEntry(
      id: AppModuleId.sentinel,
      name: 'Sentinel',
      purpose: 'Analiza mensajes, correos y comprobantes en busca de engaño.',
      icon: Icons.mail_outline,
      routePath: '/m/sentinel',
      permissions: [
        ModulePermissionNeed(
          title: 'Ninguno al empezar',
          why: 'Puedes pegar o importar texto. Más adelante, compartir desde '
              'otras apps puede pedir acceso al archivo que elijas.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.qrShield,
      name: 'Escudo QR',
      purpose: 'Muestra y comprueba un QR o enlace antes de abrirlo.',
      icon: Icons.qr_code_scanner_outlined,
      routePath: '/m/qr-shield',
      permissions: [
        ModulePermissionNeed(
          title: 'Cámara',
          why: 'Solo al escanear. Si no la das, puedes pegar la URL.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.echoTrap,
      name: 'EchoTrap',
      purpose: 'Detecta voz clonada en llamadas con el altavoz encendido.',
      icon: Icons.phone_in_talk_outlined,
      routePath: '/m/echotrap',
      limitNote: 'No accede al audio de la llamada; usa el micrófono.',
      permissions: [
        ModulePermissionNeed(
          title: 'Micrófono',
          why: 'Escucha por el altavoz mientras tú activas la detección.',
        ),
        ModulePermissionNeed(
          title: 'Notificaciones',
          why: 'Muestra que la detección está activa en primer plano.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.refuge,
      name: 'Refugio',
      purpose: 'Zona segura: SMS a tu círculo si estás lejos de casa a deshora.',
      icon: Icons.shield_outlined,
      routePath: '/refugio',
      usesOwnOnboarding: true,
      skipActivationGate: true,
      limitNote: 'También pide inicio automático en algunos teléfonos.',
      permissions: [
        ModulePermissionNeed(
          title: 'Ubicación (todo el tiempo)',
          why: 'Para saber si saliste de tu zona de casa, con la app cerrada.',
          opensSystemSettings: true,
        ),
        ModulePermissionNeed(
          title: 'SMS',
          why: 'Envía la alerta desde tu propio celular a tus contactos.',
        ),
        ModulePermissionNeed(
          title: 'Notificaciones',
          why: 'Cuenta regresiva y avisos antes de enviar.',
        ),
        ModulePermissionNeed(
          title: 'Alarmas exactas',
          why: 'Revisa la ventana horaria aunque la app esté cerrada.',
        ),
        ModulePermissionNeed(
          title: 'Sin optimización de batería',
          why: 'Reduce que el sistema detenga las alertas.',
          opensSystemSettings: true,
        ),
        ModulePermissionNeed(
          title: 'Inicio automático (fabricante)',
          why: 'En Honor, Xiaomi y otros, sin esto el SMS en segundo plano falla.',
          opensSystemSettings: true,
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.guardianPay,
      name: 'Guardian Pago',
      purpose: 'Compuerta real antes de pagar o abrir una billetera.',
      icon: Icons.account_balance_wallet_outlined,
      routePath: '/m/guardian-pay',
      permissions: [
        ModulePermissionNeed(
          title: 'Los de Refugio, si usas la compuerta',
          why: 'La retención reutiliza la pausa de Refugio; no congela bancos.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.trustCircle,
      name: 'Red de Confianza',
      purpose: 'Contactos de confianza, alertas y SOS.',
      icon: Icons.group_outlined,
      routePath: '/red',
      skipActivationGate: true,
      permissions: [
        ModulePermissionNeed(
          title: 'Notificaciones',
          why: 'Para avisarte de alertas cuando el contacto usa la app.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.logbook,
      name: 'Bitácora',
      purpose: 'Línea de tiempo, evidencia e informes de incidentes.',
      icon: Icons.menu_book_outlined,
      routePath: '/bitacora',
      skipActivationGate: true,
      permissions: [],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.aura,
      name: 'AURA',
      purpose: 'Asistente que explica, guía y educa.',
      icon: Icons.chat_bubble_outline,
      routePath: '/m/aura',
      permissions: [],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.privacy,
      name: 'Privacidad',
      purpose: 'Consentimientos, permisos y borrado de datos.',
      icon: Icons.privacy_tip_outlined,
      routePath: '/m/privacy',
      permissions: [],
    ),
  ];

  static ModuleCatalogEntry byId(AppModuleId id) =>
      all.firstWhere((e) => e.id == id);

  static ModuleCatalogEntry? byPathSegment(String segment) {
    for (final e in all) {
      if (e.id.name == segment || _slug(e) == segment) return e;
    }
    return null;
  }

  static String _slug(ModuleCatalogEntry e) {
    switch (e.id) {
      case AppModuleId.qrShield:
        return 'qr-shield';
      case AppModuleId.echoTrap:
        return 'echotrap';
      case AppModuleId.guardianPay:
        return 'guardian-pay';
      case AppModuleId.trustCircle:
        return 'trust-circle';
      default:
        return e.id.name;
    }
  }

  static String slugFor(AppModuleId id) => _slug(byId(id));

  /// Modules listed on Inicio (overview).
  static List<ModuleCatalogEntry> get homeEntries => all;

  /// Analysis group on the Analizar tab.
  static List<ModuleCatalogEntry> get analyzeEntries => [
        byId(AppModuleId.sentinel),
        byId(AppModuleId.qrShield),
        byId(AppModuleId.echoTrap),
      ];
}
