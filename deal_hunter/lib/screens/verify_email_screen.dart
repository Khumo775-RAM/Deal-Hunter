import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.username,
    required this.email,
  });

  final String username;
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  final _auth = AuthService();

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _code;
    if (code.length < 6) {
      setState(() => _error = 'Enter all 6 digits.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await _auth.verifyEmail(widget.username, code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Please sign in.'),
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
        _isVerifying = false;
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await _auth.resendVerification(widget.username);
      if (!mounted) return;
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent — check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    setState(() => _isResending = false);
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (_code.length == 6) _verify();
  }

  void _onKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
    }
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
                  child: Icon(Icons.mark_email_unread_outlined,
                      color: c.accent, size: 48),
                ),
                const SizedBox(height: 24),
                Text('Verify your email',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  'We sent a 6-digit code to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 36),

                // 6-digit boxes
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
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
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
                const SizedBox(height: 16),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isVerifying
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: c.onAccent, strokeWidth: 2))
                        : Text('Verify Email',
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
                      onTap: _isResending ? null : _resend,
                      child: _isResending
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: c.accent, strokeWidth: 2))
                          : Text('Resend code',
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
}
