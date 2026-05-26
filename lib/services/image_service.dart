import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  final _picker = ImagePicker();

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

  /// Upload image ke Cloudinary dan return secure URL.
  Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      if (!CloudinaryConfig.isConfigured) {
        throw Exception(
          'Cloudinary belum dikonfigurasi. Isi lib/config/cloudinary_config.dart.',
        );
      }

      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final fileBytes = await imageFile.readAsBytes();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final boundary = 'teman_resto_$timestamp';
      final uri = Uri.https(
        'api.cloudinary.com',
        '/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );

      print('[ImageService] Starting Cloudinary upload...');
      print('[ImageService] User ID: $uid');
      print('[ImageService] File path: ${imageFile.path}');
      print('[ImageService] File size: ${fileBytes.length} bytes');

      final body = <int>[
        ..._fieldPart(boundary, 'upload_preset', CloudinaryConfig.uploadPreset),
        ..._fieldPart(boundary, 'folder', CloudinaryConfig.folder),
        ..._fieldPart(boundary, 'public_id', 'profile_${uid}_$timestamp'),
        ..._filePart(
          boundary: boundary,
          fieldName: 'file',
          fileName: 'profile_$uid.jpg',
          contentType: 'image/jpeg',
          bytes: fileBytes,
        ),
        ...utf8.encode('--$boundary--\r\n'),
      ];

      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType(
          'multipart',
          'form-data',
          parameters: {'boundary': boundary},
        );
        request.contentLength = body.length;
        request.add(body);

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode < 200 || response.statusCode >= 300) {
          print('[ImageService] Cloudinary error: $responseBody');
          throw Exception('Upload Cloudinary gagal (${response.statusCode})');
        }

        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl == null || secureUrl.trim().isEmpty) {
          throw Exception('Cloudinary tidak mengembalikan secure_url');
        }

        print('[ImageService] Cloudinary upload berhasil: $secureUrl');
        return secureUrl;
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      print('[ImageService] Upload error: $e');
      return null;
    }
  }

  List<int> _fieldPart(String boundary, String name, String value) {
    return utf8.encode(
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="$name"\r\n\r\n'
      '$value\r\n',
    );
  }

  List<int> _filePart({
    required String boundary,
    required String fieldName,
    required String fileName,
    required String contentType,
    required List<int> bytes,
  }) {
    return [
      ...utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="$fieldName"; filename="$fileName"\r\n'
        'Content-Type: $contentType\r\n\r\n',
      ),
      ...bytes,
      ...utf8.encode('\r\n'),
    ];
  }

  /// Delete image dari Cloudinary perlu signed request dari backend.
  Future<bool> deleteProfileImage(String uid) async {
    print(
      '[ImageService] Delete skipped for profile_$uid. Cloudinary delete needs backend signature.',
    );
    return false;
  }

  /// Pilih gambar dengan dialog (gallery atau camera)
  Future<File?> pickImage() async {
    final file = await pickImageFromGallery();
    return file;
  }
}
