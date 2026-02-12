import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_page.dart';

class NavigatePage extends StatelessWidget {
  const NavigatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
            child: Stack(
              children: [
                // Gunakan screenshot map dari Google Maps
                // Uncomment ini kalau sudah punya screenshot:
                /*
                Image.asset(
                  'assets/images/map_background.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                */

                // ATAU gunakan pola map yang lebih realistis
                CustomPaint(
                  size: Size.infinite,
                  painter: RealisticMapPainter(),
                ),

                // Gradient overlay untuk efek depth
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.35,
            right: MediaQuery.of(context).size.width * 0.25,
            child: _buildMarker(
              label: 'Marina Kitchen',
              color: Color(0xFFFF4F0F),
              isMain: true,
            ),
          ),

          // Marker Cocomart (Brown)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.32,
            right: MediaQuery.of(context).size.width * 0.1,
            child: _buildMarker(
              label: 'Your Position',
              color: Color(0xFF8B4513),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/icons/back.svg',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                    Text(
                      "Navigate",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 32),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/location.svg',
                                width: 18,
                                height: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marina Kitchen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Jl. Mangan III 216 Psr II Mabara, Surabaya, Jawa Timur',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF4F0F),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Navigate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker({
    required String label,
    required Color color,
    bool isMain = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMain ? 10 : 8,
            vertical: isMain ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMain ? 11 : 10,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(height: 4),
        // Pin Icon
        Stack(
          alignment: Alignment.center,
          children: [
            // Shadow
            Transform.translate(
              offset: Offset(0, 2),
              child: Icon(
                Icons.location_on,
                color: Colors.black.withOpacity(0.25),
                size: isMain ? 42 : 34,
              ),
            ),
            // Main Icon
            Icon(Icons.location_on, color: color, size: isMain ? 42 : 34),
          ],
        ),
      ],
    );
  }
}

// Realistic Map Painter - Map yang lebih bagus!
class RealisticMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base background (light gray untuk area kosong)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Color(0xFFF5F5F5),
    );

    // Green park areas (warna hijau muda seperti Google Maps)
    final parkPaint = Paint()
      ..color = Color(0xFFCCE5CC)
      ..style = PaintingStyle.fill;

    // Park 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.05,
          size.height * 0.15,
          size.width * 0.35,
          size.height * 0.3,
        ),
        Radius.circular(12),
      ),
      parkPaint,
    );

    // Park 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.65,
          size.height * 0.5,
          size.width * 0.3,
          size.height * 0.25,
        ),
        Radius.circular(12),
      ),
      parkPaint,
    );

    // Building blocks (warna abu-abu terang)
    final buildingPaint = Paint()..color = Color(0xFFE8E8E8);

    final buildings = [
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.5,
        size.width * 0.2,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.2,
        size.width * 0.18,
        size.height * 0.2,
      ),
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.25,
        size.width * 0.15,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.6,
        size.width * 0.22,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.75,
        size.width * 0.18,
        size.height * 0.12,
      ),
    ];

    for (var building in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(building, Radius.circular(3)),
        buildingPaint,
      );
    }

    // Roads (putih dengan border abu-abu)
    final roadBorderPaint = Paint()
      ..color = Color(0xFFDCDCDC)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Horizontal roads
    final horizontalRoads = [0.25, 0.5, 0.7];
    for (var y in horizontalRoads) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        roadBorderPaint,
      );
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        roadPaint,
      );
    }

    // Vertical roads
    final verticalRoads = [0.25, 0.5, 0.75];
    for (var x in verticalRoads) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        roadBorderPaint,
      );
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        roadPaint,
      );
    }

    // Diagonal road
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.65, size.height * 0.75),
      roadBorderPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.65, size.height * 0.75),
      roadPaint,
    );

    // Road markings (dashed lines)
    final dashPaint = Paint()
      ..color = Color(0xFFE0E0E0)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Add dashed line to main horizontal road
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, size.height * 0.5),
        Offset(i + 10, size.height * 0.5),
        dashPaint,
      );
    }

    // Water body (blue area - optional)
    final waterPaint = Paint()..color = Color(0xFFB3D9FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.5,
          size.height * 0.05,
          size.width * 0.25,
          size.height * 0.12,
        ),
        Radius.circular(8),
      ),
      waterPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
