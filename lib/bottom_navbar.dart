import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavbarItem> items;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant BottomNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Custom shaped navbar dengan notch
        CustomPaint(
          painter: NavbarNotchPainter(
            notchIndex: widget.currentIndex,
            itemCount: widget.items.length,
            color: const Color(0xFFFF6B35),
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),
        ),

        // Navigation items
        SafeArea(
          top: false,
          child: SizedBox(
            height: 110,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  widget.items.length,
                  (index) => _buildNavItem(index, widget.items[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, NavbarItem item) {
    bool isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 75,
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Icon dengan animasi
            Transform.translate(
              offset: isSelected ? const Offset(0, -45) : Offset.zero,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: isSelected ? 70 : 36,
                height: isSelected ? 70 : 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    item.iconPath,
                    width: isSelected ? 30 : 20,
                    height: isSelected ? 30 : 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            // Spacing dan Label
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom Painter untuk membuat notch/lengkungan yang lebih smooth
class NavbarNotchPainter extends CustomPainter {
  final int notchIndex;
  final int itemCount;
  final Color color;

  NavbarNotchPainter({
    required this.notchIndex,
    required this.itemCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true; // Untuk smooth edge

    final path = Path();

    // Hitung posisi notch
    final itemWidth = size.width / itemCount;
    final notchCenter = (notchIndex + 0.5) * itemWidth;
    final notchRadius = 40.0;
    final curveDepth = 32.0;

    // Mulai dari kiri atas
    path.moveTo(0, 0);

    // Garis horizontal ke awal notch
    path.lineTo(notchCenter - notchRadius - 8, 0);

    // Kurva smooth menggunakan cubic bezier
    // Titik awal transisi
    path.cubicTo(
      notchCenter - notchRadius - 8,
      0, // Start point (sama dengan end point garis sebelumnya)
      notchCenter - notchRadius + 2,
      0, // Control point 1 - smooth masuk
      notchCenter - notchRadius + 8,
      curveDepth * 0.25, // Control point 2
    );

    // Kurva turun ke bawah (sisi kiri lengkungan)
    path.cubicTo(
      notchCenter - notchRadius + 12,
      curveDepth * 0.4, // Control point 1
      notchCenter - notchRadius * 0.6,
      curveDepth * 0.75, // Control point 2
      notchCenter - notchRadius * 0.3,
      curveDepth * 0.9, // End point
    );

    // Kurva bagian bawah (titik terdalam lengkungan)
    path.cubicTo(
      notchCenter - notchRadius * 0.15,
      curveDepth * 0.97, // Control point 1
      notchCenter + notchRadius * 0.15,
      curveDepth * 0.97, // Control point 2
      notchCenter + notchRadius * 0.3,
      curveDepth * 0.9, // End point
    );

    // Kurva naik (sisi kanan lengkungan)
    path.cubicTo(
      notchCenter + notchRadius * 0.6,
      curveDepth * 0.75, // Control point 1
      notchCenter + notchRadius - 12,
      curveDepth * 0.4, // Control point 2
      notchCenter + notchRadius - 8,
      curveDepth * 0.25, // End point
    );

    // Kurva transisi kembali ke flat
    path.cubicTo(
      notchCenter + notchRadius - 2,
      0, // Control point 1
      notchCenter + notchRadius + 8,
      0, // Control point 2 - smooth keluar
      notchCenter + notchRadius + 8,
      0, // End point
    );

    // Garis horizontal ke kanan
    path.lineTo(size.width, 0);

    // Sisi kanan
    path.lineTo(size.width, size.height);

    // Bawah
    path.lineTo(0, size.height);

    // Sisi kiri
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NavbarNotchPainter oldDelegate) {
    return oldDelegate.notchIndex != notchIndex ||
        oldDelegate.itemCount != itemCount ||
        oldDelegate.color != color;
  }
}

class NavbarItem {
  final String iconPath;
  final String label;

  const NavbarItem({required this.iconPath, required this.label});
}
