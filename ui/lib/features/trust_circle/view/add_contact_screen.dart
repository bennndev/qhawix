import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/qhawix_inputs.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/action_result.dart';
import '../domain/trust_contact.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'labels.dart';
import 'trust_circle_scaffold.dart';

/// The person types a name and a number. The contact is added at once and
/// stays on the device: no invitation, no message, and QHAWIX never reads the
/// phone's contacts. The person does not need the app.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  ActionResult? _result;
  String? _addedName;
  String? _nameError;
  String? _phoneError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _nameError = name.isEmpty ? 'Escribe el nombre de la persona.' : null;
      _phoneError = digits.length < 6
          ? 'Escribe el número con código de país.'
          : null;
    });
    if (_nameError != null || _phoneError != null) return;
    setState(() => _saving = true);
    final vm = context.read<TrustCircleViewModel>();
    final result = await vm.addContact(name: name, phone: _phone.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = result;
      if (!result.isRejected) _addedName = name;
    });
  }

  void _another() {
    _name.clear();
    _phone.clear();
    setState(() {
      _result = null;
      _addedName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final added = _addedName != null;
    final space = context.space;
    final active = contactStatusStyle(ContactStatus.active);
    final kind = contactKindStyle(ContactKind.phoneOnly);
    return TrustCircleScaffold(
      title: 'Agregar contacto',
      children: [
        const PageHeader(
          title: 'Agrega a alguien de confianza',
          subtitle:
              'Escribe su nombre y su número. No necesita tener la app ni '
              'recibir una invitación.',
        ),
        if (!added) ...[
          QhawixTextField(
            label: 'Nombre',
            controller: _name,
            errorText: _nameError,
          ),
          QhawixTextField(
            label: 'Número de teléfono',
            controller: _phone,
            keyboardType: TextInputType.phone,
            helperText: 'Con código de país, por ejemplo +51.',
            errorText: _phoneError,
          ),
        ],
        if (_result != null) ActionResultBanner(result: _result!),
        if (added)
          SectionCard(
            title: 'Contacto agregado',
            children: [
              Text(_addedName!, style: context.text.bodyMedium),
              SizedBox(height: space.sm),
              Wrap(
                spacing: space.sm,
                runSpacing: space.xs,
                children: [
                  StatusChip(
                    label: active.label,
                    icon: active.icon,
                    tone: active.tone,
                  ),
                  StatusChip(
                    label: kind.label,
                    icon: kind.icon,
                    tone: kind.tone,
                  ),
                ],
              ),
              SizedBox(height: space.sm),
              Text(
                'Queda guardado en tu teléfono.',
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        const _HeadsUpNote(),
        if (added) ...[
          PrimaryButton(
            label: 'Listo',
            onPressed: () => Navigator.of(context).pop(),
          ),
          SecondaryButton(label: 'Agregar a otra persona', onPressed: _another),
        ] else
          PrimaryButton(
            label: 'Agregar contacto',
            icon: Icons.person_add_alt_outlined,
            loading: _saving,
            onPressed: _add,
          ),
      ],
    );
  }
}

class _HeadsUpNote extends StatelessWidget {
  const _HeadsUpNote();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    const points = [
      'Avísale que la agregaste: si hay una alerta, puede recibir mensajes '
          'tuyos.',
      'Sin la app, los mensajes van por SMS o WhatsApp. Se preparan en tu '
          'teléfono y los envías tú; QHAWIX no escribe a nadie por su cuenta.',
      'Puedes pausarla o quitarla cuando quieras.',
    ];
    return SectionCard(
      title: 'Antes de seguir',
      children: [
        for (final point in points)
          Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check,
                  size: space.iconSm,
                  color: context.qColors.accentDeep,
                ),
                SizedBox(width: space.sm),
                Expanded(child: Text(point, style: context.text.bodySmall)),
              ],
            ),
          ),
      ],
    );
  }
}
