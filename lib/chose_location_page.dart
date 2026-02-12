import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChooseLocationPage extends StatefulWidget {
  const ChooseLocationPage({Key? key}) : super(key: key);

  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage> {
  final List<Map<String, dynamic>> locations = [
    {'name': 'JAKARTA', 'isCurrent': true},
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
  Widget build(BuildContext context) {
    final filteredLocations = locations
        .where(
          (location) => location['name'].toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
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
              const SizedBox(height: 65),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),

                  Expanded(
                    child: Text(
                      'Choose Location',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Spacer biar title benar-benar di tengah
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 15),

              // Search Field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
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
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Location List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = filteredLocations[index];

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context, location['name']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (location['isCurrent']) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'Current Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
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
