import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final DateTime createdAt;
  final String? photoUrl;
  final String? profileImageUrl;
  final String? birthday;
  final String? gender;
  final String? address;
  final String? farmLocation;
  final String? extraNotes;
  final String role;
  final bool isVerified;
  final UserSettings? settings;

  const User({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.photoUrl,
    this.profileImageUrl,
    this.birthday,
    this.gender,
    this.address,
    this.farmLocation,
    this.extraNotes,
    this.role = 'farmer',
    this.isVerified = false,
    this.settings,
  });

  // ── From Firestore ─────────────────────────────────────────────
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    return User(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'],
      // ✅ check both Firestore field and backend field name
      profileImageUrl: data['profileImageUrl'] ?? data['profilePicture'],
      birthday: data['birthday'],
      gender: data['gender'],
      // ✅ check flat 'address' first, then nested location.district
      address: data['address'] ??
          (data['location'] as Map<String, dynamic>?)?['district'],
      farmLocation: data['farmLocation'],
      // ✅ Firestore stores extraNotes as plain string
      extraNotes: data['extraNotes'],
      role: data['role'] ?? 'farmer',
      isVerified: data['isVerified'] ?? false,
      settings: data['settings'] != null
          ? UserSettings.fromJson(Map<String, dynamic>.from(data['settings']))
          : null,
    );
  }

  // ── From Backend REST ──────────────────────────────────────────
  factory User.fromBackendJson(Map<String, dynamic> json, String uid) {
    final location = json['location'] as Map<String, dynamic>?;
    final farmDetails = json['farmDetails'] as Map<String, dynamic>?;
    final crops = farmDetails?['mainCrops'] as List<dynamic>?;

    // ✅ Backend stores extraNotes inside farmDetails.mainCrops[0]
    // If mainCrops has items, use first item as extraNotes
    final extraNotes =
        (crops != null && crops.isNotEmpty) ? crops.first.toString() : null;

    return User(
      uid: uid,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      photoUrl: json['profilePicture'],
      profileImageUrl: json['profilePicture'],
      birthday: json['birthday'],
      gender: json['gender'],
      address: location?['district'],
      farmLocation: json['farmLocation'],
      extraNotes: extraNotes,
      role: json['role'] ?? 'farmer',
      isVerified: json['isVerified'] ?? false,
      settings: json['settings'] != null
          ? UserSettings.fromJson(Map<String, dynamic>.from(json['settings']))
          : null,
    );
  }

  // ── To Firestore ───────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'profileImageUrl': profileImageUrl,
        'birthday': birthday,
        'gender': gender,
        'address': address,
        'farmLocation': farmLocation,
        'extraNotes': extraNotes,
        'role': role,
        'isVerified': isVerified,
        if (settings != null) 'settings': settings!.toJson(),
      };

  // ── To Backend REST body ───────────────────────────────────────
  Map<String, dynamic> toBackendJson() => {
        'name': name,
        'phone': phone,
        'location': {
          'district': address ?? '',
          'province': '',
        },
        'farmDetails': {
          // ✅ extraNotes stored as first item of mainCrops
          'mainCrops': (extraNotes != null && extraNotes!.isNotEmpty)
              ? [extraNotes]
              : [],
        },
        'birthday': birthday ?? '',
        'gender': gender ?? '',
        'farmLocation': farmLocation ?? '',
      };

  User copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? profileImageUrl,
    bool clearProfileImage = false,
    String? birthday,
    String? gender,
    String? address,
    String? farmLocation,
    String? extraNotes,
    UserSettings? settings,
  }) =>
      User(
        uid: uid,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        createdAt: createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        profileImageUrl: clearProfileImage
            ? null
            : (profileImageUrl ?? this.profileImageUrl),
        birthday: birthday ?? this.birthday,
        gender: gender ?? this.gender,
        address: address ?? this.address,
        farmLocation: farmLocation ?? this.farmLocation,
        extraNotes: extraNotes ?? this.extraNotes,
        role: role,
        isVerified: isVerified,
        settings: settings ?? this.settings,
      );
}

// ── UserSettings ───────────────────────────────────────────────────────
class UserSettings {
  final String language;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool darkMode;
  final bool locationAccess;
  final bool dataSync;

  const UserSettings({
    this.language = 'en',
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.darkMode = false,
    this.locationAccess = true,
    this.dataSync = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        language: json['language'] ?? 'en',
        pushNotifications: json['pushNotifications'] ?? true,
        emailNotifications: json['emailNotifications'] ?? false,
        darkMode: json['darkMode'] ?? false,
        locationAccess: json['locationAccess'] ?? true,
        dataSync: json['dataSync'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'pushNotifications': pushNotifications,
        'emailNotifications': emailNotifications,
        'darkMode': darkMode,
        'locationAccess': locationAccess,
        'dataSync': dataSync,
      };

  UserSettings copyWith({
    String? language,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? darkMode,
    bool? locationAccess,
    bool? dataSync,
  }) =>
      UserSettings(
        language: language ?? this.language,
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        darkMode: darkMode ?? this.darkMode,
        locationAccess: locationAccess ?? this.locationAccess,
        dataSync: dataSync ?? this.dataSync,
      );
}
