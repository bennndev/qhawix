import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/qhawix_inputs.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/action_result.dart';
import '../viewmodel/trust_circle_view_model.dart';
import 'trust_circle_scaffold.dart';

/// The person types a name and a number. QHAWIX never reads the phone's
/// contacts. The contact stays "invited" until they accept.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  ActionResult? _result;
  String? _invitedName;
  String? _nameError;
  String? _phoneError;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final name = _name.text.trim();
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _nameError = name.isEmpty ? 'Escribe el nombre de la persona.' : null;
      _phoneError = digits.length < 6
          ? 'Escribe el número con código de país.'
          : null;
    });
    if (_nameError != null || _phoneError != null) return;
    setState(() => _sending = true);
    final vm = context.read<TrustCircleViewModel>();
    final result = await vm.inviteContact(name: name, phone: _phone.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = result;
      if (!result.isRejected) _invitedName = name;
    });
  }

  void _another() {
    _name.clear();
    _phone.clear();
    setState(() {
      _result = null;
      _invitedName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _invitedName != null;
    return TrustCircleScaffold(
      title: 'Agregar contacto',
      children: [
        const PageHeader(
          title: 'Invita a alguien de confianza',
          subtitle: 'Escribe sus datos tú mismo: QHAWIX no lee tu agenda.',
        ),
        if (!pending) ...[
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
        const _ConsentExplanation(),
        if (_result != null) ActionResultBanner(result: _result!),
        if (pending)
          SectionCard(
            title: 'Invitación pendiente',
            children: [
              Text(_invitedName!, style: context.text.bodyMedium),
              SizedBox(height: context.space.sm),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusChip(
                  label: 'Invitación pendiente',
                  icon: Icons.hourglass_empty,
                  tone: StatusTone.caution,
                ),
              ),
              SizedBox(height: context.space.sm),
              Text(
                'No recibe avisos hasta que acepte.',
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        if (pending) ...[
          PrimaryButton(
            label: 'Listo',
            onPressed: () => Navigator.of(context).pop(),
          ),
          SecondaryButton(label: 'Invitar a otra persona', onPressed: _another),
        ] else
          PrimaryButton(
            label: 'Crear invitación',
            icon: Icons.person_add_alt_outlined,
            loading: _sending,
            onPressed: _invite,
          ),
      ],
    );
  }
}

class _ConsentExplanation extends StatelessWidget {
  const _ConsentExplanation();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    const points = [
      'La persona recibe una invitación y decide si acepta.',
      'Hasta que acepte queda como invitada: no recibe avisos ni ve nada.',
      'Puedes pausarla o quitarla cuando quieras.',
    ];
    return SectionCard(
      title: 'Consentimiento mutuo',
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
