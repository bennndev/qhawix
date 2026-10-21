import 'package:flutter/material.dart';

import '../domain/models/qr_site_note.dart';
import '../viewmodel/qr_site_note_view_model.dart';

/// Personal note about the reviewed host. It is shown below the verdict and
/// never changes it; nothing is sent until the person taps a button.
class QrSiteNoteCard extends StatefulWidget {
  const QrSiteNoteCard({
    super.key,
    required this.viewModel,
    required this.hostKey,
  });

  final QrSiteNoteViewModel viewModel;

  /// Exact lowercase ASCII host the note belongs to.
  final String hostKey;

  @override
  State<QrSiteNoteCard> createState() => _QrSiteNoteCardState();
}

class _QrSiteNoteCardState extends State<QrSiteNoteCard> {
  final TextEditingController _controller = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus();
  }

  @override
  void didUpdateWidget(covariant QrSiteNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostKey != widget.hostKey) {
      _editing = false;
      _controller.clear();
      _focus();
    }
  }

  void _focus() {
    final host = widget.hostKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.hostKey == host) widget.viewModel.focusHost(host);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final text = Theme.of(context).textTheme;
    final current = viewModel.host == widget.hostKey;
    final status = current ? viewModel.status : QrSiteNoteStatus.idle;
    final note = current ? viewModel.note : null;
    final failure = current ? viewModel.failure : null;
    final busy = current && viewModel.isBusy;

    return Card(
      key: const Key('qr-site-note-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Tu nota personal', style: text.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Solo tú la ves. Es un recordatorio tuyo: no verifica el sitio '
              'ni cambia el resultado de la revisión.',
            ),
            const SizedBox(height: 12),
            ..._body(context, status, note, busy),
            if (failure != null) ...[
              const SizedBox(height: 8),
              Text(
                _failureMessage(failure),
                key: const Key('qr-site-note-failure'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    QrSiteNoteStatus status,
    QrSiteNote? note,
    bool busy,
  ) {
    switch (status) {
      case QrSiteNoteStatus.idle:
      case QrSiteNoteStatus.failed:
        return [
          Text(
            'Al tocar «Ver mi nota», el dominio ${widget.hostKey} se envía con '
            'tu sesión a QHAWIX, que consulta Atomic Memory solo para tu '
            'cuenta. No se envía la URL completa.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('qr-site-note-load'),
            onPressed: busy ? null : widget.viewModel.load,
            icon: const Icon(Icons.search),
            label: const Text('Ver mi nota'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ];
      case QrSiteNoteStatus.loading:
      case QrSiteNoteStatus.saving:
      case QrSiteNoteStatus.deleting:
        return [
          Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(switch (status) {
                  QrSiteNoteStatus.saving => 'Guardando nota…',
                  QrSiteNoteStatus.deleting => 'Borrando nota…',
                  _ => 'Buscando tu nota…',
                }),
              ),
            ],
          ),
        ];
      case QrSiteNoteStatus.none:
        return _editor(busy, saveLabel: 'Guardar nota', intro: true);
      case QrSiteNoteStatus.found:
        if (_editing) return _editor(busy, saveLabel: 'Guardar corrección');
        return [
          SelectableText(note!.text, key: const Key('qr-site-note-text')),
          if (note.savedAt case final savedAt?) ...[
            const SizedBox(height: 4),
            Text('Guardada: ${savedAt.toLocal()}'),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('qr-site-note-edit'),
                onPressed: busy
                    ? null
                    : () => setState(() {
                        _controller.text = note.text;
                        _editing = true;
                      }),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Corregir'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
              TextButton.icon(
                key: const Key('qr-site-note-delete'),
                onPressed: busy ? null : () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Borrar nota'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
        ];
    }
  }

  List<Widget> _editor(
    bool busy, {
    required String saveLabel,
    bool intro = false,
  }) {
    return [
      if (intro) ...[
        const Text('Aún no tienes una nota para este sitio.'),
        const SizedBox(height: 8),
      ],
      TextField(
        key: const Key('qr-site-note-input'),
        controller: _controller,
        maxLength: qrSiteNoteMaxLength,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Nota',
          hintText: 'Por ejemplo: lo comprobé en la app oficial de la tienda.',
          helperText:
              'No escribas claves ni códigos. Los números largos, códigos y '
              'correos se ocultan antes de guardar.',
          helperMaxLines: 3,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('qr-site-note-save'),
            onPressed: busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saveLabel),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          if (_editing)
            TextButton(
              onPressed: busy ? null : () => setState(() => _editing = false),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Cancelar'),
            ),
        ],
      ),
    ];
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    final host = widget.hostKey;
    await widget.viewModel.save(value);
    if (!mounted || widget.hostKey != host) return;
    if (widget.viewModel.status == QrSiteNoteStatus.found &&
        widget.viewModel.failure == null) {
      setState(() {
        _editing = false;
        _controller.clear();
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar nota'),
        content: Text(
          'Se borrará tu nota sobre ${widget.hostKey} de Atomic Memory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.viewModel.delete();
  }
}

String _failureMessage(QrSiteNoteFailure failure) => switch (failure) {
  QrSiteNoteFailure.notConfigured =>
    'Las notas personales no están disponibles en esta instalación.',
  QrSiteNoteFailure.unauthorized =>
    'Tu sesión venció. Vuelve a iniciar sesión para usar tus notas.',
  QrSiteNoteFailure.rateLimited =>
    'Alcanzaste el límite diario de consultas de notas. Inténtalo mañana.',
  QrSiteNoteFailure.timeout =>
    'El servicio de notas tardó demasiado. No se confirmó ningún cambio.',
  QrSiteNoteFailure.invalidInput =>
    'La nota no es válida. Usa texto breve, sin caracteres de control.',
  QrSiteNoteFailure.correctionNotApplied =>
    'No se pudo reemplazar tu nota anterior. Se mantiene sin cambios.',
  QrSiteNoteFailure.saveUnconfirmed =>
    'No se pudo confirmar que la nota se guardara. No se guardó.',
  QrSiteNoteFailure.unavailable =>
    'El servicio de notas no respondió. No se confirmó ningún cambio.',
};
