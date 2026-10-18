import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/logbook/viewmodel/logbook_view_model.dart';

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logbook = context.watch<LogbookViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('QHAWIX')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 36),
                        SizedBox(height: 12),
                        Text(
                          'Revisa antes de actuar',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Analiza comunicaciones, solicitudes de pago y enlaces antes de actuar. '
                          'Las señales orientan; no confirman identidad ni eliminan todo riesgo.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _HomeAction(
                  icon: Icons.message_outlined,
                  title: 'Analizar comunicación',
                  subtitle: 'Pega un mensaje para revisar señales en el dispositivo.',
                  onTap: () => context.push('/evidence/new'),
                ),
                _HomeAction(
                  icon: Icons.email_outlined,
                  title: 'Revisar Gmail',
                  subtitle: 'Analiza el correo más reciente cuando tú lo solicites.',
                  onTap: () => context.push('/sentinel/gmail'),
                ),
                _HomeAction(
                  icon: Icons.qr_code_scanner,
                  title: 'Escudo QR',
                  subtitle: 'Muestra el contenido y el destino antes de abrir.',
                  onTap: () => context.push('/qr'),
                ),
                _HomeAction(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Guardian Pago',
                  subtitle: 'Analiza una solicitud real; QHAWIX no bloquea ni ejecuta pagos.',
                  onTap: () => context.push('/guardian'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/logbook'),
                  icon: const Icon(Icons.timeline),
                  label: Text('Bitácora (${logbook.cases.length} casos en memoria)'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/help'),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ayuda y privacidad'),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, size: 28),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          minVerticalPadding: 12,
        ),
      );
}
