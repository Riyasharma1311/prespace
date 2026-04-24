import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../fake_data.dart';

// ── Colour tokens (mirror main_shell) ─────────────────────────────────────
const _kBg      = Color(0xFF080B1E);
const _kCard    = Color(0xFF111840);
const _kBorderD = Color(0xFF1A2460);
const _kBorderP = Color(0xFF3B52CC);
const _kBlue1   = Color(0xFF2563EB);
const _kBlue2   = Color(0xFF1E40AF);
const _kTeal    = Color(0xFF00E5CC);
const _kAccent  = Color(0xFF3B5BFF);
const _kTextW   = Colors.white;
const _kTextS   = Color(0xFF8B9CC8);
const _kTextD   = Color(0xFF4A5880);

class PhotoDetailScreen extends StatefulWidget {
  final FakePhoto photo;
  const PhotoDetailScreen({super.key, required this.photo});
  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen>
    with TickerProviderStateMixin {
  bool _showUI    = true;
  bool _isFavorite = false;

  late AnimationController _uiCtrl;
  late Animation<double>   _uiAnim;
  late AnimationController _favCtrl;
  late Animation<double>   _favAnim;

  @override
  void initState() {
    super.initState();
    _uiCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _uiAnim  = CurvedAnimation(parent: _uiCtrl, curve: Curves.easeOut);
    _uiCtrl.value = 1.0;

    _favCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _favAnim = CurvedAnimation(parent: _favCtrl, curve: Curves.elasticOut);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _uiCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      _uiCtrl.forward();
    } else {
      _uiCtrl.reverse();
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _favCtrl.forward(from: 0);
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Full-screen photo ──────────────────────────────────────────
            Hero(
              tag: 'photo_${widget.photo.id}',
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      widget.photo.color.withOpacity(0.9),
                      Color.lerp(widget.photo.color, Colors.black, 0.6)!,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.photo.icon,
                    size: 120,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),

            // ── Subtle ambient glow ────────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Top bar ────────────────────────────────────────────────────
            FadeTransition(
              opacity: _uiAnim,
              child: _TopBar(
                photo: widget.photo,
                onBack: () => Navigator.pop(context),
                onMore: () => _showMoreSheet(context),
              ),
            ),

            // ── Info + action bar ──────────────────────────────────────────
            FadeTransition(
              opacity: _uiAnim,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _BottomBar(
                  photo: widget.photo,
                  isFavorite: _isFavorite,
                  favAnim: _favAnim,
                  onFavorite: _toggleFavorite,
                  onDelete: () => _confirmDelete(context),
                  formatDate: _formatDate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── More options bottom sheet ───────────────────────────────────────────
  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xE0111840),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top:   BorderSide(color: _kBorderP, width: 1),
                left:  BorderSide(color: _kBorderD, width: 1),
                right: BorderSide(color: _kBorderD, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                ...[
                  ('Add to album',       Icons.add_to_photos_outlined,   _kTeal),
                  ('Use as wallpaper',   Icons.wallpaper_outlined,        _kBlue1),
                  ('Photo info',         Icons.info_outline_rounded,      _kTextS),
                  ('Print',              Icons.print_outlined,            _kTextS),
                ].map((item) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.$3.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$2, color: item.$3, size: 18),
                  ),
                  title: Text(item.$1,
                      style: const TextStyle(
                          color: _kTextW, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right,
                      color: _kTextD, size: 18),
                  onTap: () => Navigator.pop(context),
                )),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
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
            border: Border.all(
                color: const Color(0xFFDC2626).withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444), size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Delete photo?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextW)),
              const SizedBox(height: 8),
              const Text(
                  'This photo will be moved to Bin\nand deleted after 60 days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: _kTextS, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextS,
                        side: const BorderSide(color: _kBorderD),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDC2626),
                              Color(0xFFB91C1C)
                            ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Delete'),
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
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final FakePhoto photo;
  final VoidCallback onBack;
  final VoidCallback onMore;
  const _TopBar(
      {required this.photo, required this.onBack, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Back button
                _GlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const Spacer(),
                // More button
                _GlassButton(
                  icon: Icons.more_vert_rounded,
                  onTap: onMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final FakePhoto photo;
  final bool isFavorite;
  final Animation<double> favAnim;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDate;

  const _BottomBar({
    required this.photo,
    required this.isFavorite,
    required this.favAnim,
    required this.onFavorite,
    required this.onDelete,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Info row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: _kTextS, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          formatDate(photo.date),
                          style: const TextStyle(
                              color: _kTextS, fontSize: 12),
                        ),
                        if (photo.location != null) ...[
                          const SizedBox(width: 14),
                          const Icon(Icons.location_on_outlined,
                              color: _kTextS, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            photo.location!,
                            style: const TextStyle(
                                color: _kTextS, fontSize: 12),
                          ),
                        ],
                        const Spacer(),
                        const Text('Taken with Camera',
                            style: TextStyle(
                                color: _kTextD, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Action pill ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111840).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: _kBorderD.withOpacity(0.8), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionBtn(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: _kTeal,
                          onTap: () {},
                        ),
                        _AnimatedFavBtn(
                          isFavorite: isFavorite,
                          animation: favAnim,
                          onTap: onFavorite,
                        ),
                        _ActionBtn(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: _kBlue1,
                          onTap: () {},
                        ),
                        _ActionBtn(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: const Color(0xFFEF4444),
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glass icon button ───────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Action button ───────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Animated favourite button ───────────────────────────────────────────────
class _AnimatedFavBtn extends StatelessWidget {
  final bool isFavorite;
  final Animation<double> animation;
  final VoidCallback onTap;
  const _AnimatedFavBtn(
      {required this.isFavorite,
      required this.animation,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFEF4444);
    const inactiveColor = Color(0xFF8B9CC8);
    final color = isFavorite ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0)
                  .animate(animation),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isFavorite ? 'Saved' : 'Favourite',
              style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
