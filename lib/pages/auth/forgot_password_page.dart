import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// ENTRY POINT: ForgotPasswordPage (input email)
// ─────────────────────────────────────────────
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulasi request ke server
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpVerificationPage(email: _emailController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Back Button
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back_ios, size: 20),
                      ),
                    ),
                  ],
                ),

                // Konten center
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            80,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),

                          // Icon
                          const Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 64,
                              color: Color(0xFFFF5722),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Title
                          const Text(
                            'Forgot Password?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Don\'t worry! Enter your email and we\'ll\nsend you a reset code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Email Label
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF0F0F0),
                              hintText: 'example@email.com',
                              hintStyle: const TextStyle(color: Colors.black38),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          // Send Code Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              disabledBackgroundColor:
                                  const Color(0xFFFF5722).withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Send Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 24),

                          // Back to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Remember your password? ',
                                style: TextStyle(color: Colors.black54),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFFFF5722),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SCREEN 2: OTP Verification
// ─────────────────────────────────────────────
class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _hasError = false;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _tickDown();
  }

  void _tickDown() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (_resendCountdown > 1) {
      setState(() => _resendCountdown--);
      _tickDown();
    } else {
      setState(() {
        _resendCountdown = 0;
        _canResend = true;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    setState(() => _hasError = false);

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto verify when all 4 digits filled
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 4) {
      _handleVerify();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 4) return;

    setState(() => _isLoading = true);

    // Simulasi verifikasi — anggap kode benar jika bukan "0000"
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (code == '0000') {
      // Kode salah
      setState(() => _hasError = true);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } else {
      // Kode benar → success
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordSuccessPage()),
        (route) => route.isFirst,
      );
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final masked = name.length <= 3
        ? '${'*' * name.length}@$domain'
        : '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
    return masked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Back Button
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios, size: 20),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),

                        // Icon
                        const Center(
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 64,
                            color: Color(0xFFFF5722),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Check your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a 4-digit code to\n${_maskEmail(widget.email)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // OTP Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return _OtpBox(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              hasError: _hasError,
                              onChanged: (val) => _onOtpChanged(val, index),
                              onBackspace: () => _onBackspace(index),
                            );
                          }),
                        ),

                        if (_hasError) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Incorrect code. Please try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),

                        // Verify Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            disabledBackgroundColor:
                                const Color(0xFFFF5722).withOpacity(0.6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Verify Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Resend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive the code? ",
                              style: TextStyle(color: Colors.black54),
                            ),
                            _canResend
                                ? GestureDetector(
                                    onTap: () {
                                      for (final c in _controllers) c.clear();
                                      setState(() => _hasError = false);
                                      _startResendTimer();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Kode baru telah dikirim')),
                                      );
                                    },
                                    child: const Text(
                                      'Resend',
                                      style: TextStyle(
                                        color: Color(0xFFFF5722),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Resend in ${_resendCountdown}s',
                                    style:
                                        const TextStyle(color: Colors.black38),
                                  ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasError
                ? Colors.redAccent.withOpacity(0.08)
                : const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : const Color(0xFFFF5722),
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class ResetPasswordSuccessPage extends StatelessWidget {
  const ResetPasswordSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Color(0xFF4CAF50),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Password Reset\nSuccessful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password has been reset successfully.\nYou can now sign in with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // Back to Login Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
