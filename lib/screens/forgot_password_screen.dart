import 'dart:async';
import 'package:flutter/material.dart';
import '../services/registration_service.dart';
import '../utils/app_colors.dart';

/// Forgot Password screen, styled to match Login/Registration:
/// background image + logo + white card. Username is checked live
/// as the user types (debounced); a green message confirms a match,
/// a red message flags no match. Reset is only enabled once the
/// username is confirmed valid and both password fields agree.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _UsernameCheckState { idle, checking, valid, invalid }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameC = TextEditingController();
  final _newPassC = TextEditingController();
  final _confirmC = TextEditingController();

  _UsernameCheckState _usernameState = _UsernameCheckState.idle;
  Timer? _debounce;

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameC.dispose();
    _newPassC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() => _usernameState = _UsernameCheckState.idle);
      return;
    }

    setState(() => _usernameState = _UsernameCheckState.checking);

    // Debounce so it doesn't re-check on every single keystroke.
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final valid = await RegistrationService.isUsernameValid(value);
      if (!mounted) return;
      setState(() {
        _usernameState = valid ? _UsernameCheckState.valid : _UsernameCheckState.invalid;
      });
    });
  }

  bool get _canSubmit {
    return _usernameState == _UsernameCheckState.valid &&
        _newPassC.text.length >= 6 &&
        _confirmC.text == _newPassC.text;
  }

  Future<void> _handleReset() async {
    setState(() => _formError = null);

    if (_usernameState != _UsernameCheckState.valid) {
      setState(() => _formError = 'Enter a valid registered username');
      return;
    }
    if (_newPassC.text.length < 6) {
      setState(() => _formError = 'Password must be at least 6 characters');
      return;
    }
    if (_newPassC.text != _confirmC.text) {
      setState(() => _formError = 'Passwords do not match');
      return;
    }

    setState(() => _submitting = true);
    await RegistrationService.resetPassword(_newPassC.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 44),
        title: const Text('Password Changed Successfully!', textAlign: TextAlign.center),
        content: const Text(
          'Your password has been updated.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pop(context); // back to login
              },
              child: const Text('OK'),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Widget _iconTile(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primaryDark, size: 22),
    );
  }

  Widget _usernameHint() {
    switch (_usernameState) {
      case _UsernameCheckState.checking:
        return const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Text('Checking\u2026', style: TextStyle(fontSize: 12, color: Colors.black45)),
        );
      case _UsernameCheckState.valid:
        return const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.success),
              SizedBox(width: 4),
              Text('Username found', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case _UsernameCheckState.invalid:
        return const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 14, color: AppColors.error),
              SizedBox(width: 4),
              Text('Username not found', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case _UsernameCheckState.idle:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final cardMaxWidth = isTablet ? 520.0 : double.infinity;
    final logoSize = mq.size.width * (isTablet ? 0.30 : 0.42);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgroundIMG.png', fit: BoxFit.cover),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 18, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 4),
                      const Text('Forgot Password?',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your username then choose a new password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _usernameC,
                              onChanged: _onUsernameChanged,
                              decoration: InputDecoration(labelText: 'Username', prefixIcon: _iconTile(Icons.person_outline)),
                            ),
                            Align(alignment: Alignment.centerLeft, child: _usernameHint()),

                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPassC,
                              obscureText: _obscureNew,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: _iconTile(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmC,
                              obscureText: _obscureConfirm,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: _iconTile(Icons.lock_reset),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                            ),

                            if (_formError != null) ...[
                              const SizedBox(height: 12),
                              Text(_formError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ],

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  disabledBackgroundColor: Colors.black12,
                                ),
                                onPressed: (_canSubmit && !_submitting) ? _handleReset : null,
                                child: _submitting
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Reset Password', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}