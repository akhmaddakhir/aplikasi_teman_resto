class CloudinaryConfig {
  static const cloudName = 'dh0slmjul';
  static const uploadPreset = 'teman_resto_profile';
  static const folder = 'teman_resto/profile_images';

  static bool get isConfigured =>
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty &&
      !cloudName.startsWith('ISI_') &&
      !uploadPreset.startsWith('ISI_');
}
