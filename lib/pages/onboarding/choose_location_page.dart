import 'package:flutter/material.dart';
import 'package:teman_resto/utils/app_colors.dart';

class ChooseLocationPage extends StatefulWidget {
  const ChooseLocationPage({Key? key}) : super(key: key);

  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage> {
  static String currentActiveCity = "JAKARTA";

  List<Map<String, dynamic>> locations = [
    {'name': 'JAKARTA', 'isCurrent': false},
    {'name': 'MALANG', 'isCurrent': false},
    {'name': 'MOJOKERTO', 'isCurrent': false},
    {'name': 'KEDIRI', 'isCurrent': false},
    {'name': 'PROBOLINGGO', 'isCurrent': false},
    {'name': 'SURABAYA', 'isCurrent': false},
    {'name': 'GRESIK', 'isCurrent': false},
    {'name': 'JEMBER', 'isCurrent': false},
    {'name': 'MADIUN', 'isCurrent': false},
    {'name': 'SOLO', 'isCurrent': false},
    {'name': 'YOGYAKARTA', 'isCurrent': false},
    {'name': 'PURWOKERTO', 'isCurrent': false},
    {'name': 'MATARAM', 'isCurrent': false},
    {'name': 'TEGAL', 'isCurrent': false},
    {'name': 'CIREBON', 'isCurrent': false},
    {'name': 'BANDUNG', 'isCurrent': false},
    {'name': 'PURWAKARTA', 'isCurrent': false},
    {'name': 'KARAWANG', 'isCurrent': false},
    {'name': 'CIKARANG', 'isCurrent': false},
    {'name': 'BEKASI', 'isCurrent': false},
    {'name': 'BOGOR', 'isCurrent': false},
    {'name': 'DEPOK', 'isCurrent': false},
    {'name': 'TANGERANG', 'isCurrent': false},
    {'name': 'SERANG', 'isCurrent': false},
    {'name': 'MAKASSAR', 'isCurrent': false},
    {'name': 'LAMPUNG', 'isCurrent': false},
    {'name': 'BALIKPAPAN', 'isCurrent': false},
    {'name': 'SAMARINDA', 'isCurrent': false},
    {'name': 'PALEMBANG', 'isCurrent': false},
    {'name': 'BATAM', 'isCurrent': false},
    {'name': 'PEKANBARU', 'isCurrent': false},
    {'name': 'MEDAN', 'isCurrent': false},
    {'name': 'PADANG', 'isCurrent': false},
  ];

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateCurrentStatus();
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
                    child: Text(
                      'Choose Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
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
