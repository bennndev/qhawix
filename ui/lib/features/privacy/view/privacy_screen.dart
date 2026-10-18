import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ayuda y privacidad')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _InfoCard(
              icon: Icons.phone_android,
              title: 'Análisis en el dispositivo',
              body: 'SENTINEL analiza texto en español localmente. El texto original no se conserva; se conserva una versión redactada en la memoria de la sesión, hasta que cierres la app o venza el plazo configurado. La redacción automática puede pasar por alto datos sensibles.',
            ),
            _InfoCard(
              icon: Icons.qr_code_2,
              title: 'Escudo QR',
              body: 'El QR se decodifica y muestra sin ejecutar acciones. Una consulta de reputación transmite la URL elegible al proveedor después de tu autorización. Si el proveedor no está habilitado o falla, el estado es «no verificable»; nunca significa que el enlace sea seguro.',
            ),
            _InfoCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Guardian Pago',
              body: 'Analiza solicitudes de pago reales con reglas locales y muestra señales orientativas. No se conecta con bancos, no bloquea pagos en otras aplicaciones, no mueve dinero y no confirma la identidad de una institución.',
            ),
            _InfoCard(
              icon: Icons.delete_outline,
              title: 'Control de tus datos',
              body: 'Puedes borrar cada caso desde Mi sesión. Al borrarlo se eliminan sus evidencias redactadas y su línea de tiempo sin guardar un registro del borrado. No hay cuenta ni sincronización en esta versión.',
            ),
            _InfoCard(
              icon: Icons.lock_outline,
              title: 'Permisos',
              body: 'La cámara se solicita solo al abrir el escáner; puedes pegar el contenido como alternativa. Esta versión no solicita contactos, SMS, registro de llamadas, micrófono ni ubicación.',
            ),
            SizedBox(height: 8),
            Text(
              'QHAWIX ofrece señales orientativas. No confirma identidad, no detecta todas las estafas y no sustituye la verificación con un canal oficial independiente.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
