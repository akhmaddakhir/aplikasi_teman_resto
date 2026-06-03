import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/restaurant_table_model.dart';

const Color tableAvailableColor = Color(0xFFEDEDED);
const Color tableReservedColor = Color(0xFFFF4F0F);
const Color tableSelectedColor = Color(0xFF43EA3B);
const Color tableStrokeColor = Color(0xFF878787);

Color tableColor(bool reserved, bool isSelected) {
  if (reserved) return tableReservedColor;
  if (isSelected) return tableSelectedColor;
  return tableAvailableColor;
}

Color strokeColor(bool reserved, bool isSelected) {
  if (reserved || isSelected) return Colors.white;
  return tableStrokeColor;
}

Color textColor(bool reserved, bool isSelected) {
  return (reserved || isSelected) ? Colors.white : Colors.black87;
}

class TableShapeWidget extends StatelessWidget {
  final String tableName;
  final int capacity;
  final TableShape shape;
  final TableOrientation orientation;
  final TableStatus status;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showCapacity;

  const TableShapeWidget({
    super.key,
    required this.tableName,
    required this.capacity,
    required this.shape,
    required this.orientation,
    this.status = TableStatus.available,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.showCapacity = true,
  });

  bool get _reserved => status == TableStatus.reserved;
  bool get _isVertical => orientation == TableOrientation.vertical;
  bool get _isLong => shape == TableShape.longRectangle;

  @override
  Widget build(BuildContext context) {
    final size = _layoutSize();
    return GestureDetector(
      onTap: _reserved ? null : onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ..._chairPositions(size).map(
              (point) => Positioned(
                left: point.dx - 8,
                top: point.dy - 8,
                child: _chair(),
              ),
            ),
            _tableBody(),
          ],
        ),
      ),
    );
  }

  Size _layoutSize() {
    switch (shape) {
      case TableShape.round:
        return const Size(126, 126);
      case TableShape.longRectangle:
        return _isVertical ? const Size(112, 176) : const Size(176, 112);
      case TableShape.rectangle:
        return _isVertical ? const Size(104, 140) : const Size(140, 104);
      case TableShape.square:
        return const Size(112, 112);
    }
  }

  Size _bodySize() {
    switch (shape) {
      case TableShape.round:
        return const Size(72, 72);
      case TableShape.longRectangle:
        return _isVertical ? const Size(54, 128) : const Size(128, 54);
      case TableShape.rectangle:
        return _isVertical ? const Size(64, 96) : const Size(96, 64);
      case TableShape.square:
        return const Size(70, 70);
    }
  }

  Widget _tableBody() {
    final body = _bodySize();
    final reserved = _reserved;
    final selected = isSelected;
    final bodyColor = tableColor(reserved, selected);
    final border = strokeColor(reserved, selected);
    final text = textColor(reserved, selected);
    final radius = shape == TableShape.round
        ? null
        : BorderRadius.circular(_isLong ? 18 : 12);

    final label = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          tableName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: _isVertical && _isLong ? 11 : 13,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
        if (showCapacity) ...[
          const SizedBox(height: 2),
          Text(
            '$capacity kursi',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: text.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );

    return Container(
      width: body.width,
      height: body.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bodyColor,
        shape: shape == TableShape.round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
        border: Border.all(color: border, width: 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: body.width - 12, child: label),
      ),
    );
  }

  List<Offset> _chairPositions(Size size) {
    switch (shape) {
      case TableShape.round:
        return _roundChairPositions(size);
      case TableShape.square:
        return _squareChairPositions(size);
      case TableShape.rectangle:
      case TableShape.longRectangle:
        return _rectangleChairPositions(size);
    }
  }

  List<Offset> _roundChairPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    return List.generate(capacity, (index) {
      final angle = (-math.pi / 2) + (index * 2 * math.pi / capacity);
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });
  }

  List<Offset> _squareChairPositions(Size size) {
    final body = _bodySize();
    final left = (size.width - body.width) / 2;
    final right = left + body.width;
    final top = (size.height - body.height) / 2;
    final bottom = top + body.height;
    final counts = _splitCapacity(capacity, 4);
    final points = <Offset>[];

    points.addAll(_edgePoints(
      count: counts[0],
      start: Offset(left + 14, top - 12),
      end: Offset(right - 14, top - 12),
    ));
    points.addAll(_edgePoints(
      count: counts[1],
      start: Offset(right + 12, top + 14),
      end: Offset(right + 12, bottom - 14),
    ));
    points.addAll(_edgePoints(
      count: counts[2],
      start: Offset(left + 14, bottom + 12),
      end: Offset(right - 14, bottom + 12),
    ));
    points.addAll(_edgePoints(
      count: counts[3],
      start: Offset(left - 12, top + 14),
      end: Offset(left - 12, bottom - 14),
    ));
    return points;
  }

  List<Offset> _rectangleChairPositions(Size size) {
    final body = _bodySize();
    final left = (size.width - body.width) / 2;
    final right = left + body.width;
    final top = (size.height - body.height) / 2;
    final bottom = top + body.height;
    final firstSide = (capacity / 2).ceil();
    final secondSide = capacity - firstSide;

    if (_isVertical) {
      return [
        ..._edgePoints(
          count: firstSide,
          start: Offset(left - 12, top + 12),
          end: Offset(left - 12, bottom - 12),
        ),
        ..._edgePoints(
          count: secondSide,
          start: Offset(right + 12, top + 12),
          end: Offset(right + 12, bottom - 12),
        ),
      ];
    }

    return [
      ..._edgePoints(
        count: firstSide,
        start: Offset(left + 12, top - 12),
        end: Offset(right - 12, top - 12),
      ),
      ..._edgePoints(
        count: secondSide,
        start: Offset(left + 12, bottom + 12),
        end: Offset(right - 12, bottom + 12),
      ),
    ];
  }

  List<int> _splitCapacity(int value, int sideCount) {
    final base = value ~/ sideCount;
    final remainder = value % sideCount;
    return List.generate(
      sideCount,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  List<Offset> _edgePoints({
    required int count,
    required Offset start,
    required Offset end,
  }) {
    if (count <= 0) return const [];
    if (count == 1) {
      return [Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2)];
    }

    return List.generate(count, (index) {
      final t = index / (count - 1);
      return Offset(
        start.dx + ((end.dx - start.dx) * t),
        start.dy + ((end.dy - start.dy) * t),
      );
    });
  }

  Widget _chair() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: tableColor(_reserved, isSelected),
        shape: BoxShape.circle,
        border: Border.all(color: strokeColor(_reserved, isSelected), width: 1),
      ),
    );
  }
}
