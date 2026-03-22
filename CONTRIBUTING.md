# 👥 Contributing to Govi Sahaya

First off, thank you for considering contributing to Govi Sahaya! It's people like you that make Govi Sahaya such a great platform for farmers.

## 🎯 What We're Looking For

We welcome contributions in many forms:

- 🐛 **Bug Reports** - Found a bug? Let us know!
- ✨ **Feature Requests** - Have an idea? We'd love to hear it
- 📝 **Documentation** - Improve our guides and docs
- 💻 **Code** - Submit pull requests with improvements
- 🧪 **Tests** - Write tests for better coverage
- 🎨 **Design** - UI/UX improvements
- 🌍 **Translations** - Help reach more farmers

---

## 🚀 Getting Started

### 1. Fork the Repository

Click the **Fork** button at the top right of the repository.

```bash
# Click "Fork" on GitHub UI
```

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/govi-sahaya.git
cd Govi-Sahaya
```

### 3. Set Up Development Environment

Follow the [QUICKSTART.md](./QUICKSTART.md) guide to set up your local environment.

### 4. Create a Branch

```bash
# For features
git checkout -b feature/amazing-feature

# For bug fixes
git checkout -b bugfix/issue-description

# For documentation
git checkout -b docs/updated-guides
```

**Branch naming conventions:**
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `docs/*` - Documentation updates
- `test/*` - Test improvements
- `refactor/*` - Code refactoring

---

## 💻 Making Changes

### Code Standards

#### Backend (Node.js/Express)
```javascript
// ✅ Good - Clear and documented
/**
 * Get user profile
 * @param {Object} req - Express request
 * @returns {Promise} User profile data
 */
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false });
    }
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    logger.error('Error:', error);
    res.status(500).json({ success: false });
  }
};

// ❌ Bad - Unclear, no error handling
exports.getProfile = (req, res) => {
  User.findById(req.user.id).then(user => {
    res.json(user);
  });
};
```

**Code style rules:**
- Use ESLint (configured)
- 2-space indentation
- Semicolons required
- CamelCase for variables
- PascalCase for classes/models
- UPPER_CASE for constants
- Add JSDoc comments for functions
- Handle errors properly
- Log important events

#### Frontend (Flutter/Dart)
```dart
// ✅ Good - Clear and documented
/// Fetches user profile from API
/// 
/// Returns user profile data or null if not found
Future<UserProfile?> getUserProfile(String userId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    return null;
  } catch (e) {
    logger.error('Error fetching profile: $e');
    return null;
  }
}

// ❌ Bad - Unclear, no error handling
getProfile(id) {
  return http.get('$baseUrl/users/$id');
}
```

**Code style rules:**
- Follow Dart conventions
- Use meaningful names
- Document public methods
- Handle nullability
- Use const constructors
- Proper error handling
- Add tests for new features

---

## 🧪 Writing Tests

### Backend Tests
```javascript
describe('User Controller', () => {
  test('should get user profile', async () => {
    // Arrange
    const userId = '123';
    User.findById = jest.fn().mockResolvedValue({ id: userId, name: 'John' });
    
    // Act
    const result = await getProfile(userId);
    
    // Assert
    expect(result).toBeDefined();
    expect(result.id).toBe(userId);
  });
});
```

### Frontend Tests
```dart
testWidgets('Login button navigates to home', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  expect(find.byType(HomePage), findsOneWidget);
});
```

**Test requirements:**
- Write tests for new features
- Maintain >80% code coverage
- Include both happy path and error cases
- Use descriptive test names

---

## 📝 Commit Messages

Write clear, descriptive commit messages:

```bash
# Good format
git commit -m "Add disease detection feature for tomato crops

- Implement ML model integration
- Create detection API endpoint
- Add error handling
- Write unit tests with 90% coverage

Fixes #123"

# Bad format
git commit -m "fix stuff"
git commit -m "updated"
```

**Commit message guidelines:**
- First line: 50 characters, summary in imperative mood
- Blank line
- Detailed explanation (if needed)
- Reference issues: `Fixes #123`
- One logical change per commit

---

## 🔄 Submitting a Pull Request

### Before Submitting

1. **Test your changes**
   ```bash
   npm test              # Backend
   flutter test         # Frontend
   ```

2. **Format your code**
   ```bash
   npm run lint:fix     # Backend
   dart format lib/    # Frontend
   ```

3. **Update documentation**
   - Update README if needed
   - Add inline comments
   - Update CHANGELOG

4. **Make sure tests pass**
   - All tests green ✅
   - Coverage maintained
   - No linting errors

### Creating the Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill in the PR template:

```markdown
## Description
Brief description of your changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Added tests
- [ ] Updated tests
- [ ] All tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added (where needed)
- [ ] Documentation updated
- [ ] No new warnings generated

## Related Issues
Fixes #123

## Screenshots (if applicable)
Add screenshots for UI changes
```

---

## ✅ Code Review Process

### What Reviewers Look For

1. **Code Quality**
   - Follows style guidelines
   - No duplicated code
   - Proper error handling
   - Clear variable names

2. **Functionality**
   - Changes work as expected
   - Handles edge cases
   - Doesn't break existing features

3. **Tests**
   - Tests are included
   - Tests are meaningful
   - Coverage is adequate

4. **Documentation**
   - Code is documented
   - README updated if needed
   - Comments explain why, not what

5. **Performance**
   - No unnecessary network calls
   - Queries are optimized
   - Memory usage is reasonable

### Responding to Feedback

- Be respectful and professional
- Ask questions if unclear
- Push changes to the same branch
- Respond to all comments
- Resolve conversations once addressed

---

## 🎓 Development Workflow Example

### Feature: Add Push Notifications

```bash
# 1. Create feature branch
git checkout -b feature/push-notifications

# 2. Install dependencies
npm install           # Backend
flutter pub get      # Frontend

# 3. Code the feature
# - Edit files
# - Create new files
# - Add tests

# 4. Run tests
npm test             # Backend
flutter test        # Frontend

# 5. Format code
npm run lint:fix     # Backend
dart format lib/    # Frontend

# 6. Commit changes
git add .
git commit -m "Add push notification system

- Integrate Firebase Cloud Messaging
- Create notification service
- Add user notification preferences
- Write tests with 85% coverage

Fixes #456"

# 7. Push to GitHub
git push origin feature/push-notifications

# 8. Open Pull Request on GitHub UI
# Fill in the PR template
# Wait for review

# 9. Address feedback
# Make requested changes
# Commit and push again

# 10. Merge!
# Reviewer merges your PR
```

---

## 📚 Understanding the Codebase

### Backend Structure
```
govi_sahaya_backend/
├── src/
│   ├── controllers/    ← Handle requests
│   ├── routes/         ← Define endpoints
│   ├── models/         ← Database schemas
│   ├── services/       ← Business logic
│   ├── middleware/     ← Request processing
│   └── utils/          ← Helper functions
```

### Frontend Structure
```
govi_sahaya_mobile/lib/
├── screens/     ← UI pages
├── widgets/     ← Reusable components
├── providers/   ← State management
├── services/    ← API calls
├── models/      ← Data classes
└── utils/       ← Helper functions
```

### Key Concepts

**Backend:**
- Express.js for routing
- Mongoose for database
- JWT for authentication
- Firebase for services

**Frontend:**
- Provider for state management
- Dio for HTTP requests
- Firebase for auth & notifications
- Google Maps for location

---

## 🐛 Reporting Issues

Found a bug? Please create an issue with:

1. **Clear Title**
   ```
   ✅ "Login button doesn't work on iOS"
   ❌ "app broken"
   ```

2. **Detailed Description**
   - What were you doing?
   - What happened?
   - What should happen?

3. **Steps to Reproduce**
   ```
   1. Go to login screen
   2. Enter credentials
   3. Click login button
   4. See error message
   ```

4. **Environment**
   - OS & version
   - App version
   - Device/Browser

5. **Screenshots/Logs**
   - Error messages
   - Console logs
   - Network requests

---

## 💡 Feature Request Template

Have an idea? Submit a feature request:

```markdown
## Is your feature request related to a problem?
A clear description of what the problem is.

## Describe the solution you'd like
Clear description of what you want to happen.

## Describe alternatives you've considered
Alternative solutions or features.

## Additional context
Any other context or screenshots.
```

---

## 🤝 Community Guidelines

### Be Respectful
- Use inclusive language
- Be helpful to others
- Accept constructive criticism
- Respect different viewpoints

### No Harassment
- No discrimination
- No profanity
- No aggressive behavior
- No spam

### Report Issues
- Use GitHub to report problems
- Be specific and factual
- Don't post in wrong channels

---

## 🎁 Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes
- Monthly newsletter
- Special badges on GitHub

### Hall of Fame
Contributors with 10+ merged PRs are added to our Hall of Fame!

---

## 💬 Questions?

Can't figure something out?

- 📖 Check [README.md](./README.md)
- ⚡ Check [QUICKSTART.md](./QUICKSTART.md)
- 🐛 Check existing [Issues](https://github.com/govi-sahaya/govi-sahaya/issues)
- 💬 Start a [Discussion](https://github.com/govi-sahaya/govi-sahaya/discussions)
- 📧 Email: hello@govisahaya.lk

---

## 📝 License

By contributing, you agree that your contributions will be licensed under its MIT License.

---

<div align="center">

**Thank you for contributing to Govi Sahaya!** 🙏

Help us build the best agriculture platform for farmers.

</div>
