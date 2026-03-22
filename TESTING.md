# Govi Sahaya - Complete Testing Documentation

## Project Overview
This document provides comprehensive testing guidance for both the **Backend (Node.js/Express)** and **Frontend (Flutter)** components of the Govi Sahaya agricultural platform.

---

## 📋 Table of Contents
1. [Backend Testing](#backend-testing)
2. [Frontend Testing](#frontend-testing)
3. [Test Coverage Reports](#test-coverage-reports)
4. [CI/CD Integration](#cicd-integration)
5. [Best Practices](#best-practices)

---

## 🧪 Backend Testing

### Setup
```bash
cd govi_sahaya_backend
npm install
```

### Test Structure
```
tests/
├── unit/                    # Unit tests for individual components
│   ├── authController.test.js
│   ├── userController.test.js
│   ├── weatherService.test.js
│   ├── utilities.test.js
│   └── ml.test.js
├── integration/            # Integration tests for API endpoints
│   ├── api.test.js
│   └── database.test.js
└── fixtures/              # Test data and mocks
```

### Running Backend Tests

#### Run all tests
```bash
npm test
```

#### Run tests in watch mode
```bash
npm run test:watch
```

#### Run tests with coverage
```bash
npm test -- --coverage
```

#### Run specific test file
```bash
npm test -- authController.test.js
```

#### Run tests matching pattern
```bash
npm test -- --testNamePattern="login"
```

### Test Categories

#### 1. **Unit Tests**
Test individual functions and classes in isolation.

**Coverage:**
- Controllers (auth, user, weather, etc.)
- Services (email, ML, news, etc.)
- Utilities (validators, formatters, etc.)
- Middleware

**Running unit tests:**
```bash
npm test -- tests/unit
```

#### 2. **Integration Tests**
Test complete API flows and database interactions.

**Coverage:**
- Authentication endpoints (register, login, logout)
- User endpoints (profile CRUD operations)
- Weather data retrieval
- Health checks

**Running integration tests:**
```bash
npm test -- tests/integration
```

#### 3. **Service Tests**
Test business logic in services.

**Example service test:**
```javascript
describe('Weather Service', () => {
  test('should fetch weather data', async () => {
    const result = await weatherService.fetchWeatherByDistrict('Colombo');
    expect(result).toHaveProperty('temperature');
  });
});
```

### Jest Configuration
The `jest.config.js` file includes:
- Test environment: Node.js
- Coverage collection from `src/` directory
- Test timeout: 10 seconds
- Setup file for environment variables

### Code Coverage Targets
- Overall coverage: > 80%
- Controllers: > 85%
- Services: > 85%
- Utilities: > 90%

### View Coverage Report
```bash
npm test -- --coverage --collectCoverageFrom="src/**/*.js"
# Open coverage/lcov-report/index.html in browser
```

---

## 📱 Frontend Testing

### Setup
```bash
cd govi_sahaya_mobile
flutter pub get
```

### Test Structure
```
test/
├── widget_tests.dart       # Widget and UI tests
├── unit_tests.dart         # Service and data model tests
└── integration_tests.dart  # Complete user flow tests
```

### Running Frontend Tests

#### Run all tests
```bash
flutter test
```

#### Run tests in watch mode
```bash
flutter test --watch
```

#### Run specific test file
```bash
flutter test test/widget_tests.dart
```

#### Run tests with code coverage
```bash
flutter test --coverage
```

#### View coverage report
```bash
# Generate coverage (requires lcov)
flutter test --coverage
# On macOS/Linux
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Categories

#### 1. **Widget Tests**
Test Flutter UI widgets and user interactions.

**Test files:**
- `widget_tests.dart` - Splash, Auth, Home screens

**Features tested:**
- Widget rendering
- User interactions (tap, text input)
- Navigation
- Error dialogs
- ListView scrolling

**Example:**
```dart
testWidgets('Login screen displays input fields', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.byType(TextField), findsWidgets);
  await tester.enterText(find.byType(TextField), 'test@example.com');
  expect(find.text('test@example.com'), findsOneWidget);
});
```

#### 2. **Unit Tests**
Test services, providers, and business logic.

**Test files:**
- `unit_tests.dart` - Weather, News, ML, Auth, Shop services

**Features tested:**
- Service methods
- Data validation
- Error handling
- Data manipulation

**Services covered:**
- WeatherService
- NewsService
- MLService (disease detection, crop recommendations)
- AuthService
- ShopService

#### 3. **Integration Tests**
Test complete user flows and multi-screen interactions.

**Test files:**
- `integration_tests.dart` - Complete workflows

**Flows tested:**
- Authentication (signup, login, logout)
- Home screen data loading
- Shopping (search, add to cart, checkout)
- Forum (view threads, create thread, reply)
- Navigation between screens

### Code Coverage Targets
- Overall coverage: > 70%
- Widget tests coverage: > 75%
- Service tests coverage: > 80%

---

## 📊 Test Coverage Reports

### Backend Coverage Report
After running tests with coverage:
```bash
npm test -- --coverage
```

Expected output includes:
- Statement coverage: % of code statements executed
- Branch coverage: % of conditional branches tested
- Function coverage: % of functions tested
- Line coverage: % of lines executed

### Frontend Coverage Report
After running tests with coverage:
```bash
flutter test --coverage
```

View the HTML report:
```bash
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

---

## 🔄 CI/CD Integration

### GitHub Actions Setup
Add to `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd govi_sahaya_backend && npm install
      - run: cd govi_sahaya_backend && npm test

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd govi_sahaya_mobile && flutter pub get
      - run: cd govi_sahaya_mobile && flutter test
```

---

## ✅ Best Practices

### General Testing Principles
1. **Test Naming**: Use descriptive test names
   ```javascript
   // Good
   test('should return user profile when user exists', async () => {})
   
   // Bad
   test('test user profile', async () => {})
   ```

2. **Single Responsibility**: Each test should verify one thing
   ```javascript
   // Good
   test('should return 404 when user not found', () => {})
   test('should return user data when user exists', () => {})
   
   // Bad
   test('should handle user retrieval', () => {})
   ```

3. **Arrange-Act-Assert Pattern**:
   ```javascript
   test('should update user profile', async () => {
     // Arrange
     const user = { id: '123', name: 'John' };
     User.findById = jest.fn().mockResolvedValue(user);
     
     // Act
     const result = await updateProfile(user.id, { name: 'Jane' });
     
     // Assert
     expect(result.name).toBe('Jane');
   });
   ```

4. **Mock External Dependencies**:
   ```javascript
   jest.mock('../../src/models/User');
   jest.mock('../../src/services/emailService');
   ```

5. **Clean Up After Tests**:
   ```javascript
   beforeEach(() => {
     jest.clearAllMocks();
   });
   
   afterAll(async () => {
     // Close connections, clean up
   });
   ```

### Backend-Specific Best Practices

1. **Mock Database Operations**:
   ```javascript
   User.findById = jest.fn().mockResolvedValue(mockUser);
   ```

2. **Test Error Cases**:
   ```javascript
   test('should handle database errors', async () => {
     User.findById = jest.fn()
       .mockRejectedValue(new Error('DB Error'));
     
     const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
     await controller.getProfile(req, res);
     
     expect(res.status).toHaveBeenCalledWith(500);
   });
   ```

3. **Test Authentication Middleware**:
   ```javascript
   test('should protect authenticated routes', () => {
     const req = { user: { id: '123' } };
     const res = { status: jest.fn(), json: jest.fn() };
     
     protect(req, res, () => {
       expect(req.user).toBeDefined();
     });
   });
   ```

### Frontend-Specific Best Practices

1. **Use WidgetTester for UI Tests**:
   ```dart
   testWidgets('Button responds to tap', (WidgetTester tester) async {
     await tester.pumpWidget(MyApp());
     await tester.tap(find.byType(ElevatedButton));
     await tester.pump();
   });
   ```

2. **Mock Services in Unit Tests**:
   ```dart
   final mockService = MockWeatherService();
   final result = await mockService.getWeatherData('Colombo');
   expect(result['temperature'], equals(28.5));
   ```

3. **Test Error Scenarios**:
   ```dart
   test('service throws exception on error', () async {
     expect(
       () => mockService.failingMethod(),
       throwsException,
     );
   });
   ```

4. **Verify Navigation**:
   ```dart
   testWidgets('navigates to home on login', (WidgetTester tester) async {
     await tester.pumpWidget(MyApp());
     await tester.tap(find.byText('Login'));
     await tester.pumpAndSettle();
     expect(find.byType(HomePage), findsOneWidget);
   });
   ```

---

## 🚀 Running Full Test Suite

### Backend
```bash
cd govi_sahaya_backend
npm install
npm test -- --coverage --verbose
```

### Frontend
```bash
cd govi_sahaya_mobile
flutter pub get
flutter test --coverage
```

### Combined
```bash
# Run from project root
./run-all-tests.sh
```

---

## 📈 Continuous Improvement

### Metrics to Track
- Code coverage percentage
- Test execution time
- Number of failing tests
- Number of flaky tests (tests that sometimes fail)
- Code quality score

### Regular Review
1. Review test failures in CI/CD pipeline
2. Update tests when features change
3. Add tests for new bug fixes
4. Refactor tests to reduce duplication
5. Monitor and improve coverage

---

## 🆘 Troubleshooting

### Backend Issues
**Tests timing out?**
```bash
npm test -- --testTimeout=20000
```

**Clear Jest cache:**
```bash
npm test -- --clearCache
```

**Module not found?**
```bash
npm install
```

### Frontend Issues
**Tests not running?**
```bash
flutter clean
flutter pub get
flutter test
```

**Widget test failing?**
- Use `tester.pumpAndSettle()` instead of `pump()`
- Wait for animations: `await tester.pumpAndSettle()`

---

## 📞 Support

For issues or questions about testing:
1. Check Jest documentation: https://jestjs.io
2. Check Flutter test docs: https://flutter.dev/docs/testing
3. Review existing tests for examples
4. Check project GitHub issues

---

**Last Updated**: March 2024
**Maintained by**: Govi Sahaya Team
