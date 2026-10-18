import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True when the person is signed in (false in previews and tests, where
/// Supabase is not initialized).
bool get hasQhawixSession {
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return false;
  }
}

/// Ends the session; [AuthenticationGate] then shows the sign-in screen.
Future<void> signOutOfQhawix() async {
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {
    // Nothing to close when there is no configured session.
  }
}

/// The gate sits above the Navigator, so its screens bring their own Overlay
/// (needed by text selection, paste and tooltips).
Widget _withOverlay(Widget child) =>
    Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]);

/// Keeps the QHAWIX shell behind one sign-in screen.
class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    try {
      _client = Supabase.instance.client;
      _hasSession = _client!.auth.currentSession != null;
      _authSubscription = _client!.auth.onAuthStateChange.listen((state) {
        if (mounted) setState(() => _hasSession = state.session != null);
      });
    } catch (_) {
      _client = null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client == null) return _withOverlay(const _AccessUnavailableScreen());
    if (!_hasSession) return _withOverlay(_SignInScreen(client: client));
    return widget.child;
  }
}

class _AccessUnavailableScreen extends StatelessWidget {
  const _AccessUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.shield_moon_outlined,
                    size: 48,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No se pudo abrir QHAWIX',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La aplicación no tiene lista la conexión para iniciar sesión. Instala una versión configurada y vuelve a intentarlo.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen({required this.client});

  final SupabaseClient client;

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creatingAccount = false;
  bool _working = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Escribe tu correo y contraseña.');
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      if (_creatingAccount) {
        final response = await widget.client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.session == null && mounted) {
          setState(
            () => _message =
                'Cuenta creada. Revisa tu correo para confirmarla y luego inicia sesión.',
          );
        }
      } else {
        await widget.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'No se pudo iniciar sesión. Revisa tu conexión y vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.shield_moon_outlined,
                    size: 48,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QHAWIX',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _creatingAccount ? 'Crear cuenta' : 'Iniciar sesión',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra para usar EchoTrap y las demás herramientas de QHAWIX.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _working ? null : _submit,
                    child: Text(
                      _working
                          ? 'Un momento…'
                          : _creatingAccount
                          ? 'Crear cuenta'
                          : 'Iniciar sesión',
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _working
                          ? null
                          : () => setState(() {
                              _creatingAccount = !_creatingAccount;
                              _message = null;
                            }),
                      child: Text(
                        _creatingAccount
                            ? 'Ya tengo cuenta'
                            : 'Crear una cuenta nueva',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
