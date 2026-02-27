import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INVITE FRIENDS
// ─────────────────────────────────────────────────────────────────────────────
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  static const String _inviteLink = 'https://govisahaya.lk/invite';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Invite Friends',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.people_alt_outlined,
                            size: 44, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Invite Your Farming Friends',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Share Govi Sahaya with fellow farmers\nand grow together!',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Link box
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.link,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                _inviteLink,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    const ClipboardData(text: _inviteLink));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Link copied!'),
                                    backgroundColor: AppTheme.primaryGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Copy',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RATE US
// ─────────────────────────────────────────────────────────────────────────────
class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Rate Us',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child:
                    _submitted ? _buildThankYou() : _buildRatingForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded,
                size: 48, color: Color(0xFFF57F17)),
          ),
          const SizedBox(height: 20),
          const Text('Enjoying Govi Sahaya?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Your feedback helps us improve',
              style: TextStyle(fontSize: 14, color: AppTheme.textLight)),
          const SizedBox(height: 28),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    _rating >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: _rating >= star ? 44 : 38,
                    color: _rating >= star
                        ? const Color(0xFFF57F17)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _rating == 0
                ? 'Tap to rate'
                : ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent!'][_rating],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _rating > 0 ? const Color(0xFFF57F17) : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 24),
          // Feedback box
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell us what you think (optional)',
                hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Rating',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                size: 50, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 20),
          const Text('Thank You!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Your feedback means a lot to us.',
              style: TextStyle(fontSize: 14, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TERMS AND PRIVACY
// ─────────────────────────────────────────────────────────────────────────────
class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Terms & Privacy',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Terms of Use'),
                    Tab(text: 'Privacy Policy'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContent(_termsContent),
                    _buildContent(_privacyContent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, String>> sections) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sections[index]['title']!,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 6),
            Text(
              sections[index]['body']!,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textLight, height: 1.6),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  static const List<Map<String, String>> _termsContent = [
    {
      'title': '1. Acceptance of Terms',
      'body':
          'By using Govi Sahaya, you agree to these terms. If you do not agree, please do not use the application.',
    },
    {
      'title': '2. Use of the App',
      'body':
          'Govi Sahaya is intended for agricultural purposes. You agree to use it lawfully and not misuse any features.',
    },
    {
      'title': '3. Intellectual Property',
      'body':
          'All content, logos, and data within Govi Sahaya are property of DARTIS Dynamics. Unauthorized reproduction is prohibited.',
    },
    {
      'title': '4. Disclaimer',
      'body':
          'AI-generated crop recommendations are for guidance only. DARTIS Dynamics is not liable for agricultural decisions made based on app data.',
    },
    {
      'title': '5. Changes to Terms',
      'body':
          'We may update these terms at any time. Continued use of the app after changes constitutes acceptance.',
    },
  ];

  static const List<Map<String, String>> _privacyContent = [
    {
      'title': '1. Data We Collect',
      'body':
          'We collect your name, email, phone number, farm location, and usage data to provide our services.',
    },
    {
      'title': '2. How We Use Your Data',
      'body':
          'Your data is used to personalize crop recommendations, weather alerts, and community features.',
    },
    {
      'title': '3. Data Sharing',
      'body':
          'We do not sell your personal data. Data may be shared with service providers who help operate the app.',
    },
    {
      'title': '4. Data Security',
      'body':
          'We use industry-standard encryption and secure servers to protect your information.',
    },
    {
      'title': '5. Your Rights',
      'body':
          'You may request deletion of your account and data at any time via Settings → Delete Account.',
    },
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORT PROBLEM
// ─────────────────────────────────────────────────────────────────────────────
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _selectedCategory = 'App Crash';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _categories = [
    'App Crash',
    'Login Issue',
    'Weather Data',
    'AI Crop Doctor',
    'Forum',
    'Shop',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    // TODO: POST to /api/v1/support/report
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Report Problem',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: _submitted ? _buildSuccess() : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Category
            Text('Category',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight.withOpacity(0.7),
                    letterSpacing: 1.4)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Description',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLight.withOpacity(0.7),
                    letterSpacing: 1.4)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please describe the problem'
                  : null,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                hintStyle:
                    const TextStyle(color: AppTheme.textLight, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Report',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline,
                  size: 50, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            const Text('Report Submitted!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Thank you for the report.\nOur team will review it shortly.',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textLight, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Back to Menu',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
