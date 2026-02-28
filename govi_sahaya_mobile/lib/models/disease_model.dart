class DiseaseModel {
  final String id;
  final String name;
  final String nameSinhala;
  final String cropName;

  final String description; // ✅ MUST EXIST
  final String cause; // ✅ from backend
  final String solution; // ✅ from backend
  final String prevention; // ✅ from backend
  final List<String> recommendations; // ✅ emojis list

  final String imageUrl;
  final double confidence;
  final String riskLevel;

  // optional (if you want)
  final String organicTreatment;
  final String chemicalTreatment;
  final String predictedClass;

  DiseaseModel({
    required this.id,
    required this.name,
    required this.nameSinhala,
    required this.cropName,
    required this.description,
    required this.cause,
    required this.solution,
    required this.prevention,
    required this.recommendations,
    required this.imageUrl,
    required this.confidence,
    required this.riskLevel,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.predictedClass,
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    // recommendations can come as List<dynamic> or missing
    final recRaw = json['recommendations'];
    final recList = (recRaw is List)
        ? recRaw.map((e) => e.toString()).toList()
        : <String>[];

    return DiseaseModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nameSinhala: (json['name_sinhala'] ?? '').toString(),
      cropName: (json['crop_name'] ?? '').toString(),

      // ✅ IMPORTANT: these are the fields your UI is reading
      description: (json['description'] ?? '').toString(),
      cause: (json['cause'] ?? '').toString(),
      solution: (json['solution'] ?? '').toString(),
      prevention: (json['prevention'] ?? '').toString(),
      recommendations: recList,

      imageUrl: (json['image_url'] ?? '').toString(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      riskLevel: (json['risk_level'] ?? 'Medium').toString(),

      // ✅ keep these for compatibility (your backend sends these too)
      organicTreatment: (json['organic_treatment'] ?? '').toString(),
      chemicalTreatment: (json['chemical_treatment'] ?? '').toString(),
      predictedClass: (json['class'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_sinhala': nameSinhala,
      'crop_name': cropName,
      'description': description,
      'cause': cause,
      'solution': solution,
      'prevention': prevention,
      'recommendations': recommendations,
      'image_url': imageUrl,
      'confidence': confidence,
      'risk_level': riskLevel,
      'organic_treatment': organicTreatment,
      'chemical_treatment': chemicalTreatment,
      'class': predictedClass,
    };
  }
}
