import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // Custom ID: USR-0000001
  final String firebaseUid; // Firebase Auth UID
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
    required this.firebaseUid,
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

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firebaseUid': firebaseUid,
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

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    try {
      return UserModel(
        uid: (data['uid'] as String?) ?? '',
        firebaseUid: (data['firebaseUid'] as String?) ?? '',
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
      return UserModel(
        uid: (data['uid'] as String?) ?? '',
        firebaseUid: (data['firebaseUid'] as String?) ?? '',
        fullName: (data['fullName'] as String?) ?? 'User',
        email: (data['email'] as String?) ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firebaseUid': firebaseUid,
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
        firebaseUid: (json['firebaseUid'] as String?) ?? '',
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
        firebaseUid: (json['firebaseUid'] as String?) ?? '',
        fullName: (json['fullName'] as String?) ?? 'User',
        email: (json['email'] as String?) ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  UserModel copyWith({
    String? uid,
    String? firebaseUid,
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
      firebaseUid: firebaseUid ?? this.firebaseUid,
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return null;
    } catch (e) {
      print('[UserModel._parseDate] Error: $e');
      return null;
    }
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, firebaseUid: $firebaseUid, fullName: $fullName, email: $email)';
}
