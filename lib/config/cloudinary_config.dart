import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static const folder = '';
  static const profileFolder = 'profile';
  static const restaurantPhotoFolder = 'foto_resto';
  static const restaurantGalleryFolder = 'foto_resto/gallery';
  static const menuPhotoFolder = 'foto_menu';

  static bool get isConfigured =>
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty &&
      !cloudName.startsWith('ISI_') &&
      !uploadPreset.startsWith('ISI_');
}
