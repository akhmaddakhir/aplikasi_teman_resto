import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;

  factory ImageService() => _instance;
  ImageService._internal();

  /// Pilih gambar dari gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile == null) return null;
      print('[ImageService] Gallery image selected: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      print('[ImageService] Gallery error: $e');
      return null;
    }
  }

  /// Ambil gambar dari camera
  Future<File?> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile == null) return null;
      print('[ImageService] Camera image selected: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      print('[ImageService] Camera error: $e');
      return null;
    }
  }

  /// Upload image ke Firebase Storage
  Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final fileName = 'profile_$uid.jpg';
      final ref = _storage.ref().child('profile_images/$fileName');

      print('[ImageService] Uploading profile image: $fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('[ImageService] Upload successful: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('[ImageService] Upload error: $e');
      return null;
    }
  }

  /// Delete image dari Firebase Storage
  Future<bool> deleteProfileImage(String uid) async {
    try {
      final fileName = 'profile_$uid.jpg';
      final ref = _storage.ref().child('profile_images/$fileName');

      await ref.delete();
      print('[ImageService] Image deleted: $fileName');
      return true;
    } catch (e) {
      print('[ImageService] Delete error: $e');
      return false;
    }
  }

  /// Pilih gambar dengan dialog (gallery atau camera)
  Future<File?> pickImage() async {
    // Bisa diganti dengan showModalBottomSheet jika diperlukan dialog yang lebih custom
    final file = await pickImageFromGallery();
    return file;
  }
}
