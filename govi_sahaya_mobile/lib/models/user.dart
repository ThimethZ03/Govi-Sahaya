class User {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final DateTime createdAt;
  final String? photoUrl;
  final String? profileImageUrl; // ADD THIS
  final String? birthday; // ADD THIS
  final String? gender; // ADD THIS
  final String? address; // ADD THIS
  final String? farmLocation; // ADD THIS
  final String? extraNotes; // ADD THIS

  User({
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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      photoUrl: json['photo_url'],
      profileImageUrl: json['profile_image_url'],
      birthday: json['birthday'],
      gender: json['gender'],
      address: json['address'],
      farmLocation: json['farm_location'],
      extraNotes: json['extra_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
      'profile_image_url': profileImageUrl,
      'birthday': birthday,
      'gender': gender,
      'address': address,
      'farm_location': farmLocation,
      'extra_notes': extraNotes,
    };
  }
}
