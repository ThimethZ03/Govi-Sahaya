import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../models/shop_item_model.dart';

class ShopProvider with ChangeNotifier {
  final ShopService _shopService = ShopService();

  List<ShopItemModel> _shopItems = [];
  final List<ShopItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ShopItemModel> get shopItems => _shopItems;
  List<ShopItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get cartCount => _cartItems.length;
  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + item.price);

  // Fetch shop items
  Future<void> fetchShopItems({String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shopItems = await _shopService.getShopItems(category: category);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add to cart
  void addToCart(ShopItemModel item) {
    _cartItems.add(item);
    notifyListeners();
  }

  // Remove from cart
  void removeFromCart(ShopItemModel item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Check if item in cart
  bool isInCart(ShopItemModel item) {
    return _cartItems.any((cartItem) => cartItem.id == item.id);
  }
}
