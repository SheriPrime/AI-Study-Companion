import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/core/widgets/app_text_field.dart';
import 'package:ai_study_companion/core/widgets/loading_button.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';

/// A minimalist signup screen mirroring the login screen's aesthetic.
///
/// Collects name, email, password, and confirm-password with inline
/// validation and shows loading / error / success feedback.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _timelineController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFormValid = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _universityController.addListener(_validateForm);
    _departmentController.addListener(_validateForm);
    _timelineController.addListener(_validateForm);
    _passwordController.addListener(() {
      setState(() {});
      _validateForm();
    });
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _timelineController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  void _validateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Numbers are not allowed in the name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must contain at least one lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain at least one number';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Must contain at least one special character';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateUniversity(String? value) {
    if (value == null || value.trim().isEmpty) return 'University name is required';
    return null;
  }

  String? _validateDepartment(String? value) {
    if (value == null || value.trim().isEmpty) return 'Department / major is required';
    return null;
  }

  String? _validateTimeline(String? value) {
    if (value == null || value.trim().isEmpty) return 'Session (e.g. 2023-2027) is required';
    return null;
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    
    return strength;
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = context.read<AuthController>();
    controller.clearError();

    await controller.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      university: _universityController.text.trim(),
      department: _departmentController.text.trim(),
      timeline: _timelineController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (controller.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully! Please log in with your credentials.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                  const SizedBox(height: 32),
                  _buildSignupButton(),
                  const SizedBox(height: 24),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Gradient icon and headline matching the login screen's style.
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_stories,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start your learning journey today',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  /// All four input fields wrapped in a validated [Form].
  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Name
          AppTextField(
            label: 'Full Name',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: _validateName,
          ),
          const SizedBox(height: 20),

          // Email
          AppTextField(
            label: 'Email',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: 20),

          // University
          AppTextField(
            label: 'University',
            controller: _universityController,
            prefixIcon: Icons.school_outlined,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: _validateUniversity,
          ),
          const SizedBox(height: 20),

          // Department
          AppTextField(
            label: 'Department / Major',
            controller: _departmentController,
            prefixIcon: Icons.account_tree_outlined,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: _validateDepartment,
          ),
          const SizedBox(height: 20),

          // Timeline
          AppTextField(
            label: 'Session / Timeline (e.g. 2023-2027)',
            controller: _timelineController,
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: _validateTimeline,
          ),
          const SizedBox(height: 20),

          // Password
          AppTextField(
            label: 'Password',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 22,
                color: AppColors.textHint,
              ),
              splashRadius: 20,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          _buildPasswordStrengthMeter(),
          const SizedBox(height: 20),

          // Confirm Password
          AppTextField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _isFormValid ? _handleSignup() : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 22,
                color: AppColors.textHint,
              ),
              splashRadius: 20,
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ],
      ),
    );
  }

  /// Signup CTA – disabled until every field passes validation.
  Widget _buildSignupButton() {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        return LoadingButton(
          text: 'Sign Up',
          icon: Icons.person_add_outlined,
          isLoading: auth.isLoading,
          onPressed: _isFormValid ? _handleSignup : null,
        );
      },
    );
  }

  /// Navigation link back to the login screen.
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Login',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  /// Visual indicator for password complexity rules met.
  Widget _buildPasswordStrengthMeter() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculatePasswordStrength(password);
    Color color;
    String label;
    
    if (strength <= 0.4) {
      color = AppColors.error;
      label = 'Weak Password';
    } else if (strength <= 0.8) {
      color = AppColors.warning;
      label = 'Medium Password';
    } else {
      color = AppColors.success;
      label = 'Strong Password';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementRow('At least 8 characters', password.length >= 8),
          _buildRequirementRow('One uppercase & one lowercase letter',
              RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)),
          _buildRequirementRow('One number & one special character',
              RegExp(r'[0-9]').hasMatch(password) && RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isMet ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isMet ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
