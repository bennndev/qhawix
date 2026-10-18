import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/config/sentinel_policy.dart';

class SentinelInputScreen extends StatefulWidget {
  const SentinelInputScreen({
    super.key,
    this.caseId,
    required this.onAnalyze,
    required this.errorMessage,
  });

  final String? caseId;
  final String? Function({
    required String text,
    required String channel,
    String? caseId,
  }) onAnalyze;
  final String? Function() errorMessage;

  @override
  State<SentinelInputScreen> createState() => _SentinelInputScreenState();
}

class _SentinelInputScreenState extends State<SentinelInputScreen> {
  final TextEditingController _textController = TextEditingController();
  String _channel = 'messaging_app';
  bool _busy = false;
  bool _privacyAcknowledged = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() => _busy = true);
    final caseId = widget.onAnalyze(
      text: _textController.text,
      channel: _channel,
      caseId: widget.caseId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (caseId == null) {
      _showError(widget.errorMessage() ?? 'No se pudo analizar el contenido.');
      return;
    }
    context.go('/cases/$caseId');
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analizar comunicación')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Pega el contenido recibido. Se procesa en esta sesión; el texto original no se conserva después de redactar los datos detectables.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'No incluyas contraseñas, códigos bancarios ni información que no quieras revisar. La redacción automática puede fallar.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _channel,
                  decoration: const InputDecoration(labelText: 'Canal declarado'),
                  items: const [
                    DropdownMenuItem(value: 'phone_call', child: Text('Llamada telefónica')),
                    DropdownMenuItem(value: 'sms', child: Text('SMS')),
                    DropdownMenuItem(value: 'messaging_app', child: Text('Aplicación de mensajería')),
                    DropdownMenuItem(value: 'email', child: Text('Correo electrónico')),
                    DropdownMenuItem(value: 'in_person', child: Text('En persona')),
                    DropdownMenuItem(value: 'unknown', child: Text('No lo sé')),
                  ],
                  onChanged: (value) => setState(() => _channel = value ?? 'unknown'),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _privacyAcknowledged,
                  onChanged: (value) => setState(() => _privacyAcknowledged = value ?? false),
                  title: const Text('Entiendo cómo se procesa este contenido'),
                  subtitle: const Text(
                    'Se analiza en el dispositivo y solo se conserva redactado en esta sesión, '
                    'que se pierde al cerrar la app o al vencer el plazo configurado. La redacción automática puede fallar.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: const Text('Leer privacidad y límites'),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('sentinel-evidence-input'),
                  controller: _textController,
                  minLines: 7,
                  maxLines: 14,
                  maxLength: SentinelPolicy.maxTextCharacters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Texto de la comunicación',
                    hintText: 'Pega aquí el mensaje que recibiste',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || !_privacyAcknowledged ? null : _analyze,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Analizar en este dispositivo'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El análisis es orientativo. Una institución mencionada o un número conocido no autentican a quien escribe.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
