import 'dart:io';
import 'package:dio/dio.dart';
import '../models/disease_model.dart';
import '../config/constants.dart';

class MLService {
  final Dio _dio = Dio();

  Future<DiseaseModel> predictDisease(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '${AppConstants.baseUrl}${AppConstants.predictEndpoint}',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return DiseaseModel.fromJson(response.data);
      } else {
        throw Exception('Prediction failed');
      }
    } catch (e) {
      return _getDummyPrediction();
    }
  }

  DiseaseModel _getDummyPrediction() {
    return DiseaseModel(
      id: '1',
      name: 'Leaf Blight',
      nameSinhala: 'කොළ මරණ රෝගය',
      cropName: 'Rice',
      description: 'A fungal disease affecting rice leaves causing brown spots',
      organicTreatment:
          'Apply neem oil solution (5ml per liter of water) weekly. Remove and destroy infected leaves. Ensure proper spacing between plants for air circulation. Use compost tea as a preventive spray.',
      chemicalTreatment:
          'Use copper-based fungicide (Copper oxychloride 50% WP) at 3g per liter of water. Apply every 10 days until symptoms disappear. Alternative: Mancozeb 75% WP at 2g per liter.',
      imageUrl: '',
      confidence: 0.87,
      riskLevel: 'Medium',
    );
  }
}
