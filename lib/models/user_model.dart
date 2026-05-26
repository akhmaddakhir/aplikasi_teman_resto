import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String? gender;
  final String? location;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.gender,
    this.location,
    required this.createdAt,
    this.lastLogin,
    this.updatedAt,
  });

  // ── Firestore ─────────────────────────────────────────────────
  /// Simpan ke Firestore — semua tanggal dalam format ISO String
  /// agar konsisten dan mudah dibaca
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'gender': gender,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': (lastLogin ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Baca dari Firestore — handle Timestamp Firestore ATAU ISO String
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    try {
      return UserModel(
        uid: (data['uid'] as String?) ?? '',
        fullName: (data['fullName'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        phoneNumber: data['phoneNumber'] as String?,
        profileImage: data['profileImage'] as String?,
        gender: data['gender'] as String?,
        location: data['location'] as String?,
        createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
        lastLogin: _parseDate(data['lastLogin']),
        updatedAt: _parseDate(data['updatedAt']),
      );
    } catch (e) {
      print('[UserModel] Error parsing fromFirestore: $e');
      // Return minimal user jika parsing gagal
      return UserModel(
        uid: (data['uid'] as String?) ?? '',
        fullName: (data['fullName'] as String?) ?? 'User',
        email: (data['email'] as String?) ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  // ── JSON (SharedPreferences) ──────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'gender': gender,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        uid: (json['uid'] as String?) ?? '',
        fullName: (json['fullName'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        profileImage: json['profileImage'] as String?,
        gender: json['gender'] as String?,
        location: json['location'] as String?,
        createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
        lastLogin: _parseDate(json['lastLogin']),
        updatedAt: _parseDate(json['updatedAt']),
      );
    } catch (e) {
      print('[UserModel] Error parsing fromJson: $e');
      return UserModel(
        uid: (json['uid'] as String?) ?? '',
        fullName: (json['fullName'] as String?) ?? 'User',
        email: (json['email'] as String?) ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  // ── CopyWith ──────────────────────────────────────────────────
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? gender,
    String? location,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Helper ────────────────────────────────────────────────────
  /// Parse tanggal dari Firestore Timestamp, ISO String, atau null
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      // Firestore Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }

      // ISO String
      if (value is String) {
        return DateTime.parse(value);
      }

      // Fallback: try to parse if it's any other type
      print(
          '[UserModel._parseDate] Unknown type: ${value.runtimeType}, value: $value');
      return null;
    } catch (e) {
      print('[UserModel._parseDate] Error parsing date: $e');
      return null;
    }
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, fullName: $fullName, email: $email)';
}
