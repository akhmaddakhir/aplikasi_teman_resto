import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 20,
                      height: 20,
                    ),
                    Text(
                      "Wishlist",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(width: 20), // Spacer biar seimbang
                  ],
                ),
                SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF4F0F),
                        foregroundColor: Colors.white,
                      ),
                      child: Text("All"),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                      child: Text("Javanese"),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                      child: Text("Balinese"),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          'assets/images/melati_restaurant.png',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Melati Restaurant',
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
                                    Text('4.8', style: TextStyle(fontSize: 14)),
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
                                Text('25 min', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 16),
                                SvgPicture.asset(
                                  'assets/icons/bowl_card.svg',
                                  width: 16,
                                  height: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Javanese',
                                  style: TextStyle(fontSize: 14),
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
                                Text('Jl. Kahuripan No.3, Klojen, Kota Malang'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          'assets/images/melati_restaurant.png',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Melati Restaurant',
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
                                    Text('4.8', style: TextStyle(fontSize: 14)),
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
                                Text('25 min', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 16),
                                SvgPicture.asset(
                                  'assets/icons/bowl_card.svg',
                                  width: 16,
                                  height: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Javanese',
                                  style: TextStyle(fontSize: 14),
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
                                Text('Jl. Kahuripan No.3, Klojen, Kota Malang'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
