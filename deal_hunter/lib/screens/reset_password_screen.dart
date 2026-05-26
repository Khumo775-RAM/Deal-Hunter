import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final List<TextEditingController> _codeCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeNodes =
      List.generate(6, (_) => FocusNode());

  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _formKey       = GlobalKey<FormState>();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  String? _error;

  final _auth = AuthService();

  @override
  void dispose() {
    for (final c in _codeCtrls) c.dispose();
    for (final n in _codeNodes) n.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _code => _codeCtrls.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _codeNodes[index + 1].requestFocus();
    }
  }

  void _onKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _codeCtrls[index].text.isEmpty &&
        index > 0) {
      _codeNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_code.length < 6) {
      setState(() => _error = 'Enter all 6 digits of the reset code.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _auth.resetPassword(widget.email, _code, _passwordCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Password reset! Please sign in with your new password.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _resend() async {
    try {
      await _auth.forgotPassword(widget.email);
      for (final c in _codeCtrls) c.clear();
      _codeNodes[0].requestFocus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New reset code sent.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.accentSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline, color: c.accent, size: 48),
                ),
                const SizedBox(height: 24),
                Text('Reset Password',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  'Enter the code sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // 6-digit code boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      width: 46,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (e) => _onKeyPress(i, e),
                        child: TextFormField(
                          controller: _codeCtrls[i],
                          focusNode: _codeNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: c.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: c.accent, width: 2),
                            ),
                            counterText: '',
                          ),
                          onChanged: (v) => _onDigitEntered(i, v),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildPasswordField(
                        context: context,
                        controller: _passwordCtrl,
                        label: 'New password',
                        obscure: _obscurePass,
                        onToggle: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter a new password';
                          }
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        context: context,
                        controller: _confirmCtrl,
                        label: 'Confirm new password',
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: c.onAccent, strokeWidth: 2))
                        : Text('Reset Password',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.onAccent)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive it? ",
                        style: TextStyle(
                            color: c.textMuted, fontSize: 13)),
                    GestureDetector(
                      onTap: _resend,
                      child: Text('Resend code',
                          style: TextStyle(
                              color: c.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Code expires in 15 minutes',
                    style: TextStyle(color: c.textFaint, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    final c = context.colors;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textSecondary),
        prefixIcon: Icon(Icons.lock_outline, color: c.textMuted),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: c.textMuted,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }
}
