import 'package:dio/dio.dart';
import '../models/shop_item_model.dart';
import '../config/constants.dart';

class ShopService {
  final Dio _dio = Dio();

  Future<List<ShopItemModel>> getShopItems({String? category}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.shopItemsEndpoint}',
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ShopItemModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shop items');
      }
    } catch (e) {
      return _getDummyShopItems(category);
    }
  }

  List<ShopItemModel> _getDummyShopItems(String? category) {
    final allItems = [
      ShopItemModel(
        id: '1',
        name: 'Organic Fertilizer',
        nameSinhala: 'කාබනික පොහොර',
        category: 'Fertilizer',
        description: 'High quality organic fertilizer for all crops',
        price: 2500.00,
        unit: 'kg',
        imageUrl: '',
        inStock: true,
        rating: 4.5,
        reviewCount: 128,
      ),
      ShopItemModel(
        id: '2',
        name: 'Rice Seeds - Premium',
        nameSinhala: 'වී බීජ - ප්‍රිමියම්',
        category: 'Seeds',
        description: 'High yield rice seeds',
        price: 500.00,
        unit: 'kg',
        imageUrl: '',
        inStock: true,
        rating: 4.8,
        reviewCount: 256,
      ),
      ShopItemModel(
        id: '3',
        name: 'Drip Irrigation Kit',
        nameSinhala: 'ජල පහසුකම් කට්ටලය',
        category: 'Equipment',
        description: 'Complete drip irrigation system',
        price: 15000.00,
        unit: 'set',
        imageUrl: '',
        inStock: true,
        rating: 4.3,
        reviewCount: 64,
      ),
    ];

    if (category != null) {
      return allItems.where((item) => item.category == category).toList();
    }
    return allItems;
  }
}
