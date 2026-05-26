import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teman_resto/services/location_service.dart';
import 'package:teman_resto/utils/app_colors.dart';

class ChooseLocationPage extends StatefulWidget {
  const ChooseLocationPage({Key? key}) : super(key: key);

  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage> {
  static String currentActiveCity = "Jakarta";
  bool _isLoadingLocation = false;

  List<Map<String, dynamic>> locations = [
    {'name': 'Jakarta', 'isCurrent': false},
    {'name': 'Malang', 'isCurrent': false},
    {'name': 'Mojokerto', 'isCurrent': false},
    {'name': 'Kediri', 'isCurrent': false},
    {'name': 'Probolinggo', 'isCurrent': false},
    {'name': 'Surabaya', 'isCurrent': false},
    {'name': 'Gresik', 'isCurrent': false},
    {'name': 'Jember', 'isCurrent': false},
    {'name': 'Madiun', 'isCurrent': false},
    {'name': 'Solo', 'isCurrent': false},
    {'name': 'Yogyakarta', 'isCurrent': false},
    {'name': 'Purwokerto', 'isCurrent': false},
    {'name': 'Mataram', 'isCurrent': false},
    {'name': 'Tegal', 'isCurrent': false},
    {'name': 'Cirebon', 'isCurrent': false},
    {'name': 'Bandung', 'isCurrent': false},
    {'name': 'Purwakarta', 'isCurrent': false},
    {'name': 'Karawang', 'isCurrent': false},
    {'name': 'Cikarang', 'isCurrent': false},
    {'name': 'Bekasi', 'isCurrent': false},
    {'name': 'Bogor', 'isCurrent': false},
    {'name': 'Depok', 'isCurrent': false},
    {'name': 'Tangerang', 'isCurrent': false},
    {'name': 'Serang', 'isCurrent': false},
    {'name': 'Makassar', 'isCurrent': false},
    {'name': 'Lampung', 'isCurrent': false},
    {'name': 'Balikpapan', 'isCurrent': false},
    {'name': 'Samarinda', 'isCurrent': false},
    {'name': 'Palembang', 'isCurrent': false},
    {'name': 'Batam', 'isCurrent': false},
    {'name': 'Pekanbaru', 'isCurrent': false},
    {'name': 'Medan', 'isCurrent': false},
    {'name': 'Padang', 'isCurrent': false},
  ];

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateCurrentStatus();
    _detectUserLocation();
  }

  /// Detect user location dan update current active city
  Future<void> _detectUserLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Request permission
      final permission = await Geolocator.checkPermission();
      late LocationPermission permissionStatus;

      if (permission == LocationPermission.denied) {
        permissionStatus = await Geolocator.requestPermission();
      } else {
        permissionStatus = permission;
      }

      if (permissionStatus == LocationPermission.whileInUse ||
          permissionStatus == LocationPermission.always) {
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ).catchError((_) async {
          // Fallback to last known position
          return await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition();
        });

        // Convert position ke city name
        final city =
            await LocationService.instance.getCityFromPosition(position);

        if (mounted) {
          setState(() {
            currentActiveCity = city;
            _updateCurrentStatus();
            _isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      print('Error detecting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateCurrentStatus() {
    for (var loc in locations) {
      if (loc['name'].toLowerCase() == currentActiveCity.toLowerCase()) {
        loc['isCurrent'] = true;
      } else {
        loc['isCurrent'] = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocations = locations
        .where(
          (location) => location['name']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Choose Location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_isLoadingLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: SizedBox(
                              height: 12,
                              width: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              // Search Field
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: AppColors.textGrey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Location List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = filteredLocations[index];

                    return InkWell(
                      onTap: () {
                        setState(() {
                          currentActiveCity = location['name'];
                          _updateCurrentStatus();
                        });
                        Future.delayed(const Duration(milliseconds: 200), () {
                          Navigator.pop(context, location['name']);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.inputFill,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  location['name'],
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: location['isCurrent']
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: location['isCurrent']
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                ),
                                if (location['isCurrent']) ...[
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Current Location',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: location['isCurrent']
                                  ? AppColors.primary
                                  : AppColors.textGrey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
