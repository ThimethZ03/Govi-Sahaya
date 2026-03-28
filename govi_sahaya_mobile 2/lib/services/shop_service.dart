import 'package:dio/dio.dart';
import '../models/shop_item_model.dart';
import '../core/network/api_endpoints.dart';

class ShopService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Get shop items
  Future<List<ShopItemModel>> getShopItems({String? category}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.shopItems, // ✅ full URL from ApiEndpoints
        queryParameters: category != null ? {'category': category} : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ Handle both { data: [...] } and [...] response shapes
        final List<dynamic> list =
            data is Map ? (data['data'] ?? data['items'] ?? []) : data;

        return list.map((json) => ShopItemModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shop items');
      }
    } catch (e) {
      return _getDummyShopItems(category);
    }
  }

  // Get single shop item
  Future<ShopItemModel?> getShopItemById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.shopItemDetail(id));

      if (response.statusCode == 200) {
        final data = response.data;
        final json = data is Map && data['data'] != null ? data['data'] : data;
        return ShopItemModel.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
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
