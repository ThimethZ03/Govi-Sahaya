import 'package:dio/dio.dart';
import '../models/guide_model.dart';
import '../config/constants.dart';

class KnowledgeHubService {
  final Dio _dio = Dio();

  Future<List<GuideModel>> getGuides({String? category}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.guidesEndpoint}',
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => GuideModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load guides');
      }
    } catch (e) {
      return _getDummyGuides(category);
    }
  }

  List<GuideModel> _getDummyGuides(String? category) {
    final allGuides = [
      GuideModel(
        id: '1',
        title: 'How to prepare compost at home',
        titleSinhala: 'ගෙදර කොම්පෝස්ට් සකස් කරන්නේ කෙසේද',
        content: 'Step-by-step guide to prepare organic compost...',
        category: 'Soil',
        imageUrl: '',
        createdAt: DateTime.now(),
        tags: ['compost', 'organic', 'soil'],
      ),
      GuideModel(
        id: '2',
        title: 'Best practices for tomato cultivation',
        titleSinhala: 'තක්කාලි වගාව සඳහා හොඳම පිළිවෙත්',
        content: 'Complete guide for growing healthy tomatoes...',
        category: 'Vegetables',
        imageUrl: '',
        createdAt: DateTime.now(),
        tags: ['tomato', 'vegetables', 'cultivation'],
      ),
      GuideModel(
        id: '3',
        title: 'Organic pest control methods',
        titleSinhala: 'කාබනික පළිබෝධ පාලන ක්‍රම',
        content: 'Natural ways to control pests without chemicals...',
        category: 'Pest',
        imageUrl: '',
        createdAt: DateTime.now(),
        tags: ['pest', 'organic', 'control'],
      ),
    ];

    if (category != null) {
      return allGuides.where((g) => g.category == category).toList();
    }
    return allGuides;
  }
}
