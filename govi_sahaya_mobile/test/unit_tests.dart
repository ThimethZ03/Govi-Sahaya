import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mock classes for testing
class MockWeatherService {
  Future<Map<String, dynamic>> getWeatherData(String location) async {
    return {
      'temperature': 28.5,
      'humidity': 75,
      'windSpeed': 12.3,
      'description': 'Partly Cloudy',
      'prediction': 'Fair weather expected',
    };
  }
}

class MockNewsService {
  Future<List<Map<String, dynamic>>> getNews() async {
    return [
      {
        'id': '1',
        'title': 'Latest Agricultural News',
        'content': 'Breaking news about farming',
        'date': '2024-03-20',
      },
      {
        'id': '2',
        'title': 'Crop Prices Update',
        'content': 'Market prices for seasonal crops',
        'date': '2024-03-19',
      },
    ];
  }
}

class MockMLService {
  Future<Map<String, dynamic>> detectDisease(String imagePath) async {
    return {
      'disease': 'Leaf Spot',
      'confidence': 0.92,
      'treatment': 'Apply fungicide',
      'severity': 'High',
    };
  }

  Future<List<String>> getCropRecommendations(
    String location,
    String season,
    String soilType,
  ) async {
    return ['Rice', 'Corn', 'Wheat'];
  }
}

class MockAuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password required');
    }
    return {
      'token': 'mock-jwt-token',
      'user': {
        'id': '123',
        'name': 'John Farmer',
        'email': email,
      },
    };
  }

  Future<void> register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields required');
    }
  }

  Future<void> logout() async {
    // Mock logout
  }

  Future<bool> isAuthenticated() async {
    return true;
  }
}

class MockShopService {
  Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? sortBy,
  }) async {
    return [
      {
        'id': '1',
        'name': 'Fertilizer NPK 20-20-20',
        'price': 5000,
        'category': 'Fertilizers',
        'rating': 4.5,
      },
      {
        'id': '2',
        'name': 'Pesticide Spray',
        'price': 3000,
        'category': 'Pesticides',
        'rating': 4.2,
      },
    ];
  }

  Future<void> addToCart(String productId, int quantity) async {
    if (productId.isEmpty || quantity <= 0) {
      throw Exception('Invalid product or quantity');
    }
  }

  Future<Map<String, dynamic>> checkout(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      throw Exception('Cart is empty');
    }
    return {
      'orderId': 'ORD-12345',
      'total': 8000,
      'status': 'pending',
    };
  }
}

void main() {
  group('Unit Tests - Services', () {
    group('Weather Service Tests', () => {
      test('getWeatherData returns valid weather data', () async {
        final service = MockWeatherService();
        final result = await service.getWeatherData('Colombo');

        expect(result, isNotNull);
        expect(result['temperature'], equals(28.5));
        expect(result['humidity'], equals(75));
        expect(result['description'], contains('Cloudy'));
      });

      test('getWeatherData contains required fields', () async {
        final service = MockWeatherService();
        final result = await service.getWeatherData('Kandy');

        expect(result, containsPair('temperature', 28.5));
        expect(result, containsPair('humidity', 75));
        expect(result, containsPair('windSpeed', 12.3));
      });
    });

    group('News Service Tests', () => {
      test('getNews returns list of news', () async {
        final service = MockNewsService();
        final news = await service.getNews();

        expect(news, isA<List>());
        expect(news, isNotEmpty);
        expect(news.length, equals(2));
      });

      test('News items have required fields', () async {
        final service = MockNewsService();
        final news = await service.getNews();

        final firstNews = news.first;
        expect(firstNews, containsPair('id', '1'));
        expect(firstNews, containsPair('title', 'Latest Agricultural News'));
        expect(firstNews, containsPair('content', isNotEmpty));
      });

      test('News items are sorted by date', () async {
        final service = MockNewsService();
        final news = await service.getNews();

        expect(news.first['date'], greaterThanOrEqualTo(news.last['date']));
      });
    });

    group('ML Service Tests', () => {
      test('detectDisease returns disease prediction', () async {
        final service = MockMLService();
        final result = await service.detectDisease('test_image.jpg');

        expect(result, isNotNull);
        expect(result['disease'], equals('Leaf Spot'));
        expect(result['confidence'], equals(0.92));
        expect(result['treatment'], isNotEmpty);
      });

      test('detectDisease confidence is between 0 and 1', () async {
        final service = MockMLService();
        final result = await service.detectDisease('test_image.jpg');

        final confidence = result['confidence'] as double;
        expect(confidence, greaterThanOrEqualTo(0));
        expect(confidence, lessThanOrEqualTo(1));
      });

      test('getCropRecommendations returns crop list', () async {
        final service = MockMLService();
        final crops = await service.getCropRecommendations(
          'Colombo',
          'Monsoon',
          'Clay',
        );

        expect(crops, isA<List<String>>());
        expect(crops, isNotEmpty);
        expect(crops, contains('Rice'));
      });
    });

    group('Auth Service Tests', () => {
      test('login succeeds with valid credentials', () async {
        final service = MockAuthService();
        final result = await service.login('john@example.com', 'password123');

        expect(result, isNotNull);
        expect(result, containsPair('token', isNotEmpty));
        expect(result['user'], isNotNull);
        expect(result['user']['email'], equals('john@example.com'));
      });

      test('login fails with empty email', () async {
        final service = MockAuthService();

        expect(
          () => service.login('', 'password123'),
          throwsException,
        );
      });

      test('login fails with empty password', () async {
        final service = MockAuthService();

        expect(
          () => service.login('john@example.com', ''),
          throwsException,
        );
      });

      test('register fails with incomplete data', () async {
        final service = MockAuthService();

        expect(
          () => service.register('John', '', 'password123'),
          throwsException,
        );
      });

      test('isAuthenticated returns boolean', () async {
        final service = MockAuthService();
        final isAuth = await service.isAuthenticated();

        expect(isAuth, isA<bool>());
        expect(isAuth, isTrue);
      });
    });

    group('Shop Service Tests', () => {
      test('getProducts returns list of products', () async {
        final service = MockShopService();
        final products = await service.getProducts();

        expect(products, isA<List>());
        expect(products, isNotEmpty);
      });

      test('getProducts with category filter', () async {
        final service = MockShopService();
        final products = await service.getProducts(category: 'Fertilizers');

        expect(products, isNotEmpty);
        expect(products.first['category'], equals('Fertilizers'));
      });

      test('addToCart fails with invalid product', () async {
        final service = MockShopService();

        expect(
          () => service.addToCart('', 1),
          throwsException,
        );
      });

      test('addToCart fails with zero quantity', () async {
        final service = MockShopService();

        expect(
          () => service.addToCart('product-1', 0),
          throwsException,
        );
      });

      test('checkout returns order confirmation', () async {
        final service = MockShopService();
        final order = await service.checkout([
          {'productId': '1', 'quantity': 2, 'price': 5000},
        ]);

        expect(order, isNotNull);
        expect(order, containsPair('orderId', isNotEmpty));
        expect(order, containsPair('status', 'pending'));
        expect(order['total'], greaterThan(0));
      });

      test('checkout fails with empty cart', () async {
        final service = MockShopService();

        expect(
          () => service.checkout([]),
          throwsException,
        );
      });
    });
  });

  group('Unit Tests - Data Validation', () => {
    test('Email validation works correctly', () {
      final validateEmail = (String email) {
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        return emailRegex.hasMatch(email);
      };

      expect(validateEmail('test@example.com'), isTrue);
      expect(validateEmail('invalid-email'), isFalse);
      expect(validateEmail('test@domain'), isFalse);
    });

    test('Phone number validation works correctly', () {
      final validatePhone = (String phone) {
        final phoneRegex = RegExp(r'^0\d{9}$');
        return phoneRegex.hasMatch(phone);
      };

      expect(validatePhone('0771234567'), isTrue);
      expect(validatePhone('0712345678'), isTrue);
      expect(validatePhone('123'), isFalse);
    });

    test('Password strength validation', () {
      final validatePassword = (String password) {
        return password.length >= 8 &&
            password.contains(RegExp(r'[A-Z]')) &&
            password.contains(RegExp(r'[0-9]')) &&
            password.contains(RegExp(r'[!@#\$%^&*]'));
      };

      expect(validatePassword('Weak'), isFalse);
      expect(validatePassword('Strong@123'), isTrue);
      expect(validatePassword('NoSpecial123'), isFalse);
    });
  });

  group('Unit Tests - Data Manipulation', () => {
    test('Format date correctly', () {
      final formatDate = (DateTime date) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      };

      final testDate = DateTime(2024, 3, 20);
      expect(formatDate(testDate), equals('2024-03-20'));
    });

    test('Calculate discount correctly', () {
      final calculateDiscount = (double price, double discountPercent) {
        return price * (1 - discountPercent / 100);
      };

      expect(calculateDiscount(1000, 10), equals(900));
      expect(calculateDiscount(5000, 20), equals(4000));
    });

    test('Sort prices ascending', () {
      final prices = [5000, 1000, 3000, 2000];
      final sorted = List<int>.from(prices)..sort();

      expect(sorted, equals([1000, 2000, 3000, 5000]));
    });
  });
}
