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

class _BottomNavbarState extends State<BottomNavbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index, widget.items[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavbarItem item) {
    bool isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index != widget.currentIndex) {
          widget.onTap(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6B35).withOpacity(0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  item.iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    isSelected ? const Color(0xFFFF6B35) : Colors.grey[400]!,
                    BlendMode.srcIn,
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

class NavbarItem {
  final String iconPath;
  final String label;

  const NavbarItem({required this.iconPath, required this.label});
}
