class DiseaseModel {
  final String id;
  final String name;
  final String nameSinhala;
  final String cropName;
  final String description;
  final String organicTreatment;
  final String chemicalTreatment;
  final String imageUrl;
  final double confidence;
  final String riskLevel;

  DiseaseModel({
    required this.id,
    required this.name,
    required this.nameSinhala,
    required this.cropName,
    required this.description,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.imageUrl,
    required this.confidence,
    required this.riskLevel,
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    return DiseaseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameSinhala: json['name_sinhala'] ?? '',
      cropName: json['crop_name'] ?? '',
      description: json['description'] ?? '',
      organicTreatment: json['organic_treatment'] ?? '',
      chemicalTreatment: json['chemical_treatment'] ?? '',
      imageUrl: json['image_url'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      riskLevel: json['risk_level'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_sinhala': nameSinhala,
      'crop_name': cropName,
      'description': description,
      'organic_treatment': organicTreatment,
      'chemical_treatment': chemicalTreatment,
      'image_url': imageUrl,
      'confidence': confidence,
      'risk_level': riskLevel,
    };
  }
}
