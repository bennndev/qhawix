import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/qhawix_inputs.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/action_result.dart';
import '../viewmodel/family_keyword_view_model.dart';
import 'trust_circle_scaffold.dart';

/// Create, reveal and change the shared family keyword. It stays hidden until
/// the person taps "Mostrar" and hides again when the app goes to background
/// or the screen closes.
class FamilyKeywordScreen extends StatefulWidget {
  const FamilyKeywordScreen({super.key});

  @override
  State<FamilyKeywordScreen> createState() => _FamilyKeywordScreenState();
}

class _FamilyKeywordScreenState extends State<FamilyKeywordScreen>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  late final FamilyKeywordViewModel _vm;
  ActionResult? _result;
  bool _saving = false;

  static const _mask = '••••••••';

  @override
  void initState() {
    super.initState();
    _vm = context.read<FamilyKeywordViewModel>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _vm.hide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    Future.microtask(_vm.hide);
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _vm.save(_input.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = result;
      if (!result.isRejected) _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FamilyKeywordViewModel>();
    final space = context.space;
    if (!vm.loaded) {
      return const TrustCircleScaffold(
        title: 'Palabra clave familiar',
        children: [LoadingSkeleton()],
      );
    }
    return TrustCircleScaffold(
      title: 'Palabra clave familiar',
      children: [
        const PageHeader(
          title: 'Una palabra que solo tu familia sabe',
          subtitle:
              'Sirve para comprobar que quien llama es de verdad quien dice ser.',
        ),
        if (vm.hasKeyword)
          SectionCard(
            title: 'Tu palabra clave',
            children: [
              Semantics(
                label: vm.revealed
                    ? 'Palabra clave: ${vm.keyword}'
                    : 'Palabra clave oculta',
                excludeSemantics: true,
                child: Text(
                  vm.revealed ? vm.keyword! : _mask,
                  style: context.text.headlineMedium,
                ),
              ),
              SizedBox(height: space.md),
              SecondaryButton(
                label: vm.revealed ? 'Ocultar' : 'Mostrar',
                icon: vm.revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onPressed: vm.revealed ? vm.hide : vm.reveal,
              ),
            ],
          ),
        SectionCard(
          title: vm.hasKeyword ? 'Cambiar la palabra' : 'Crear la palabra',
          children: [
            QhawixTextField(
              label: 'Nueva palabra clave',
              controller: _input,
              helperText: 'Al menos 4 caracteres. Evita nombres o fechas.',
              obscureText: true,
            ),
            SizedBox(height: space.md),
            vm.hasKeyword
                ? SecondaryButton(
                    label: 'Cambiar palabra clave',
                    onPressed: _saving ? null : _save,
                  )
                : PrimaryButton(
                    label: 'Crear palabra clave',
                    loading: _saving,
                    onPressed: _save,
                  ),
          ],
        ),
        if (_result != null) ActionResultBanner(result: _result!),
        const _Guidance(),
      ],
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance();

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    const lines = [
      'Si alguien te la pide por teléfono y no la sabe, cuelga y vuelve a '
          'llamar por otro canal: un número que ya tengas guardado o en persona.',
      'No la escribas en chats ni la compartas por mensaje.',
      'Cámbiala si crees que alguien más la conoce.',
    ];
    return SectionCard(
      title: 'Cómo usarla',
      children: [
        for (final line in lines)
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
                Expanded(child: Text(line, style: context.text.bodySmall)),
              ],
            ),
          ),
      ],
    );
  }
}
