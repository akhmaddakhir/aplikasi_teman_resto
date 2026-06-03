class MalangRestaurantLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const MalangRestaurantLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  bool matches(String restaurantName, String restaurantAddress) {
    final normalizedName = _normalize(restaurantName);
    final normalizedAddress = _normalize(restaurantAddress);
    final targetName = _normalize(name);
    final targetAddress = _normalize(address);

    final nameMatches = normalizedName.isNotEmpty &&
        (normalizedName.contains(targetName) ||
            targetName.contains(normalizedName));
    final addressMatches = normalizedAddress.isNotEmpty &&
        (normalizedAddress.contains(targetAddress) ||
            targetAddress.contains(normalizedAddress));

    return nameMatches || addressMatches;
  }
}

const malangRestaurantLocations = <MalangRestaurantLocation>[
  MalangRestaurantLocation(
    name: 'Melati Restaurant',
    address:
        'Hotel Tugu Malang, Jl. Tugu No.3, Klojen, Kota Malang, Jawa Timur 65119',
    latitude: -7.9775639,
    longitude: 112.6332972,
  ),
  MalangRestaurantLocation(
    name: 'Taman Indie River View Resto',
    address:
        'Jl. Lawang Sewu Golf No.2-18, Araya, Kota Malang, Jawa Timur 65111',
    latitude: -7.9394444,
    longitude: 112.6647222,
  ),
  MalangRestaurantLocation(
    name: 'Inggil Museum Resto',
    address: 'Jl. Gajah Mada No.4, Klojen, Kota Malang, Jawa Timur 65119',
    latitude: -7.979030,
    longitude: 112.635089,
  ),
  MalangRestaurantLocation(
    name: 'Depot Rawon Nguling Malang',
    address:
        'Jl. Zainul Arifin No.62, Sukoharjo, Klojen, Kota Malang, Jawa Timur 65119',
    latitude: -7.984935,
    longitude: 112.631482,
  ),
  MalangRestaurantLocation(
    name: 'Bakso President',
    address:
        'Jl. Batanghari No.3, Rampal Celaket, Klojen, Kota Malang, Jawa Timur 65111',
    latitude: -7.964456,
    longitude: 112.637069,
  ),
];

MalangRestaurantLocation? findMalangRestaurantLocation({
  required String restaurantName,
  required String restaurantAddress,
}) {
  final normalizedName = _normalize(restaurantName);
  final normalizedAddress = _normalize(restaurantAddress);
  if (normalizedName.isEmpty && normalizedAddress.isEmpty) return null;

  for (final location in malangRestaurantLocations) {
    if (location.matches(restaurantName, restaurantAddress)) return location;
  }

  return null;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
