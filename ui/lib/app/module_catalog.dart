import 'package:flutter/material.dart';

/// Stable id for a product module (routing and activation).
enum AppModuleId {
  sentinel,
  qrShield,
  echoTrap,
  refuge,
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

  final String title;
  final String why;
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
  final bool usesOwnOnboarding;
  final bool skipActivationGate;
}

/// Product modules for the shell menus.
abstract final class ModuleCatalog {
  static const List<ModuleCatalogEntry> all = [
    ModuleCatalogEntry(
      id: AppModuleId.sentinel,
      name: 'Sentinel',
      purpose: 'Analiza mensajes y comprobantes en busca de engaño.',
      icon: Icons.mail_outline,
      routePath: '/m/sentinel',
      permissions: [
        ModulePermissionNeed(
          title: 'Ninguno al empezar',
          why: 'Puedes pegar texto. Compartir desde otras apps es opcional.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.qrShield,
      name: 'Escudo QR',
      purpose: 'Comprueba un QR o enlace antes de abrirlo.',
      icon: Icons.qr_code_scanner_outlined,
      routePath: '/m/qr-shield',
      permissions: [
        ModulePermissionNeed(
          title: 'Cámara',
          why: 'Solo al escanear. Si no, pega la URL.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.echoTrap,
      name: 'EchoTrap',
      purpose: 'Llama, consulta tus contactos y revisa llamadas con EchoTrap.',
      icon: Icons.phone_in_talk_outlined,
      routePath: '/m/echotrap',
      skipActivationGate: true,
      permissions: [
        ModulePermissionNeed(
          title: 'Contactos',
          why: 'Solo para mostrar tu agenda y llamar a quien elijas.',
        ),
        ModulePermissionNeed(
          title: 'Micrófono',
          why: 'Escucha por el altavoz mientras tú activas la detección.',
        ),
        ModulePermissionNeed(
          title: 'Notificaciones',
          why: 'Muestra que la detección está activa.',
        ),
        ModulePermissionNeed(
          title: 'SMS',
          why:
              'Solo si una llamada se marca como estafa: avisa a tus contactos de confianza.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.refuge,
      name: 'Refugio',
      purpose:
          'Zona segura: SMS a tu círculo si estás lejos de casa a deshora.',
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
          why:
              'En Honor, Xiaomi y otros, sin esto el SMS en segundo plano falla.',
          opensSystemSettings: true,
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.trustCircle,
      name: 'Red de Confianza',
      purpose: 'Contactos de confianza, alertas y SOS.',
      icon: Icons.group_outlined,
      routePath: '/red',
      usesOwnOnboarding: true,
      skipActivationGate: true,
      permissions: [
        ModulePermissionNeed(
          title: 'Notificaciones',
          why: 'Avisos cuando la app no está abierta.',
        ),
        ModulePermissionNeed(
          title: 'Selector de contactos',
          why: 'Eliges un contacto; no leemos toda tu agenda.',
        ),
      ],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.logbook,
      name: 'Bitácora',
      purpose: 'Línea de tiempo e informes.',
      icon: Icons.menu_book_outlined,
      routePath: '/bitacora',
      skipActivationGate: true,
      permissions: [],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.aura,
      name: 'AURA',
      purpose: 'Ayuda y guías.',
      icon: Icons.chat_bubble_outline,
      routePath: '/m/aura',
      permissions: [],
    ),
    ModuleCatalogEntry(
      id: AppModuleId.privacy,
      name: 'Privacidad',
      purpose: 'Consentimientos y borrado de datos.',
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
      case AppModuleId.trustCircle:
        return 'trust-circle';
      default:
        return e.id.name;
    }
  }

  static String slugFor(AppModuleId id) => _slug(byId(id));

  /// Modules on Inicio (not duplicated as bottom tabs).
  static List<ModuleCatalogEntry> get homeEntries => [
    byId(AppModuleId.sentinel),
    byId(AppModuleId.qrShield),
    byId(AppModuleId.echoTrap),
    byId(AppModuleId.aura),
    byId(AppModuleId.privacy),
  ];

  static List<ModuleCatalogEntry> get analyzeEntries => [
    byId(AppModuleId.sentinel),
    byId(AppModuleId.qrShield),
    byId(AppModuleId.echoTrap),
  ];
}
