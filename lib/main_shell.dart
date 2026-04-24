import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_data.dart';
import 'screens/photo_detail_screen.dart';

// ── Midnight Gallery colour tokens ─────────────────────────────────────────
const _kBg       = Color(0xFF080B1E);
const _kSurface  = Color(0xFF0C1030);
const _kCard     = Color(0xFF111840);
const _kCardAlt  = Color(0xFF0F1535);
const _kBorderD  = Color(0xFF1A2460);
const _kBorderP  = Color(0xFF3B52CC);
const _kBlue1    = Color(0xFF2563EB);
const _kBlue2    = Color(0xFF1E40AF);
const _kTeal     = Color(0xFF00E5CC);
const _kAccent   = Color(0xFF3B5BFF);
const _kLime     = Color(0xFFB8FF57);
const _kTextW    = Colors.white;
const _kTextS    = Color(0xFF8B9CC8);
const _kTextD    = Color(0xFF4A5880);

// ── Time-based greeting ─────────────────────────────────────────────────────
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String _greetingEmoji() {
  final h = DateTime.now().hour;
  if (h < 12) return '☀️';
  if (h < 17) return '🌤️';
  return '🌙';
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SHELL
// ═══════════════════════════════════════════════════════════════════════════
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _username  = '';
  String _planName  = '';

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadUser();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('display_name') ?? 'User';
        _planName = prefs.getString('plan_name') ?? '';
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kCard, Color(0xFF1A1060)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorderP.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sign out?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kTextW)),
              const SizedBox(height: 10),
              const Text(
                  'You will need to sign in again\nto access your photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _kTextS)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextS,
                        side: const BorderSide(color: _kBorderD),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Sign out'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/splash');
    }
  }

  void _onTabTap(int i) {
    if (i == _currentIndex) return;
    _fadeCtrl.forward(from: 0);
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PhotosScreen(
          username: _username, planName: _planName, onLogout: _logout),
      const SearchScreen(),
      const LibraryScreen(),
      UtilitiesScreen(
          username: _username, planName: _planName, onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: _FloatingNav(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

// ── Floating Pill Navigation Bar ────────────────────────────────────────────
class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.photo_outlined,       activeIcon: Icons.photo_rounded,          label: 'Photos'),
    (icon: Icons.search_outlined,      activeIcon: Icons.search_rounded,         label: 'Search'),
    (icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library_rounded, label: 'Library'),
    (icon: Icons.tune_outlined,        activeIcon: Icons.tune_rounded,           label: 'Utilities'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: _kBg,
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottom > 0 ? bottom : 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF111840).withOpacity(0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _kBorderD, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _kBlue1.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final active = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: active
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kBlue1, _kAccent]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue1.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 20,
                          color: active ? Colors.white : _kTextD,
                        ),
                        if (active) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHOTOS SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class PhotosScreen extends StatefulWidget {
  final String username;
  final String planName;
  final VoidCallback onLogout;
  const PhotosScreen(
      {super.key,
      required this.username,
      required this.planName,
      required this.onLogout});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 10;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Map<String, List<FakePhoto>> get _grouped {
    final now = DateTime.now();
    final Map<String, List<FakePhoto>> g = {};
    for (final p in allPhotos) {
      final diff = now.difference(p.date).inDays;
      String label;
      if (diff == 0)       label = 'Today';
      else if (diff == 1)  label = 'Yesterday';
      else if (diff < 7)   label = '$diff days ago';
      else if (diff < 30)  { final w = diff ~/ 7; label = '$w week${w > 1 ? 's' : ''} ago'; }
      else {
        const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        label = '${m[p.date.month - 1]} ${p.date.year}';
      }
      g.putIfAbsent(label, () => []).add(p);
    }
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final first = widget.username.trim().split(' ').first;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: _scrolled
                ? _kBg.withOpacity(0.96)
                : Colors.transparent,
            elevation: 0,
            title: AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Text('Photos',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextW)),
            ),
            actions: [
              _UserAvatar(
                  username: widget.username, onLogout: widget.onLogout),
              const SizedBox(width: 4),
            ],
          ),

          // ── Greeting header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _greetingEmoji(),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_greeting()}, $first',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _kTextW,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${allPhotos.length} photos backed up',
                    style: const TextStyle(fontSize: 13, color: _kTextS),
                  ),
                ],
              ),
            ),
          ),

          // ── Memories ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _MemoriesSection()),

          // ── Photo groups ─────────────────────────────────────────────────
          ...groups.entries.expand((e) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kTeal, _kBlue1],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kTextS,
                                letterSpacing: 0.2)),
                        const Spacer(),
                        Text('${e.value.length} photos',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextD)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PhotoTile(photo: e.value[i]),
                      childCount: e.value.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                    ),
                  ),
                ),
              ]),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Memories carousel ───────────────────────────────────────────────────────
class _MemoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> memories = const [
    {'title': '3 Years Ago in Paris',  'subtitle': 'Jun 2022 · 24 photos', 'color': Color(0xFF1A3A6E), 'icon': Icons.location_city},
    {'title': 'Summer Highlights',     'subtitle': 'Aug 2023 · 18 photos', 'color': Color(0xFF1E3A52), 'icon': Icons.wb_sunny_outlined},
    {'title': 'Family Weekend',        'subtitle': 'Dec 2023 · 31 photos', 'color': Color(0xFF1A3A2E), 'icon': Icons.people_outline},
    {'title': 'Road Trip 2024',        'subtitle': 'Mar 2024 · 47 photos', 'color': Color(0xFF3A2A1E), 'icon': Icons.directions_car_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              const Text('Memories',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextW)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorderD),
                ),
                child: const Text('View all',
                    style: TextStyle(
                        color: _kTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: memories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final m = memories[i];
              final c = m['color'] as Color;
              return Container(
                width: 155,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kBorderD.withOpacity(0.6), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topRight,
                            radius: 1.3,
                            colors: [
                              c.withOpacity(0.9),
                              _kCard,
                            ],
                          ),
                        ),
                      ),
                      // Large faded icon
                      Positioned(
                        right: -16,
                        top: 10,
                        child: Icon(
                          m['icon'] as IconData,
                          size: 88,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      // Dot grid pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.15,
                          child: CustomPaint(
                              painter: _SmallDotPainter()),
                        ),
                      ),
                      // Bottom gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Play badge
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1),
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      // Text content
                      Positioned(
                        bottom: 14, left: 12, right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title']!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3)),
                            const SizedBox(height: 3),
                            Text(m['subtitle']!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SmallDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..strokeWidth = 1;
    const s = 20.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Photo Tile ──────────────────────────────────────────────────────────────
class _PhotoTile extends StatelessWidget {
  final FakePhoto photo;
  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => PhotoDetailScreen(photo: photo),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 220),
        ),
      ),
      child: Hero(
        tag: 'photo_${photo.id}',
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                photo.color.withOpacity(0.9),
                Color.lerp(photo.color, _kCard, 0.45)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(photo.icon,
                color: Colors.white.withOpacity(0.28), size: 28),
          ),
        ),
      ),
    );
  }
}

// ── User Avatar ─────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  const _UserAvatar({required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initials = username.isNotEmpty
        ? username.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showAccountSheet(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [_kBlue1, _kAccent]),
            boxShadow: [
              BoxShadow(
                color: _kBlue1.withOpacity(0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }

  void _showAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kCard, Color(0xFF0E1245)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top:   BorderSide(color: _kBorderP, width: 1),
            left:  BorderSide(color: _kBorderD, width: 1),
            right: BorderSide(color: _kBorderD, width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kTeal, _kAccent]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_kBlue1, _kAccent]),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue1.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(username,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kTextW)),
            const SizedBox(height: 4),
            const Text('Manage your account',
                style: TextStyle(fontSize: 12, color: _kTextS)),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _accountTile(
                    context,
                    icon: Icons.account_circle_outlined,
                    iconColor: _kTeal,
                    label: 'Manage Account',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  _accountTile(
                    context,
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFEF4444),
                    label: 'Sign out',
                    labelColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    Color labelColor = _kTextW,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorderD, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: _kTextD, size: 18),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _searching = false;

  final List<Map<String, dynamic>> categories = [
    {'label': 'People',      'icon': Icons.face_retouching_natural, 'color': Color(0xFF2563EB)},
    {'label': 'Places',      'icon': Icons.explore_outlined,        'color': Color(0xFF059669)},
    {'label': 'Things',      'icon': Icons.category_outlined,       'color': Color(0xFFD97706)},
    {'label': 'Videos',      'icon': Icons.videocam_outlined,       'color': Color(0xFFDC2626)},
    {'label': 'Selfies',     'icon': Icons.camera_front_outlined,   'color': Color(0xFF7C3AED)},
    {'label': 'Screenshots', 'icon': Icons.screenshot_outlined,     'color': Color(0xFF0891B2)},
    {'label': 'Favourites',  'icon': Icons.favorite_outline,        'color': Color(0xFFE11D48)},
    {'label': 'Documents',   'icon': Icons.description_outlined,    'color': Color(0xFF00E5CC)},
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kTeal, _kBlue1]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Search',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _kTextW,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _searching
                          ? _kBorderP.withOpacity(0.8)
                          : _kBorderD,
                      width: _searching ? 1.5 : 1),
                  boxShadow: _searching
                      ? [
                          BoxShadow(
                            color: _kBlue1.withOpacity(0.15),
                            blurRadius: 16,
                          )
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: _kTextW, fontSize: 15),
                  onChanged: (v) =>
                      setState(() => _searching = v.isNotEmpty),
                  decoration: InputDecoration(
                    hintText: 'Search your photos…',
                    hintStyle: const TextStyle(
                        color: _kTextD, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: _kTextS, size: 22),
                    suffixIcon: _searching
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: _kTextS, size: 20),
                            onPressed: () {
                              _ctrl.clear();
                              setState(() => _searching = false);
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Results / Browse
            Expanded(
              child: _searching
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 3,
                              mainAxisSpacing: 3),
                      itemCount: 12,
                      itemBuilder: (_, i) =>
                          _PhotoTile(photo: allPhotos[i % allPhotos.length]),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Browse',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextW)),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 2.5),
                            itemCount: categories.length,
                            itemBuilder: (_, i) {
                              final cat = categories[i];
                              final c = cat['color'] as Color;
                              return Container(
                                decoration: BoxDecoration(
                                  color: _kCard,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                      color: c.withOpacity(0.25),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 14),
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                          cat['icon'] as IconData,
                                          color: c,
                                          size: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(cat['label'] as String,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _kTextW)),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          const Text('Recent',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextW)),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 6,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final p =
                                    allPhotos[i % allPhotos.length];
                                return ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Container(
                                    width: 90,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          p.color.withOpacity(0.9),
                                          Color.lerp(
                                              p.color, _kCard, 0.5)!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(p.icon,
                                        color: Colors.white
                                            .withOpacity(0.3),
                                        size: 28),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIBRARY SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            backgroundColor: _kBg,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kTeal, _kBlue1]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Library',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kTextW)),
              ],
            ),
          ),

          // ── Quick tiles ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                        icon: Icons.favorite_rounded,
                        label: 'Favourites',
                        count: '24',
                        color: const Color(0xFFE11D48)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                        icon: Icons.archive_rounded,
                        label: 'Archive',
                        count: '12',
                        color: _kTextS),
                  ),
                ],
              ),
            ),
          ),

          // ── Albums header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                children: [
                  Text('Albums',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextW)),
                  Spacer(),
                  Text('View all',
                      style: TextStyle(
                          color: _kTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // ── Album grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _AlbumCard(album: fakeAlbums[i]),
                childCount: fakeAlbums.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  const _QuickTile(
      {required this.icon,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kTextW)),
                Text(count,
                    style: const TextStyle(
                        fontSize: 11, color: _kTextS)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _kTextD, size: 16),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorderD, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient bg
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      album.color.withOpacity(0.85),
                      Color.lerp(album.color, _kCard, 0.55)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Large faded icon
              Positioned(
                right: -10,
                top: 10,
                child: Icon(album.icon,
                    size: 70,
                    color: Colors.white.withOpacity(0.1)),
              ),
              // Bottom gradient + text
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // Centre icon
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Icon(album.icon,
                    size: 44,
                    color: Colors.white.withOpacity(0.55)),
              ),
              // Text
              Positioned(
                bottom: 14, left: 12, right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(album.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${album.count} items',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UTILITIES SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class UtilitiesScreen extends StatefulWidget {
  final String username;
  final String planName;
  final VoidCallback onLogout;
  const UtilitiesScreen(
      {super.key,
      required this.username,
      required this.planName,
      required this.onLogout});
  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen>
    with SingleTickerProviderStateMixin {
  int _storageGB = 15;
  String _planName = '';
  late AnimationController _storageCtrl;
  late Animation<double> _storageAnim;

  @override
  void initState() {
    super.initState();
    _storageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _storageAnim = CurvedAnimation(
        parent: _storageCtrl, curve: Curves.easeOut);
    _loadPlan();
  }

  @override
  void dispose() {
    _storageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _storageGB = prefs.getInt('storage_gb') ?? 15;
        _planName  = prefs.getString('plan_name') ?? 'Basic';
      });
      _storageCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usedFraction = 0.38;
    final usedGB = (_storageGB * usedFraction).toStringAsFixed(1);

    final utils = [
      {'title': 'Free up space',  'sub': 'Remove items already backed up', 'icon': Icons.storage_outlined,  'color': _kBlue1},
      {'title': 'Locked Folder',  'sub': 'Protect sensitive photos',       'icon': Icons.lock_outline,       'color': Color(0xFF059669)},
      {'title': 'Archive',        'sub': 'Hide photos from your grid',     'icon': Icons.archive_outlined,   'color': Color(0xFFD97706)},
      {'title': 'Bin',            'sub': 'Photos deleted after 60 days',   'icon': Icons.delete_outline,     'color': Color(0xFFDC2626)},
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            backgroundColor: _kBg,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kTeal, _kBlue1]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Utilities',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kTextW)),
              ],
            ),
            actions: [
              _UserAvatar(
                  username: widget.username, onLogout: widget.onLogout),
              const SizedBox(width: 4),
            ],
          ),

          // ── Storage card ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1A50), Color(0xFF1A1060)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _kBorderP.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue1.withOpacity(0.18),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kBlue1.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_done_rounded,
                              color: _kTeal, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_planName Plan',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextW)),
                            const Text('Cloud Storage',
                                style: TextStyle(
                                    fontSize: 11, color: _kTextS)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kLime.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _kLime.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$_storageGB GB',
                            style: const TextStyle(
                                color: _kLime,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Animated progress bar
                    AnimatedBuilder(
                      animation: _storageAnim,
                      builder: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: usedFraction *
                                      _storageAnim.value,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [_kTeal, _kBlue1]),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              _kTeal.withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('$usedGB GB used',
                                  style: const TextStyle(
                                      color: _kTextS, fontSize: 12)),
                              const Spacer(),
                              Text('$_storageGB GB total',
                                  style: const TextStyle(
                                      color: _kTextD, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kBlue1, _kBlue2]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18),
                          ),
                          child: const Text('Manage storage',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Section header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Text('Tools',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextW)),
            ),
          ),

          // ── Utility items
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final u = utils[i];
                  final c = u['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: c.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(u['icon'] as IconData,
                                color: c, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(u['title'] as String,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextW)),
                                const SizedBox(height: 2),
                                Text(u['sub'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _kTextS)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: _kTextD, size: 18),
                        ],
                      ),
                    ),
                  );
                },
                childCount: utils.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
