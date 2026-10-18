import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/qhawix_app_bar.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../domain/alert_recipient_source.dart';
import '../domain/safe_zone_platform.dart';
import '../viewmodel/safe_zone_setup_view_model.dart';
import 'onboarding_steps.dart';
import 'safe_zone_common.dart';

/// Setup wizard of the safe-zone alerts: seven steps with a visible progress
/// and a back action. The hub opens it at a given [initialStep] to edit an
/// existing configuration.
class SafeZoneOnboardingScreen extends StatelessWidget {
  const SafeZoneOnboardingScreen({
    super.key,
    this.initialStep = SetupStep.intro,
    this.onFinished,
  });

  final SetupStep initialStep;

  /// Called after the config was saved and monitoring runs.
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<SafeZoneSetupViewModel>(
        create: (context) => SafeZoneSetupViewModel(
          platform: context.read<SafeZonePlatform>(),
          recipientSource: context.read<AlertRecipientSource>(),
          initialStep: initialStep,
        )..load(),
        child: _Wizard(initialStep: initialStep, onFinished: onFinished),
      );
}

class _Wizard extends StatelessWidget {
  const _Wizard({required this.initialStep, required this.onFinished});

  /// A step other than the first means the hub opened the wizard to edit.
  final SetupStep initialStep;
  final VoidCallback? onFinished;

  bool get editing => initialStep != SetupStep.intro;

  static const _titles = {
    SetupStep.intro: 'Qué hace',
    SetupStep.recipients: 'Destinatarios',
    SetupStep.home: 'Casa',
    SetupStep.parameters: 'Parámetros',
    SetupStep.sending: 'Envío',
    SetupStep.permissions: 'Permisos',
    SetupStep.review: 'Revisión',
  };

  Widget _body(BuildContext context, SafeZoneSetupViewModel vm) =>
      switch (vm.step) {
        SetupStep.intro => const IntroStep(),
        SetupStep.recipients => const RecipientsStep(),
        SetupStep.home => const HomeStep(),
        SetupStep.parameters => const ParametersStep(),
        SetupStep.sending => const SendingStep(),
        SetupStep.permissions => const PermissionsStep(),
        SetupStep.review => ReviewStep(
          onSendTest: () => _sendTest(context, vm),
        ),
      };

  Future<void> _sendTest(
    BuildContext context,
    SafeZoneSetupViewModel vm,
  ) async {
    final confirmed = await confirmRealSms(
      context,
      recipientCount: vm.selectedRecipients.length,
    );
    if (confirmed) await vm.sendTestMessage();
  }

  Future<void> _finish(BuildContext context, SafeZoneSetupViewModel vm) async {
    final navigator = Navigator.of(context);
    await vm.finish();
    if (!vm.finished) return;
    onFinished?.call();
    if (editing && navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SafeZoneSetupViewModel>();
    final space = context.space;
    final isFirst = vm.step == SetupStep.intro;
    final atStart = vm.step == initialStep;
    final isLast = vm.step == SetupStep.review;
    final position = vm.step.index + 1;
    final total = SetupStep.values.length;
    return PopScope(
      canPop: atStart,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.back();
      },
      child: ResumeRefresh(
        onResume: vm.refreshStatus,
        child: Scaffold(
          appBar: QhawixAppBar(
            title: 'Alertas de zona segura',
            automaticallyImplyLeading: editing && atStart,
          ),
          body: SafeArea(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.unavailable
                ? const SafeZoneUnavailableView()
                : Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          space.gutter,
                          space.sm,
                          space.gutter,
                          0,
                        ),
                        child: _Progress(
                          position: position,
                          total: total,
                          title: _titles[vm.step]!,
                        ),
                      ),
                      Expanded(
                        child: SafeZonePage(
                          children: [
                            if (vm.note != null)
                              NoteBanner(
                                note: vm.note!,
                                onDismiss: vm.dismissNote,
                              ),
                            _body(context, vm),
                          ],
                        ),
                      ),
                      _Actions(
                        isFirst: isFirst,
                        isLast: isLast,
                        leaves: editing && atStart,
                        vm: vm,
                        onBack: editing && atStart
                            ? () => Navigator.of(context).maybePop()
                            : vm.back,
                        onNext: vm.next,
                        onFinish: () => _finish(context, vm),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.position,
    required this.total,
    required this.title,
  });

  final int position;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Semantics(
      container: true,
      label: 'Paso $position de $total: $title',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso $position de $total · $title',
            style: context.text.labelMedium?.copyWith(
              color: context.qColors.onSurfaceMuted,
            ),
          ),
          SizedBox(height: space.xs),
          LinearProgressIndicator(
            value: position / total,
            minHeight: space.xs,
            borderRadius: context.shapes.pillRadius,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isFirst,
    required this.isLast,
    required this.leaves,
    required this.vm,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
  });

  final bool isFirst;
  final bool isLast;

  /// Back leaves the wizard (editing from its first step).
  final bool leaves;
  final SafeZoneSetupViewModel vm;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final finishLabel = vm.monitoringNow
        ? 'Guardar cambios'
        : 'Iniciar monitoreo';
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: space.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.all(space.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLast)
                PrimaryButton(
                  label: finishLabel,
                  loading: vm.running == SetupCommand.finish,
                  onPressed: vm.canStart && !vm.busy ? onFinish : null,
                )
              else
                PrimaryButton(
                  label: isFirst ? 'Empezar' : 'Siguiente',
                  onPressed: vm.canAdvance ? onNext : null,
                ),
              if (!isFirst || leaves) ...[
                SizedBox(height: space.sm),
                SecondaryButton(
                  label: leaves ? 'Cancelar' : 'Atrás',
                  onPressed: onBack,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
