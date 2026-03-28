class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String? birthday;
  final String? gender;
  final String? address;
  final String? farmLocation;
  final String? extraNotes;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.birthday,
    this.gender,
    this.address,
    this.farmLocation,
    this.extraNotes,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profile_image_url'],
      birthday: json['birthday'],
      gender: json['gender'],
      address: json['address'],
      farmLocation: json['farm_location'],
      extraNotes: json['extra_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'birthday': birthday,
      'gender': gender,
      'address': address,
      'farm_location': farmLocation,
      'extra_notes': extraNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? birthday,
    String? gender,
    String? address,
    String? farmLocation,
    String? extraNotes,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      farmLocation: farmLocation ?? this.farmLocation,
      extraNotes: extraNotes ?? this.extraNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
