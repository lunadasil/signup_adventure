import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'success_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Field completion tracking
  bool get _nameDone => _nameController.text.trim().isNotEmpty;
  bool get _emailDone => _isEmailValid(_emailController.text.trim());
  bool get _dobDone => _dobController.text.trim().isNotEmpty;
  bool get _passwordDone => _passwordController.text.trim().length >= 6;
  String _selectedAvatar = '😊';

  // Simple animation for "valid bounce" per field
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut);

    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _dobController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // bounce lightly when a field becomes valid
    if (_nameDone || _emailDone || _passwordDone || _dobDone) {
      if (!_bounceCtrl.isAnimating) {
        _bounceCtrl.reverse().then((_) => _bounceCtrl.forward());
      }
    }
    setState(() {});
  }

  bool _isEmailValid(String v) {
    if (v.isEmpty) return false;
    final r = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return r.hasMatch(v);
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
      HapticFeedback.selectionClick();
    }
  }

  // Strength meter 0..1
double _passwordStrength(String p) {
  if (p.isEmpty) return 0;
  double score = 0;
  if (p.length >= 6) score += 0.25;
  if (p.length >= 10) score += 0.25;
  if (RegExp(r'[A-Z]').hasMatch(p)) score += 0.15;
  if (RegExp(r'[a-z]').hasMatch(p)) score += 0.15;
  if (RegExp(r'[0-9]').hasMatch(p)) score += 0.10;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score += 0.10;
  return score.clamp(0, 1);
}


  void _submitForm() {
    // Shake/haptic for invalid
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    // Simulated network call
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Build badges
      final badges = <String>[];
      final strength = _passwordStrength(_passwordController.text);
      if (strength >= 0.75) badges.add('Strong Password Master');
      final now = DateTime.now();
      if (now.hour < 12) badges.add('The Early Bird');
      if (_nameDone && _emailDone && _dobDone && _passwordDone && _selectedAvatar.isNotEmpty) {
        badges.add('Profile Completer');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            userName: _nameController.text.trim(),
            avatar: _selectedAvatar,
            badges: badges,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_passwordController.text);
    final progress = _computeProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account 🎉'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TipCard(),
                  const SizedBox(height: 20),

                  // Progress tracker
                  ProgressTracker(progress: progress),

                  const SizedBox(height: 24),

                  // Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Adventure Name',
                    icon: Icons.person,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'What should we call you on this adventure?' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'We need your email for adventure updates!';
                      }
                      if (!_isEmailValid(v.trim())) {
                        return 'Oops! That doesn\'t look like a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // DOB
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: _selectDate,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'When did your adventure begin?' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Secret Password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.deepPurple),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Every adventurer needs a secret password!';
                      if (v.length < 6) return 'Make it stronger! At least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),
                  PasswordStrengthMeter(strength: strength),

                  const SizedBox(height: 20),

                  // Avatar picker
                  AvatarPicker(
                    selected: _selectedAvatar,
                    onChanged: (val) {
                      setState(() => _selectedAvatar = val);
                      HapticFeedback.selectionClick();
                    },
                  ),

                  const SizedBox(height: 28),

                  // Submit button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isLoading ? 60 : double.infinity,
                    height: 56,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 5,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Start My Adventure', style: TextStyle(fontSize: 18, color: Colors.white)),
                                SizedBox(width: 10),
                                Icon(Icons.rocket_launch, color: Colors.white),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _computeProgress() {
    // 5 items: name, email, dob, password, avatar (20% each)
    int complete = 0;
    if (_nameDone) complete++;
    if (_emailDone) complete++;
    if (_dobDone) complete++;
    if (_passwordDone) complete++;
    if (_selectedAvatar.isNotEmpty) complete++;

    return (complete / 5.0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates, color: Colors.deepPurple[800]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete your adventure profile!',
              style: TextStyle(
                color: Colors.deepPurple[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress Tracker with milestone messages + haptics
class ProgressTracker extends StatefulWidget {
  final double progress; // 0..1

  const ProgressTracker({super.key, required this.progress});

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> {
  String _message = 'Let’s begin!';

  @override
  void didUpdateWidget(covariant ProgressTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMessage(widget.progress);
  }

  void _updateMessage(double p) {
    String newMsg = _message;
    if (p >= 1.0) {
      newMsg = 'Ready for adventure!';
    } else if (p >= 0.75) {
      newMsg = 'Almost done!';
    } else if (p >= 0.5) {
      newMsg = 'Halfway there!';
    } else if (p >= 0.25) {
      newMsg = 'Great start!';
    } else {
      newMsg = 'Let’s begin!';
    }
    if (newMsg != _message) {
      _message = newMsg;
      HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: widget.progress,
          minHeight: 10,
          backgroundColor: Colors.deepPurple[50],
          color: Colors.deepPurple,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('$pct% complete',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple)),
            const SizedBox(width: 12),
            Text(_message),
          ],
        ),
      ],
    );
  }
}

/// Simple password strength meter
class PasswordStrengthMeter extends StatelessWidget {
  final double strength; // 0..1
  const PasswordStrengthMeter({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    String label;
    if (strength >= 0.75) {
      label = 'Strong 💪';
    } else if (strength >= 0.5) {
      label = 'Medium 🙂';
    } else if (strength > 0) {
      label = 'Weak 😬';
    } else {
      label = 'Enter a password';
    }

    Color barColor;
    if (strength >= 0.75) {
      barColor = Colors.green;
    } else if (strength >= 0.5) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 8,
            backgroundColor: Colors.black12,
            color: barColor,
          ),
        ),
        const SizedBox(height: 6),
        Text('Password strength: $label'),
      ],
    );
  }
}

/// Avatar picker row
class AvatarPicker extends StatelessWidget {
  final List<String> avatars = const ['😊', '🚀', '🌸', '🐱', '🎮'];
  final String selected;
  final ValueChanged<String> onChanged;

  const AvatarPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose your avatar', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: avatars.map((a) {
            final isSel = a == selected;
            return GestureDetector(
              onTap: () => onChanged(a),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? Colors.deepPurple : Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? Colors.deepPurple : Colors.deepPurple.shade100),
                ),
                child: Text(
                  a,
                  style: TextStyle(
                    fontSize: 20,
                    color: isSel ? Colors.white : Colors.deepPurple,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
