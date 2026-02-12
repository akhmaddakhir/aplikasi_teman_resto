import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavbar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90, // ⬅️ PENTING: kasih tinggi biar ga putih
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Navbar
          Positioned.fill(
            top: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    items.length,
                    (index) => _buildItem(context, index),
                  ),
                ),
              ),
            ),
          ),

          // Floating Active Icon
          Positioned(
            top: 0,
            left: _getPosition(context),
            child: _buildFloatingActiveIcon(),
          ),
        ],
      ),
    );
  }

  double _getPosition(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / items.length;
    return itemWidth * currentIndex + (itemWidth / 2) - 28;
  }

  Widget _buildFloatingActiveIcon() {
    final item = items[currentIndex];

    return GestureDetector(
      onTap: () => onTap(currentIndex),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            item.iconPath,
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFF6B35),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / items.length,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 18),

            Opacity(
              opacity: isActive ? 0 : 1,
              child: SvgPicture.asset(
                items[index].iconPath,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              items[index].label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class NavbarItem {
  final String iconPath;
  final String label;

  const NavbarItem({required this.iconPath, required this.label});
}
