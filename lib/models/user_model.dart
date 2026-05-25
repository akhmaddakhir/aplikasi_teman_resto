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

  /// Convert model to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'gender': gender,
      'location': location,
      'createdAt': createdAt,
      'lastLogin': lastLogin ?? DateTime.now(),
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  /// Create model from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImage: data['profileImage'],
      gender: data['gender'],
      location: data['location'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastLogin: data['lastLogin']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  /// Create model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
      gender: json['gender'],
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt
          : DateTime.now(),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'gender': gender,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'updatedAt': updatedAt
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  //String? gender,
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
      updatedAt: updatedAt ?? this.updatedAt
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
