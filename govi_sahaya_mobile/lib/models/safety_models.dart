// lib/models/safety_models.dart

class EmergencyContact {
  final String id, name, nameSi, nameTa, number, category, color;
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.nameSi,
    required this.nameTa,
    required this.number,
    required this.category,
    required this.color,
  });
  factory EmergencyContact.fromJson(Map<String, dynamic> j) => EmergencyContact(
        id: j['id'],
        name: j['name'],
        nameSi: j['nameSi'],
        nameTa: j['nameTa'],
        number: j['number'],
        category: j['category'],
        color: j['color'],
      );
}

class FirstAidGuide {
  final String id, title, titleSi, titleTa, icon, color, category;
  final List<String> symptoms, symptomsSi, symptomsTa;
  final List<String> steps, stepsSi, stepsTa;
  final List<String> doNot, doNotSi, doNotTa;

  const FirstAidGuide({
    required this.id,
    required this.title,
    required this.titleSi,
    required this.titleTa,
    required this.icon,
    required this.color,
    required this.category,
    required this.symptoms,
    required this.symptomsSi,
    required this.symptomsTa,
    required this.steps,
    required this.stepsSi,
    required this.stepsTa,
    required this.doNot,
    required this.doNotSi,
    required this.doNotTa,
  });

  factory FirstAidGuide.fromJson(Map<String, dynamic> j) => FirstAidGuide(
        id: j['id'],
        title: j['title'],
        titleSi: j['titleSi'],
        titleTa: j['titleTa'],
        icon: j['icon'],
        color: j['color'],
        category: j['category'],
        symptoms: List<String>.from(j['symptoms'] ?? []),
        symptomsSi: List<String>.from(j['symptomsSi'] ?? []),
        symptomsTa: List<String>.from(j['symptomsTa'] ?? []),
        steps: List<String>.from(j['steps'] ?? []),
        stepsSi: List<String>.from(j['stepsSi'] ?? []),
        stepsTa: List<String>.from(j['stepsTa'] ?? []),
        doNot: List<String>.from(j['doNot'] ?? []),
        doNotSi: List<String>.from(j['doNotSi'] ?? []),
        doNotTa: List<String>.from(j['doNotTa'] ?? []),
      );
}

class SafetyTip {
  final String id, title, titleSi, titleTa;
  final String description, descriptionSi, descriptionTa;
  final String icon, color, category;

  const SafetyTip({
    required this.id,
    required this.title,
    required this.titleSi,
    required this.titleTa,
    required this.description,
    required this.descriptionSi,
    required this.descriptionTa,
    required this.icon,
    required this.color,
    required this.category,
  });

  factory SafetyTip.fromJson(Map<String, dynamic> j) => SafetyTip(
        id: j['id'],
        title: j['title'],
        titleSi: j['titleSi'],
        titleTa: j['titleTa'],
        description: j['description'],
        descriptionSi: j['descriptionSi'],
        descriptionTa: j['descriptionTa'],
        icon: j['icon'],
        color: j['color'],
        category: j['category'],
      );
}

class NearbyHospital {
  final String id, name, address;
  final String? phone, distance, duration;
  final double lat, lng;
  final double? rating;
  final bool? isOpen;

  const NearbyHospital({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.distance,
    this.duration,
    this.rating,
    this.isOpen,
  });

  factory NearbyHospital.fromJson(Map<String, dynamic> j) => NearbyHospital(
        id: j['id'],
        name: j['name'],
        address: j['address'] ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        phone: j['phone'],
        distance: j['distance'],
        duration: j['duration'],
        rating: j['rating'] != null ? (j['rating'] as num).toDouble() : null,
        isOpen: j['isOpen'],
      );
}
