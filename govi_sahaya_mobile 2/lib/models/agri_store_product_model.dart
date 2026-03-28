class AgriStoreProduct {
  final String id;
  final String name;
  final String nameSinhala;
  final String nameTamil;
  final String category;
  final String categorySinhala;
  final String categoryTamil;
  final String description;
  final String descriptionSinhala;
  final String descriptionTamil;
  final String imageUrl;
  final String sourceUrl; // CS Agro deep-link
  final String sourceName; // e.g. "CS Agro"
  final double? priceFrom; // approximate starting price (LKR)
  final bool isFeatured;
  final bool isOrganic;
  final List<String> tags;

  const AgriStoreProduct({
    required this.id,
    required this.name,
    required this.nameSinhala,
    required this.nameTamil,
    required this.category,
    required this.categorySinhala,
    required this.categoryTamil,
    required this.description,
    required this.descriptionSinhala,
    required this.descriptionTamil,
    required this.imageUrl,
    required this.sourceUrl,
    required this.sourceName,
    this.priceFrom,
    this.isFeatured = false,
    this.isOrganic = false,
    this.tags = const [],
  });
}
