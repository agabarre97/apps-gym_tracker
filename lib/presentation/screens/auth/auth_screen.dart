import 'package:flutter/material.dart';

import 'package:gym_tracker/domain/ports/auth_port.dart';
import 'package:gym_tracker/domain/ports/sync_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Authentication screen with Sign In / Sign Up tabs and Google Sign-In.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authPort,
    required this.syncedStorage,
    required this.onAuthenticated,
  });

  final AuthPort authPort;
  final SyncPort syncedStorage;
  final ValueChanged<BuildContext> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final AuthUser user;
      if (_isSignUp) {
        user = await widget.authPort.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        user = await widget.authPort.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      await _onAuthSuccess(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showAuthError(e.code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showAuthError('generic');
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _loading = true);

    try {
      final user = await widget.authPort.signInWithGoogle();
      await _onAuthSuccess(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (e.code == 'sign-in-cancelled') return;
      _showAuthError(e.code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showAuthError('generic');
    }
  }

  Future<void> _onAuthSuccess(AuthUser user) async {
    widget.syncedStorage.setUserId(user.uid);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.authSyncing)),
    );

    // Pull cloud data but don't block navigation if it takes too long
    await widget.syncedStorage
        .pullFromCloud(timeout: const Duration(seconds: 8));

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _loading = false);
    widget.onAuthenticated(context);
  }

  void _showAuthError(String code) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (code) {
      'wrong-password' || 'invalid-credential' => l10n.authErrorWrongPassword,
      'email-already-in-use' => l10n.authErrorEmailInUse,
      'invalid-email' => l10n.authErrorInvalidEmail,
      'weak-password' => l10n.authErrorWeakPassword,
      'user-not-found' => l10n.authErrorUserNotFound,
      _ => l10n.authErrorGeneric,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center,
                      size: 64, color: context.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    l10n.sharedAppTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.authEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.sharedFieldRequired;
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return l10n.authErrorInvalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitEmailPassword(),
                    decoration: InputDecoration(
                      labelText: l10n.authPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l10n.sharedFieldRequired;
                      }
                      if (_isSignUp && v.length < 6) {
                        return l10n.authErrorWeakPassword;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submitEmailPassword,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isSignUp ? l10n.authSignUp : l10n.authSignIn,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle sign in / sign up
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? l10n.authSignIn : l10n.authSignUp,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.authOr,
                            style: TextStyle(color: context.textSubtle)),
                      ),
                      const Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _submitGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(l10n.authSignInWithGoogle),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
