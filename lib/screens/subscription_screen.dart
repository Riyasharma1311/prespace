import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fake_data.dart';

// ─── Color tokens (XORA-inspired dark navy palette) ──────────────────────────
const _kBg1        = Color(0xFF0B0D2A);
const _kBg2        = Color(0xFF0E1245);
const _kBg3        = Color(0xFF1A1060);
const _kCardDark   = Color(0xFF0D1240);
const _kCardPop    = Color(0xFF111A52);
const _kBorderDim  = Color(0xFF1E2D6E);
const _kBorderPop  = Color(0xFF3B52CC);
const _kBtnBlue1   = Color(0xFF2563EB);
const _kBtnBlue2   = Color(0xFF1E40AF);
const _kLime       = Color(0xFFB8FF57);
const _kTeal       = Color(0xFF00E5CC);
const _kCheckBlue  = Color(0xFF3B5BFF);
const _kBadgeBg    = Color(0xFF162050);
const _kBadgeBdr   = Color(0xFF2A3F8F);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  bool _isYearly = false;
  bool _isLoading = false;
  late PageController _pageCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: _selectedIndex, viewportFraction: 0.80);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  double _getPrice(SubscriptionPlan plan) {
    if (plan.monthlyPrice == 0) return 0;
    return _isYearly
        ? double.parse((plan.monthlyPrice * 12 * 0.75).toStringAsFixed(2))
        : plan.monthlyPrice;
  }

  Future<void> _onContinue() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    final plan = subscriptionPlans[_selectedIndex];
    await prefs.setBool('has_subscription', true);
    await prefs.setString('plan_id', plan.id);
    await prefs.setString('plan_name', plan.name);
    await prefs.setInt('storage_gb', plan.storageGB);
    await prefs.setDouble('plan_price', _getPrice(plan));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kBg3, _kBg1, _kBg2, _kBg1],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // ── Decorative grid lines (subtle, like the reference)
          const _GridPainter(),
          // ── Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildToggle(),
                  const SizedBox(height: 4),
                  Expanded(child: _buildPagedCards()),
                  _buildDotIndicator(),
                  _buildContinueButton(),
                  _buildLimitedOffer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: "Flexible pricing…" ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
      child: Column(
        children: [
          // Brand row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kTeal, _kBtnBlue1]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'PHOTOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Flexible pricing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const Text(
            'for teams of all sizes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly / Annual toggle ─────────────────────────────────────────────────

  Widget _buildToggle() {
    return Container(
      height: 44,
      width: 230,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderDim, width: 1),
      ),
      child: Stack(
        children: [
          // sliding pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: _isYearly ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 109,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kBtnBlue1, _kBtnBlue2],
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: _kBtnBlue1.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isYearly = false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'MONTHLY',
                      style: TextStyle(
                        color: !_isYearly ? Colors.white : Colors.white.withOpacity(0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isYearly = true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'ANNUAL',
                      style: TextStyle(
                        color: _isYearly ? Colors.white : Colors.white.withOpacity(0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Paged Cards ─────────────────────────────────────────────────────────────

  Widget _buildPagedCards() {
    return PageView.builder(
      controller: _pageCtrl,
      onPageChanged: (i) => setState(() => _selectedIndex = i),
      itemCount: subscriptionPlans.length,
      itemBuilder: (_, i) {
        final isPopular = i == _selectedIndex;
        return AnimatedScale(
          scale: isPopular ? 1.0 : 0.93,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _XoraCard(
            plan: subscriptionPlans[i],
            isPopular: isPopular,
            price: _getPrice(subscriptionPlans[i]),
            isYearly: _isYearly,
            onGetStarted: _onContinue,
          ),
        );
      },
    );
  }

  // ── Dot Indicator ───────────────────────────────────────────────────────────

  Widget _buildDotIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(subscriptionPlans.length, (i) {
          final active = i == _selectedIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [_kTeal, _kBtnBlue1])
                  : null,
              color: active ? null : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  // ── Continue Button ──────────────────────────────────────────────────────────

  Widget _buildContinueButton() {
    final plan = subscriptionPlans[_selectedIndex];
    final price = _getPrice(plan);
    final label = plan.monthlyPrice == 0
        ? 'Get Started Free'
        : 'Continue · \$${price.toStringAsFixed(2)}/${_isYearly ? 'yr' : 'mo'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kBtnBlue1, _kBtnBlue2],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _kBtnBlue1.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        subscriptionPlans[_selectedIndex].icon,
                        color: Colors.white, size: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Limited offer footer ─────────────────────────────────────────────────────

  Widget _buildLimitedOffer() {
    return Padding(
      padding: EdgeInsets.only(
          top: 10, bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 28, height: 1, color: Colors.white.withOpacity(0.18)),
          const SizedBox(width: 10),
          Text(
            _isYearly ? '25% off on annual plans' : 'Limited time offer',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                letterSpacing: 0.5),
          ),
          const SizedBox(width: 10),
          Container(width: 28, height: 1, color: Colors.white.withOpacity(0.18)),
        ],
      ),
    );
  }
}

// ─── XORA-style Card ──────────────────────────────────────────────────────────

class _XoraCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isPopular;
  final double price;
  final bool isYearly;
  final VoidCallback onGetStarted;

  const _XoraCard({
    required this.plan,
    required this.isPopular,
    required this.price,
    required this.isYearly,
    required this.onGetStarted,
  });

  // Unique icon for each plan tier
  IconData get _planIcon {
    switch (plan.id) {
      case 'free':   return Icons.radio_button_unchecked;
      case 'basic':  return Icons.circle_outlined;
      case 'standard': return Icons.change_history; // triangle-ish
      default:        return Icons.hexagon_outlined;
    }
  }

  Color get _planAccentColor {
    switch (plan.id) {
      case 'free':     return const Color(0xFF3B82F6);
      case 'basic':    return const Color(0xFF6366F1);
      case 'standard': return _kLime;
      default:         return _kTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _planAccentColor;

    return Padding(
      // extra top padding to make room for the floating icon
      padding: const EdgeInsets.fromLTRB(10, 38, 10, 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card body
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isPopular ? _kCardPop : _kCardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isPopular ? _kBorderPop : _kBorderDim,
                    width: isPopular ? 1.5 : 1,
                  ),
                  boxShadow: isPopular
                      ? [
                          BoxShadow(
                            color: _kBtnBlue1.withOpacity(0.25),
                            blurRadius: 32,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 42, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Plan badge pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBadgeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBadgeBdr, width: 1),
                        ),
                        child: Text(
                          plan.name.toUpperCase(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: isPopular
                                    ? accentColor.withOpacity(0.85)
                                    : Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            price == 0 ? '0' : price.toStringAsFixed(2),
                            style: TextStyle(
                              color: isPopular ? accentColor : Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              price == 0 ? '' : isYearly ? '/ YR' : '/ MO',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Subtitle
                      Text(
                        price == 0
                            ? 'Free forever'
                            : isPopular
                                ? 'Most popular plan'
                                : plan.storageLabel + ' storage',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Divider
                      Container(height: 1, color: _kBorderDim),

                      const SizedBox(height: 18),

                      // ── Features
                      ...plan.features.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Filled circle checkmark
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _kCheckBlue.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kCheckBlue.withOpacity(0.4),
                                      width: 1),
                                ),
                                child: const Icon(Icons.check,
                                    size: 11, color: _kCheckBlue),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.78),
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── GET STARTED button
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kBtnBlue1, _kBtnBlue2],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _kBtnBlue1.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_planIcon,
                                    color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'GET STARTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating icon circle at top (overflows above card)
          Positioned(
            top: -2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPopular
                        ? [_kBg2, const Color(0xFF1E2A70)]
                        : [_kBg1, _kCardDark],
                  ),
                  border: Border.all(
                    color: isPopular ? _kBorderPop : _kBorderDim,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPopular ? _kBtnBlue1 : Colors.black)
                          .withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                          color: accentColor.withOpacity(0.6), width: 1.5),
                    ),
                    child: Icon(_planIcon, color: accentColor, size: 15),
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

// ─── Subtle Grid Background Painter ──────────────────────────────────────────

class _GridPainter extends StatelessWidget {
  const _GridPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridLinePainter(),
    );
  }
}

class _GridLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D6E).withOpacity(0.35)
      ..strokeWidth = 0.5;

    // Horizontal lines
    const spacing = 40.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Central radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2563EB).withOpacity(0.12),
          Colors.transparent,
        ],
        radius: 0.6,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.35),
        radius: size.width * 0.75,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.35),
      size.width * 0.75,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
