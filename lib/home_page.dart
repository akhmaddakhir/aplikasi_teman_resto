import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/location.svg',
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Jakarta",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/icons/next.svg',
                          width: 12,
                          height: 12,
                        ),
                      ],
                    ),
                    SvgPicture.asset(
                      'assets/icons/notification.svg',
                      width: 18,
                      height: 18,
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Popular Near You
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular near you",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "See all",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Horizontal Cards
                SizedBox(
                  height: 250,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Card 1
                        Container(
                          width: 200,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/melati_restaurant.png',
                                  width: 200,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
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
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Melati Restaurant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Jl. Kahuripan No.3, Klojen',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ), // transparan
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                          child: IntrinsicHeight(
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child: Text(
                                                    'See more',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  child: SvgPicture.asset(
                                                    'assets/icons/back_card.svg',
                                                    width: 32,
                                                    height: 32,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                        SizedBox(width: 16),

                        // Card 2
                        Container(
                          width: 200,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/semaja_menteng.png',
                                  width: 200,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
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
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Melati Restaurant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Jl. Kahuripan No.3, Klojen',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ), // transparan
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                          child: IntrinsicHeight(
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child: Text(
                                                    'See more',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  child: SvgPicture.asset(
                                                    'assets/icons/back_card.svg',
                                                    width: 32,
                                                    height: 32,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                        SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Another Restaurants
                Text(
                  "Another Restaurants",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                // Large Card
                Column(
                  children: [
                    Container(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        Text(
                                          '4.8',
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
                                      'Javanese',
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
                    SizedBox(height: 24),
                    Container(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        Text(
                                          '4.8',
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
                                      'Javanese',
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
                    SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
