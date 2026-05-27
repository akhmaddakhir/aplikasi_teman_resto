import 'package:flutter/material.dart';

class BottomNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _popAnim;
  int _prevIndex = 0;

  static const _kOrange = Color(0xFFFF4F0F);
  static const _kOrangeDark = Color(0xFFCC3300);

  static const _kBarH = 64.0;
  static const _kCircleD = 52.0;
  static const _kHMargin = 20.0;
  static const _kBMargin = 20.0;
  static const _kRadius = 20.0;
  static const _kNotchR = 38.0;

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ['Home', 'Search', 'Wishlist', 'Profile'];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..value = 1.0;
    _popAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void didUpdateWidget(BottomNavbar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sysBotPad = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barW = constraints.maxWidth - (_kHMargin * 2);
        final iW = barW / _icons.length;

        return Container(
          color: Colors.transparent,
          padding: EdgeInsets.fromLTRB(
              _kHMargin, 0, _kHMargin, _kBMargin + sysBotPad),
          child: AnimatedBuilder(
            animation: _popAnim,
            builder: (ctx, _) {
              final prevCx = iW * _prevIndex + iW / 2;
              final activeCx = iW * widget.currentIndex + iW / 2;
              final notchX = _lerp(prevCx, activeCx, _popAnim.value);

              return SizedBox(
                // FIX 1: hapus 35px ekstra di atas — circle overflow ke atas
                // via top negatif + Clip.none, jadi tidak ada kotak kosong
                height: _kBarH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── NAVBAR BACKGROUND ──
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: _kBarH,
                      child: CustomPaint(
                        painter: _NotchPainter(
                          notchX: notchX,
                          notchR: _kNotchR,
                          radius: _kRadius,
                          color: _kOrange,
                          darkColor: _kOrangeDark,
                        ),
                        child: Row(
                          children: List.generate(
                              _icons.length, (i) => _buildTab(i, iW)),
                        ),
                      ),
                    ),

                    // ── FLOATING CIRCLE ──
                    // FIX 1 lanjutan: top negatif = circle naik ke atas bar
                    Positioned(
                      top: -(_kCircleD / 1.9),
                      left: notchX - (_kCircleD / 2),
                      child: ScaleTransition(
                        scale: _popAnim,
                        child: Container(
                          width: _kCircleD,
                          height: _kCircleD,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            _icons[widget.currentIndex],
                            color: _kOrange,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTab(int i, double w) {
    final active = i == widget.currentIndex;
    return GestureDetector(
      onTap: () => widget.onTap(i),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: w,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // FIX 2: naik dari end → center
          children: [
            Opacity(
              opacity: active ? 0 : 1,
              child: Icon(_icons[i],
                  color: Colors.white.withOpacity(0.7), size: 24),
            ),
            const SizedBox(height: 4),
            // FIX 2 lanjutan: hapus bottom padding yg bikin text turun
            Text(
              _labels[i],
              style: TextStyle(
                color: active ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _NotchPainter extends CustomPainter {
  final double notchX;
  final double notchR;
  final double radius;
  final Color color;
  final Color darkColor;

  _NotchPainter({
    required this.notchX,
    required this.notchR,
    required this.radius,
    required this.color,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, darkColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    final safeX = notchX.clamp(notchR, size.width - notchR);
    final depth = notchR * 0.90;

    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(safeX - notchR, 0);

    path.cubicTo(
      safeX - (notchR * 0.85),
      0,
      safeX - (notchR * 0.8),
      depth,
      safeX,
      depth,
    );
    path.cubicTo(
      safeX + (notchR * 0.8),
      depth,
      safeX + (notchR * 0.85),
      0,
      safeX + notchR,
      0,
    );

    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 10, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NotchPainter oldDelegate) =>
      oldDelegate.notchX != notchX;
}
