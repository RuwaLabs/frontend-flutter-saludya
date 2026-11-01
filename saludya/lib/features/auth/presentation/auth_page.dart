import 'package:flutter/material.dart';
import '../../home/presentation/staff_home_page.dart';

import '../../../core/di/service_locator.dart';
import '../application/auth_service.dart';
import '../domain/auth_models.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _recoveryCode = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = sl<AuthService>();
  LoginChallenge? _challenge;
  PasswordRecoveryChallenge? _recoveryChallenge;
  PasswordResetGrant? _resetGrant;
  AuthSession? _session;
  bool _busy = false;
  bool _showPassword = false;
  bool _recovery = false;
  bool _reset = false;
  String? _notice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await _auth.restoreSession();
      if (mounted && session != null) setState(() => _session = session);
    } catch (_) {
      // A storage read failure leaves the user at the sign-in screen.
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _recoveryCode.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo completar la operaciÃ³n.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() => _run(() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final c = await _auth.startLogin(_email.text, _password.text);
    if (mounted) {
      setState(() {
        _challenge = c;
        _recovery = false;
        _recoveryChallenge = null;
      });
    }
  });

  Future<void> _verify() => _run(() async {
    if (_code.text.trim().length < 4) {
      setState(() => _error = 'Ingresa el cÃ³digo recibido por correo.');
      return;
    }
    final session = await _auth.verifyCode(_challenge!.id, _code.text);
    if (mounted) setState(() => _session = session);
  });

  Future<void> _recover() => _run(() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final challenge = await _auth.requestPasswordRecoveryCode(_email.text);
    if (mounted) {
      setState(() {
        _recoveryChallenge = challenge;
        _recoveryCode.clear();
      });
    }
  });

  Future<void> _verifyRecoveryCode() => _run(() async {
    if (_recoveryCode.text.trim().length != 6) {
      setState(
        () => _error = 'Ingresa el cÃ³digo de 6 dÃ­gitos recibido por correo.',
      );
      return;
    }
    final grant = await _auth.verifyPasswordRecoveryCode(
      _recoveryChallenge!.id,
      _recoveryCode.text.trim(),
    );
    if (mounted) {
      setState(() {
        _resetGrant = grant;
        _recoveryChallenge = null;
        _recoveryCode.clear();
        _reset = true;
      });
    }
  });

  Future<void> _resendRecoveryCode() => _run(() async {
    final challenge = await _auth.requestPasswordRecoveryCode(_email.text);
    if (mounted) {
      setState(() {
        _recoveryChallenge = challenge;
        _recoveryCode.clear();
      });
    }
  });

  Future<void> _resetPassword() => _run(() async {
    if (_resetGrant == null ||
        _newPassword.text.length < 8 ||
        _newPassword.text != _confirmPassword.text) {
      setState(
        () => _error =
            'Ingresa dos contraseÃ±as iguales de al menos 8 caracteres.',
      );
      return;
    }
    await _auth.resetPassword(
      _resetGrant!.token,
      _newPassword.text,
      _confirmPassword.text,
    );
    if (mounted) {
      setState(() {
        _reset = false;
        _resetGrant = null;
        _recovery = false;
        _password.clear();
        _newPassword.clear();
        _confirmPassword.clear();
        _notice = 'ContraseÃ±a actualizada. Ya puedes iniciar sesiÃ³n.';
      });
    }
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_session != null) {
      return StaffHomePage(auth: _auth, onSignedOut: () {
        if (mounted) setState(() { _session = null; _challenge = null; _code.clear(); });
      });
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _challenge != null
                  ? _verification(theme)
                  : _recoveryChallenge != null
                  ? _recoveryVerification(theme)
                  : _content(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(ThemeData theme) => Column(
    children: [
      Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          Icons.health_and_safety_rounded,
          size: 42,
          color: theme.colorScheme.primary,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'SaludYa',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Acceso para personal de salud',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _content(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _brand(theme),
      const SizedBox(height: 34),
      Text(
        _reset
            ? 'Restablecer contraseÃ±a'
            : _recovery
            ? 'Recuperar acceso'
            : 'Iniciar sesiÃ³n',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 20),
      if (_reset) ...[
        _field(
          _newPassword,
          'Nueva contraseÃ±a',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 14),
        _field(
          _confirmPassword,
          'Confirmar contraseÃ±a',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 22),
        _button('Guardar contraseÃ±a', _resetPassword),
        TextButton(
          onPressed: () => setState(() {
            _reset = false;
            _resetGrant = null;
            _recovery = false;
          }),
          child: const Text('Volver'),
        ),
      ] else ...[
        Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                _email,
                'Correo electrÃ³nico',
                icon: Icons.mail_outline,
                keyboard: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Ingresa un correo vÃ¡lido'
                    : null,
              ),
              if (!_recovery) ...[
                const SizedBox(height: 14),
                _field(
                  _password,
                  'ContraseÃ±a',
                  icon: Icons.lock_outline,
                  obscure: !_showPassword,
                  suffix: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa tu contraseÃ±a' : null,
                ),
              ],
            ],
          ),
        ),
        if (!_recovery)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _recovery = true;
                _error = null;
              }),
              child: const Text('Â¿Olvidaste tu contraseÃ±a?'),
            ),
          )
        else
          const SizedBox(height: 22),
        _button(
          _recovery ? 'Enviar cÃ³digo al correo' : 'Continuar',
          _recovery ? _recover : _login,
        ),
        if (_recovery)
          TextButton(
            onPressed: () => setState(() {
              _recovery = false;
              _error = null;
              _notice = null;
            }),
            child: const Text('Volver al inicio de sesiÃ³n'),
          ),
      ],
      _messages(theme),
    ],
  );

  Widget _verification(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _brand(theme),
      const SizedBox(height: 34),
      Text(
        'Verifica tu correo',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text('Enviamos un cÃ³digo a ${_challenge!.maskedEmail}.'),
      const SizedBox(height: 24),
      _field(
        _code,
        'CÃ³digo de verificaciÃ³n',
        icon: Icons.password,
        keyboard: TextInputType.number,
      ),
      const SizedBox(height: 20),
      _button('Verificar e ingresar', _verify),
      TextButton(
        onPressed: () => _run(() => _auth.resendCode(_challenge!.id)),
        child: const Text('Reenviar cÃ³digo'),
      ),
      TextButton(
        onPressed: () => setState(() {
          _challenge = null;
          _code.clear();
          _error = null;
        }),
        child: const Text('Volver'),
      ),
      _messages(theme),
    ],
  );

  Widget _recoveryVerification(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _brand(theme),
      const SizedBox(height: 34),
      Text(
        'Verifica tu correo',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Si la cuenta estÃ¡ activa, enviamos un cÃ³digo a ${_recoveryChallenge!.maskedEmail}.',
      ),
      const SizedBox(height: 24),
      _field(
        _recoveryCode,
        'CÃ³digo de 6 dÃ­gitos',
        icon: Icons.password,
        keyboard: TextInputType.number,
      ),
      const SizedBox(height: 20),
      _button('Verificar cÃ³digo', _verifyRecoveryCode),
      TextButton(
        onPressed: _resendRecoveryCode,
        child: const Text('Reenviar cÃ³digo'),
      ),
      TextButton(
        onPressed: () => setState(() {
          _recoveryChallenge = null;
          _recovery = true;
          _recoveryCode.clear();
          _error = null;
        }),
        child: const Text('Volver'),
      ),
      _messages(theme),
    ],
  );

  Widget _messages(ThemeData theme) => Column(
    children: [
      if (_busy)
        const Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      if (_notice != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _notice!,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
    ],
  );

  Widget _button(String label, VoidCallback action) => FilledButton(
    onPressed: _busy ? null : action,
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    child: Text(label),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboard,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
    ),
  );
}
