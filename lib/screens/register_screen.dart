import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fake_data.dart';

// ── XORA colour tokens (mirrors subscription_screen.dart) ──────────────────
const _kBg1       = Color(0xFF0B0D2A);
const _kBg2       = Color(0xFF0E1245);
const _kBg3       = Color(0xFF1A1060);
const _kCardDark  = Color(0xFF0D1240);
const _kBorderDim = Color(0xFF1E2A6E);
const _kBorderPop = Color(0xFF3B52CC);
const _kBtnBlue1  = Color(0xFF2563EB);
const _kBtnBlue2  = Color(0xFF1E40AF);
const _kTeal      = Color(0xFF00E5CC);
const _kCheckBlue = Color(0xFF3B5BFF);
const _kLime      = Color(0xFFB8FF57);
const _kTextSub   = Color(0xFF8B9CC8);
const _kTextDim   = Color(0xFF5A6A9A);

// ── Dot-grid + radial glow background (same as subscription screen) ─────────
class _GridLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF1E2A6E).withOpacity(0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    // central glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2563EB).withOpacity(0.18),
          Colors.transparent,
        ],
        radius: 0.7,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Main screen widget ──────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  bool _showPassword  = false;
  bool _showConfirm   = false;
  bool _isLoading     = false;
  String? _planName;
  String? _storageLabel;
  Color   _planAccent = _kBtnBlue1;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // Focus nodes to drive border glow
  final _nameFocus      = FocusNode();
  final _usernameFocus  = FocusNode();
  final _emailFocus     = FocusNode();
  final _passwordFocus  = FocusNode();
  final _confirmFocus   = FocusNode();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _loadPlan();

    for (final fn in [_nameFocus, _usernameFocus, _emailFocus,
                      _passwordFocus, _confirmFocus]) {
      fn.addListener(() => setState(() {}));
    }
  }

  Future<void> _loadPlan() async {
    final prefs  = await SharedPreferences.getInstance();
    final planId = prefs.getString('plan_id') ?? 'basic';
    final plan   = subscriptionPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => subscriptionPlans[1],
    );
    if (mounted) {
      setState(() {
        _planName     = plan.name;
        _storageLabel = plan.storageLabel;
        // keep accent near XORA blue regardless of plan
        _planAccent = _kBtnBlue1;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_nameCtrl, _usernameCtrl, _emailCtrl,
                     _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    for (final fn in [_nameFocus, _usernameFocus, _emailFocus,
                      _passwordFocus, _confirmFocus]) {
      fn.dispose();
    }
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────
  String? _validateUsername(String? v) {
    if (v == null || v.isEmpty) return 'Username is required';
    if (v.length < 3) return 'At least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v)) {
      return 'Only letters, numbers, _ and . allowed';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _onCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1400));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('username',     _usernameCtrl.text.trim());
    await prefs.setString('display_name', _nameCtrl.text.trim());
    await prefs.setString('email',        _emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    await _showSuccessDialog();
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBg2, _kBg3],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorderPop.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: _kBtnBlue1.withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with glow ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kBtnBlue1, _kCheckBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kBtnBlue1.withOpacity(0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${_nameCtrl.text.trim().split(' ').first}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account is ready.\nEnjoy your ${_storageLabel ?? ''} of storage!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: _kTextSub, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBtnBlue1, _kBtnBlue2],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kBtnBlue1.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "Let's Go!",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
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

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg1,
      body: Stack(
        children: [
          // Dot-grid background
          Positioned.fill(
            child: CustomPaint(painter: _GridLinePainter()),
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kBg1, _kBg2, _kBg3],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      if (_planName != null) ...[
                        _buildPlanBadge(),
                        const SizedBox(height: 28),
                      ],
                      _buildForm(),
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kCardDark,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorderDim, width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 15, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 20),

        // Accent line
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kTeal, _kCheckBlue]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set up your username and password',
          style: TextStyle(fontSize: 14, color: _kTextSub),
        ),
      ],
    );
  }

  // ── Plan badge ──────────────────────────────────────────────────────────────
  Widget _buildPlanBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderPop.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: _kBtnBlue1.withOpacity(0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [_kBtnBlue1, _kCheckBlue]),
            ),
            child: const Icon(Icons.cloud_done_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            '$_planName Plan · $_storageLabel storage',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kLime.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: _kLime.withOpacity(0.3), width: 1),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                  color: _kLime,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Full Name'),
          _darkField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            hint: 'e.g. Riya Sharma',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 20),

          _label('Username'),
          _darkField(
            controller: _usernameCtrl,
            focusNode: _usernameFocus,
            hint: 'e.g. riya_sharma',
            icon: Icons.alternate_email_rounded,
            prefix: '@',
            validator: _validateUsername,
          ),
          const SizedBox(height: 20),

          _label('Email Address'),
          _darkField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 20),

          _label('Password'),
          _darkField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            hint: '6+ characters',
            icon: Icons.lock_outline_rounded,
            obscure: !_showPassword,
            suffixIcon: _eyeIcon(_showPassword,
                () => setState(() => _showPassword = !_showPassword)),
            validator: _validatePassword,
          ),
          const SizedBox(height: 20),

          _label('Confirm Password'),
          _darkField(
            controller: _confirmCtrl,
            focusNode: _confirmFocus,
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: !_showConfirm,
            suffixIcon: _eyeIcon(_showConfirm,
                () => setState(() => _showConfirm = !_showConfirm)),
            validator: _validateConfirm,
          ),
          const SizedBox(height: 36),

          // ── CTA button
          _buildCreateButton(),
          const SizedBox(height: 24),

          // ── Sign-in link
          Center(
            child: GestureDetector(
              onTap: _showSignInSheet,
              child: RichText(
                text: const TextSpan(
                  text: 'Already have an account?  ',
                  style: TextStyle(color: _kTextSub, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: _kTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_kBtnBlue1, _kBtnBlue2]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kBtnBlue1.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: _isLoading ? null : _onCreateAccount,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Dark input field helper ─────────────────────────────────────────────────
  Widget _darkField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    String? prefix,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? _kBorderPop.withOpacity(0.9)
              : _kBorderDim.withOpacity(0.7),
          width: focused ? 1.5 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _kBtnBlue1.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: _kTextDim, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: _kTextSub),
          prefixText: prefix,
          prefixStyle:
              const TextStyle(color: _kTextSub, fontSize: 15),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: _kCardDark,
          errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFFF6B6B), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _eyeIcon(bool visible, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        visible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: 20,
        color: _kTextSub,
      ),
      onPressed: onTap,
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kTextSub,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ── Sign-in bottom sheet (dark themed) ────────────────────────────────────
  void _showSignInSheet() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBg2, _kBg3],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: _kBorderPop, width: 1),
            left: BorderSide(color: _kBorderDim, width: 1),
            right: BorderSide(color: _kBorderDim, width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kTeal, _kCheckBlue]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kTeal, _kCheckBlue]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to continue',
              style: TextStyle(fontSize: 13, color: _kTextSub),
            ),
            const SizedBox(height: 24),

            // Username field
            _sheetField(usernameCtrl, 'Username', Icons.alternate_email_rounded),
            const SizedBox(height: 14),

            // Password field
            _sheetField(passwordCtrl, 'Password', Icons.lock_outline_rounded,
                obscure: true),
            const SizedBox(height: 24),

            // Sign-in button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kBtnBlue1, _kBtnBlue2]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kBtnBlue1.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final saved = prefs.getString('username') ?? '';
                    if (saved.isNotEmpty &&
                        saved.toLowerCase() ==
                            usernameCtrl.text.trim().toLowerCase()) {
                      await prefs.setBool('is_logged_in', true);
                      if (!mounted) return;
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Invalid credentials'),
                          backgroundColor: _kBg2,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextDim, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: _kTextSub),
        filled: true,
        fillColor: _kCardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorderDim, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorderDim, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorderPop, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
