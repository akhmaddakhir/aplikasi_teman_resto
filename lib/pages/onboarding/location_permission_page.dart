import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teman_resto/services/location_service.dart';

class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({Key? key}) : super(key: key);

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  bool _isRequestingLocation = false;

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

  Future<void> allowLocationAccess() async {
    if (_isRequestingLocation) return;

    setState(() => _isRequestingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        _showLocationMessage('Aktifkan GPS terlebih dahulu.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage('Izin lokasi ditolak.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        _showLocationMessage(
          'Izin lokasi diblokir permanen. Aktifkan lewat pengaturan aplikasi.',
        );
        return;
      }

      await LocationService.instance.startRealtimeTracking();

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: LocationService.liveLocationArgument,
      );
    } catch (_) {
      _showLocationMessage('Gagal mengambil lokasi. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isRequestingLocation = false);
      }
    }
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),

              /// ICON
              Container(
                width: 144,
                height: 144,
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

              const SizedBox(height: 48),

              /// TITLE
              const Text(
                'Where is Your Location?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'We need your location to show available\nnearby restaurant.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              /// ALLOW LOCATION
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequestingLocation ? null : allowLocationAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isRequestingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Allow Location Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              /// CHOOSE MANUALLY (INI YANG TADI BUG)
              TextButton(
                onPressed: openChooseLocation,
                child: const Text(
                  'Choose Location Manually',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF5722),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
