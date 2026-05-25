import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════
//  COLOUR HELPERS
// ═══════════════════════════════════════════════

Color tableColor(bool reserved, bool isSelected) {
  if (reserved) return const Color(0xFFFF4F0F);
  if (isSelected) return const Color(0xFF43EA3B);
  return const Color(0xFFEDEDED);
}

Color strokeColor(bool reserved, bool isSelected) {
  if (reserved || isSelected) return Colors.white;
  return const Color(0xFF878787);
}

Color textColor(bool reserved, bool isSelected) {
  return (reserved || isSelected) ? Colors.white : Colors.black87;
}

// ═══════════════════════════════════════════════
//  CHAIR WIDGETS
// ═══════════════════════════════════════════════

/// Kursi bulat ukuran default (16×16)
Widget tableChair(bool reserved, bool isSelected) {
  return _chairBase(reserved, isSelected, 16);
}

/// Kursi bulat ukuran custom
Widget tableChairSized(bool reserved, bool isSelected, double size) {
  return _chairBase(reserved, isSelected, size);
}

Widget _chairBase(bool reserved, bool isSelected, double size) {
  Color chairColor;
  if (reserved) {
    chairColor = const Color(0xFFFF4F0F);
  } else if (isSelected) {
    chairColor = const Color(0xFF43EA3B);
  } else {
    chairColor = const Color(0xFFEDEDED);
  }
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: chairColor,
      border: Border.all(
        color: (reserved || isSelected) ? Colors.white : const Color(0xFF878787),
        width: 1,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════
//  LEGEND
// ═══════════════════════════════════════════════

Widget tableLegend(Color color, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════
//  TABLE WIDGETS
// ═══════════════════════════════════════════════

/// Meja persegi panjang horizontal dengan kursi atas-bawah
class RectangleTableWithChairs extends StatelessWidget {
  final String id;
  final bool reserved;
  final bool isSelected;
  final VoidCallback? onTap;

  const RectangleTableWithChairs({
    super.key,
    required this.id,
    required this.reserved,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: reserved ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              tableChair(reserved, isSelected),
              const SizedBox(width: 8),
              tableChair(reserved, isSelected),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 90,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: strokeColor(reserved, isSelected), width: 1.5),
            ),
            child: Text(
              id,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              tableChair(reserved, isSelected),
              const SizedBox(width: 8),
              tableChair(reserved, isSelected),
            ],
          ),
        ],
      ),
    );
  }
}

/// Meja persegi (square) dengan kursi atas-bawah
class SquareTable extends StatelessWidget {
  final String id;
  final bool reserved;
  final bool isSelected;
  final VoidCallback? onTap;

  const SquareTable({
    super.key,
    required this.id,
    required this.reserved,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: reserved ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tableChair(reserved, isSelected),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: strokeColor(reserved, isSelected), width: 1.5),
            ),
            child: Text(
              id,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(height: 6),
          tableChair(reserved, isSelected),
        ],
      ),
    );
  }
}

/// Meja persegi panjang besar (vertikal) dengan kursi kiri-kanan
class LargeRectangleTable extends StatelessWidget {
  final String id;
  final bool reserved;
  final bool isSelected;
  final VoidCallback? onTap;

  const LargeRectangleTable({
    super.key,
    required this.id,
    required this.reserved,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: reserved ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tableChair(reserved, isSelected),
              const SizedBox(height: 8),
              tableChair(reserved, isSelected),
              const SizedBox(height: 8),
              tableChair(reserved, isSelected),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: strokeColor(reserved, isSelected), width: 1.5),
            ),
            child: Text(
              id,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tableChair(reserved, isSelected),
              const SizedBox(height: 8),
              tableChair(reserved, isSelected),
              const SizedBox(height: 8),
              tableChair(reserved, isSelected),
            ],
          ),
        ],
      ),
    );
  }
}

/// Meja panjang vertikal (untuk tepi lantai 2/3)
class LongTableVertical extends StatelessWidget {
  final String id;
  final bool reserved;
  final bool isSelected;
  final VoidCallback? onTap;

  const LongTableVertical({
    super.key,
    required this.id,
    required this.reserved,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: reserved ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: tableChair(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 36,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: strokeColor(reserved, isSelected), width: 1.5),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                id,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: textColor(reserved, isSelected),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: tableChair(reserved, isSelected),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meja bundar dengan kursi melingkar
class CircleTable extends StatelessWidget {
  final String id;
  final bool reserved;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;

  const CircleTable({
    super.key,
    required this.id,
    required this.reserved,
    required this.isSelected,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chairCount = size > 100 ? 10 : (size > 70 ? 8 : 6);
    final double fontSize = size >= 90 ? 13 : size >= 60 ? 10 : 9;
    final double chairRadius = size / 2 + (size < 60 ? 14 : 18);
    final double chairSize = size < 60 ? 12.0 : 16.0;

    return GestureDetector(
      onTap: reserved ? null : onTap,
      child: SizedBox(
        width: size + 50,
        height: size + 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(chairCount, (index) {
              final angle = (index * 360 / chairCount) * math.pi / 180;
              return Positioned(
                left: (size + 50) / 2 + chairRadius * math.cos(angle) - chairSize / 2,
                top: (size + 50) / 2 + chairRadius * math.sin(angle) - chairSize / 2,
                child: tableChairSized(reserved, isSelected, chairSize),
              );
            }),
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tableColor(reserved, isSelected),
                border: Border.all(color: strokeColor(reserved, isSelected), width: 1.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    id,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor(reserved, isSelected),
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