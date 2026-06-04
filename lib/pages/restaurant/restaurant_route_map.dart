import 'package:flutter/material.dart';

import '../navigate/navigate_page.dart';

class RestaurantRouteMap extends StatelessWidget {
  final String restaurantName;
  final String restaurantAddress;
  final double restaurantLatitude;
  final double restaurantLongitude;

  const RestaurantRouteMap({
    super.key,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
  });

  @override
  Widget build(BuildContext context) {
    return NavigatePage(
      fixedDestinationName: restaurantName,
      fixedDestinationAddress: restaurantAddress,
      fixedDestinationLatitude: restaurantLatitude,
      fixedDestinationLongitude: restaurantLongitude,
      disableSearch: true,
    );
  }
}
