class ShopItemModel {
  final String id;
  final String name;
  final String nameSinhala;
  final String category;
  final String description;
  final double price;
  final String unit;
  final String imageUrl;
  final bool inStock;
  final double rating;
  final int reviewCount;

  ShopItemModel({
    required this.id,
    required this.name,
    required this.nameSinhala,
    required this.category,
    required this.description,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.inStock,
    required this.rating,
    required this.reviewCount,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameSinhala: json['name_sinhala'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? 'kg',
      imageUrl: json['image_url'] ?? '',
      inStock: json['in_stock'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_sinhala': nameSinhala,
      'category': category,
      'description': description,
      'price': price,
      'unit': unit,
      'image_url': imageUrl,
      'in_stock': inStock,
      'rating': rating,
      'review_count': reviewCount,
    };
  }
}
