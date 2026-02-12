import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'restaurant_detail.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => WishlistState();
}

class WishlistState extends State<WishlistPage> {
  String selectedCuisine = 'All';

  final List<Map<String, dynamic>> wishlistItems = [
    {
      'title': 'Melati Restaurant',
      'image': 'assets/images/melati_restaurant.png',
      'cuisine': 'Javanese',
      'rating': '4.8',
    },
    {
      'title': 'Pawon Njawi',
      'image': 'assets/images/gambar_restoran_4.jfif',
      'cuisine': 'Balinese',
      'rating': '4.6',
    },
    {
      'title': 'Gudeg Place',
      'image': 'assets/images/gambar_restoran_5.jfif',
      'cuisine': 'Javanese',
      'rating': '4.7',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Wishlist",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(width: 20),
                  ],
                ),
                SizedBox(height: 12),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedCuisine = 'All';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCuisine == 'All'
                            ? Color(0xFFFF4F0F)
                            : Colors.grey[200],
                        foregroundColor: selectedCuisine == 'All'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: Text("All"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedCuisine = 'Javanese';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCuisine == 'Javanese'
                            ? Color(0xFFFF4F0F)
                            : Colors.grey[200],
                        foregroundColor: selectedCuisine == 'Javanese'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: Text("Javanese"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedCuisine = 'Balinese';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCuisine == 'Balinese'
                            ? Color(0xFFFF4F0F)
                            : Colors.grey[200],
                        foregroundColor: selectedCuisine == 'Balinese'
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: Text("Balinese"),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final filtered = selectedCuisine == 'All'
                        ? wishlistItems
                        : wishlistItems
                              .where((i) => i['cuisine'] == selectedCuisine)
                              .toList();

                    return Column(
                      children: filtered.map((item) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RestaurantDetail(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Stack(
                                      children: [
                                        Image.asset(
                                          item['image'],
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: SvgPicture.asset(
                                            'assets/icons/save.svg',
                                            width: 28,
                                            height: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item['title'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/icons/rating_card.svg',
                                                  width: 16,
                                                  height: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  item['rating'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/clock_card.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '25 min',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              "•",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            SvgPicture.asset(
                                              'assets/icons/bowl_card.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              item['cuisine'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/location_card.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Jl. Kahuripan No.3, Klojen, Kota Malang',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
