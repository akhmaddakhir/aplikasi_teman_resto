import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({Key? key}) : super(key: key);

  @override
  State<LocationPermissionPage> createState() =>
      _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  /// buka halaman pilih lokasi
  /// tunggu hasil
  /// lalu LANGSUNG ke home dengan lokasi tsb
  Future<void> openChooseLocation() async {
    final result = await Navigator.pushNamed(
      context,
      '/choose-location',
    );

    if (result != null && result is String) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              /// ICON
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    'assets/icons/location_besar.svg',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /// TITLE
              const Text(
                'Where is Your Location?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              /// SUBTITLE
              const Text(
                'We need your location to show available\nnearby restaurant.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 210),

              /// ALLOW LOCATION
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // contoh: auto-detect = Jakarta
                    Navigator.pushReplacementNamed(
                      context,
                      '/home',
                      arguments: 'Jakarta',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Allow Location Access',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// CHOOSE MANUALLY (INI YANG TADI BUG)
              TextButton(
                onPressed: openChooseLocation,
                child: const Text(
                  'Choose Location Manually',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFFF5722),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}