import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/models/logbook_case.dart';
import '../viewmodel/logbook_view_model.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.watch<LogbookViewModel>().cases;
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora')),
      body: cases.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay casos en la Bitácora. Se guardan solo en memoria y se eliminan al cerrar la app o al vencer su plazo.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              itemBuilder: (context, index) => _CaseTile(item: cases[index]),
            ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.item});

  final QhawixCase item;

  @override
  Widget build(BuildContext context) {
    final latestEvent = item.events.isEmpty ? 'Caso' : sessionEventLabel(item.events.last.type);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.folder_outlined),
        title: Text(latestEvent),
        subtitle: Text(
          '${item.evidence.length} evidencia(s) redactada(s) · ${item.events.length} eventos\n'
          'Creado: ${formatSessionDateTime(item.createdAt)} · vence: ${formatSessionDateTime(item.expiresAt)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Borrar caso',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => context.push('/cases/${item.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar caso'),
        content: const Text(
          'Se eliminarán de esta sesión la evidencia redactada, los resultados y la línea de tiempo. No se conservará un registro del caso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar caso'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LogbookViewModel>().deleteCase(item.id);
    }
  }
}

String sessionEventLabel(String type) => switch (type) {
      'case_created' => 'Caso iniciado',
      'evidence_analyzed' => 'Comunicación analizada',
      'false_alarm_reported' => 'Posible falsa alarma registrada',
      _ => 'Actividad de sesión',
    };

String formatSessionDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
