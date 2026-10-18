import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../qr_shield/domain/models/qr_security_incident.dart';
import '../../qr_shield/domain/repositories/qr_security_history_query_repository.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  late Future<List<QrSecurityIncident>> _incidents;

  QrSecurityHistoryQueryRepository get _repository =>
      context.read<QrSecurityHistoryQueryRepository>();

  @override
  void initState() {
    super.initState();
    _incidents = _repository.loadIncidents();
  }

  void _reload() {
    setState(() => _incidents = _repository.loadIncidents());
  }

  Future<void> _allow(QrSecurityIncident incident) async {
    final id = incident.id;
    if (id == null) return;
    try {
      final updated = await _repository.allowIncident(id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? 'El enlace se permitirá en próximos escaneos.'
                : 'No se pudo actualizar este registro.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el historial.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora')),
      body: SafeArea(
        child: FutureBuilder<List<QrSecurityIncident>>(
          future: _incidents,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo cargar el historial.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final incidents = snapshot.data ?? const [];
            if (incidents.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no hay enlaces bloqueados.'),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Historial de enlaces bloqueados. Al permitir uno, los próximos escaneos de esa URL omitirán Web Risk y la abrirán automáticamente.',
                    ),
                  ),
                  for (final incident in incidents)
                    _IncidentCard(
                      incident: incident,
                      onAllow: incident.canBeAllowed
                          ? () => _allow(incident)
                          : null,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onAllow});

  final QrSecurityIncident incident;
  final VoidCallback? onAllow;

  @override
  Widget build(BuildContext context) {
    final timestamp = incident.timestamp.toLocal().toString().split('.').first;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _categoryLabel(incident.threatCategory),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(incident.blockedUrl),
            const SizedBox(height: 4),
            Text('Fecha y hora: $timestamp'),
            if (incident.isAllowed) ...[
              const SizedBox(height: 8),
              const Chip(
                avatar: Icon(Icons.verified_user_outlined, size: 18),
                label: Text('Permitido'),
              ),
            ] else if (onAllow != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onAllow,
                  child: const Text('Permitir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String categories) => categories
      .split(',')
      .map((category) => switch (category.trim()) {
        'MALWARE' => 'Malware',
        'SOCIAL_ENGINEERING' => 'Phishing / Ingeniería social',
        'UNWANTED_SOFTWARE' => 'Software no deseado',
        'LOCAL_POLICY' => 'Bloqueo por política local',
        final category => category,
      })
      .join(', ');
}
