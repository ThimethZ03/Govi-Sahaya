import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// ── Returned data model ──────────────────────────────────────────────────────

class EditedProfileData {
  const EditedProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.birthday,
    required this.gender,
    required this.farmLocation,
    required this.extraNotes,
  });
  final String name;
  final String email;
  final String phone;
  final String address;
  final String birthday;
  final String gender;
  final String farmLocation;
  final String extraNotes;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _selectedGender;
  int _completionPercent = 0;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _birthdayCtrl;
  late final TextEditingController _farmCtrl;
  late final TextEditingController _notesCtrl;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _birthdayCtrl = TextEditingController(text: user?.birthday ?? '');
    _farmCtrl = TextEditingController(text: user?.farmLocation ?? '');
    _notesCtrl = TextEditingController(text: user?.extraNotes ?? '');
    _selectedGender = user?.gender;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _updateCompletion();
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _addressCtrl,
      _birthdayCtrl,
      _farmCtrl,
      _notesCtrl
    ]) {
      c.addListener(_updateCompletion);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _addressCtrl,
      _birthdayCtrl,
      _farmCtrl,
      _notesCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateCompletion() {
    final filled = [
      _nameCtrl.text,
      _emailCtrl.text,
      _phoneCtrl.text,
      _addressCtrl.text,
      _birthdayCtrl.text,
      _selectedGender ?? '',
      _farmCtrl.text,
      _notesCtrl.text,
    ].where((v) => v.trim().isNotEmpty).length;
    setState(() => _completionPercent = ((filled / 8) * 100).round());
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10),
    );
    if (picked != null) {
      _birthdayCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.pop(
      context,
      EditedProfileData(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        birthday: _birthdayCtrl.text.trim(),
        gender: _selectedGender ?? '',
        farmLocation: _farmCtrl.text.trim(),
        extraNotes: _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF6F7FB),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(cs, isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          _sectionLabel('Personal Info', cs),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              cs: cs,
                              isDark: isDark,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _birthdayCtrl,
                              label: 'Birthday',
                              icon: Icons.cake_outlined,
                              cs: cs,
                              isDark: isDark,
                              readOnly: true,
                              onTap: _pickDate,
                              hint: 'Select your birthday'),
                          const SizedBox(height: 14),
                          _buildGenderSelector(cs),
                          const SizedBox(height: 28),
                          _sectionLabel('Contact', cs),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _emailCtrl,
                              label: 'Email Address',
                              icon: Icons.mail_outline_rounded,
                              cs: cs,
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Email is required';
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v.trim()))
                                  return 'Enter a valid email';
                                return null;
                              }),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _phoneCtrl,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              cs: cs,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Phone is required'
                                  : null),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _addressCtrl,
                              label: 'Address',
                              icon: Icons.location_on_outlined,
                              cs: cs,
                              isDark: isDark,
                              maxLines: 2),
                          const SizedBox(height: 28),
                          _sectionLabel('Farm Details', cs),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _farmCtrl,
                              label: 'Farm Location',
                              icon: Icons.agriculture_outlined,
                              cs: cs,
                              isDark: isDark),
                          const SizedBox(height: 14),
                          _buildField(
                              controller: _notesCtrl,
                              label: 'Extra Notes',
                              icon: Icons.notes_rounded,
                              cs: cs,
                              isDark: isDark,
                              maxLines: 3,
                              hint: 'Any additional information...'),
                          const SizedBox(height: 36),
                          _buildSaveButton(cs),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, bool isDark) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CircleBtn(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context)),
                          const Spacer(),
                          const Text('Edit Profile',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2)),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Profile Completion',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text('$_completionPercent%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _completionPercent / 100),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, __) => LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _completionPercent == 100
                            ? '✓ All fields filled — looking great!'
                            : '${8 - (_completionPercent / 12.5).round()} fields remaining',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF6F7FB),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: const SizedBox(height: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                  color: cs.primary, borderRadius: BorderRadius.circular(3)),
              child: const SizedBox(width: 3, height: 18),
            ),
            const SizedBox(width: 10),
            Text(
              text.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );

  // ── Input field ───────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hint,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle:
              TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today_outlined,
                  size: 18, color: cs.onSurface.withOpacity(0.4))
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          labelStyle: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w500),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.15))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.primary, width: 1.8)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.error.withOpacity(0.8))),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.error, width: 1.8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );

  // ── Gender chip selector ──────────────────────────────────────────────────

  Widget _buildGenderSelector(ColorScheme cs) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Gender',
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w500)),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _genders.map((g) {
              final selected = _selectedGender == g;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedGender = g;
                  _updateCompletion();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color:
                          selected ? cs.primary : cs.outline.withOpacity(0.3),
                      width: selected ? 0 : 1,
                    ),
                  ),
                  child: Text(g,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : cs.onSurface.withOpacity(0.6))),
                ),
              );
            }).toList(),
          ),
        ],
      );

  // ── Save button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton(ColorScheme cs) => SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            disabledBackgroundColor: cs.primary.withOpacity(0.6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _saving
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Row(
                    key: ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Save Changes',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3)),
                    ],
                  ),
          ),
        ),
      );
}

// ── Small circle icon button ──────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );
}
