import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';
import '../utils/constants.dart';
import '../utils/form_validator.dart';
import '../utils/api_error_mapper.dart';
import '../widgets/validated_text_field.dart';
import '../widgets/loading_button.dart';

class LoginDokterPage extends StatefulWidget {
  const LoginDokterPage({super.key});

  @override
  State<LoginDokterPage> createState() => _LoginDokterPageState();
}

class _LoginDokterPageState extends State<LoginDokterPage>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();

  // Form state
  bool _loading = false;
  final Map<String, String> _errors = {};
  bool _isNetworkError = false;

  late final AuthApi _authApi;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _authApi = AuthApi(client);

    // Add listeners for real-time validation
    _username.addListener(_validateUsername);
    _password.addListener(_validatePassword);

    // Animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _validateUsername() {
    setState(() {
      final error = FormValidator.validateUsername(_username.text);
      if (error != null) {
        _errors['username'] = error;
      } else {
        _errors.remove('username');
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final error = FormValidator.validatePassword(_password.text);
      if (error != null) {
        _errors['password'] = error;
      } else {
        _errors.remove('password');
      }
    });
  }

  bool _isFormValid() {
    final validationErrors = FormValidator.validateLoginForm(
      username: _username.text,
      password: _password.text,
    );

    return validationErrors.values.every((error) => error == null);
  }

  Future<void> _doLogin() async {
    if (_loading) return;

    // Validate all fields
    final validationErrors = FormValidator.validateLoginForm(
      username: _username.text,
      password: _password.text,
    );

    setState(() {
      _errors.clear();
      validationErrors.forEach((key, value) {
        if (value != null) {
          _errors[key] = value;
        }
      });
    });

    if (_errors.isNotEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _isNetworkError = false;
    });

    try {
      final result = await _authApi.login(
        username: _username.text.trim(),
        password: _password.text,
      );

      final token = result['token'] as String?;
      final role = result['role'] as String?;

      if (token == null || role == null) {
        throw Exception('Login gagal: data tidak lengkap');
      }

      // simpan token
      final storage = TokenStorage();
      await storage.saveToken(token);

      if (!mounted) return;

      if (role == 'DOKTER') {
        Navigator.pushReplacementNamed(context, '/doctor_home');
      } else if (role == 'PASIEN') {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception('Role tidak dikenali');
      }
    } on DioException catch (e) {
      if (!mounted) return;

      // Map API errors to form fields
      final apiErrors = ApiErrorMapper.mapErrorToFields(e);
      setState(() {
        _errors.addAll(apiErrors);
        _isNetworkError = ApiErrorMapper.isNetworkError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors['_form'] = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // === GRADIENT HEADER (TEAL) ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.38,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: -20,
                    right: -15,
                    child: _buildDecoCircle(80, 0.07),
                  ),
                  Positioned(
                    top: 70,
                    left: -25,
                    child: _buildDecoCircle(60, 0.05),
                  ),
                  Positioned(
                    bottom: 50,
                    right: 40,
                    child: _buildDecoCross(0.1),
                  ),
                  Positioned(
                    top: 90,
                    right: 60,
                    child: _buildDecoCross(0.07),
                  ),
                  // Stethoscope icon decorative
                  Positioned(
                    bottom: 30,
                    left: 30,
                    child: Icon(
                      Icons.healing_rounded,
                      color: Colors.white.withValues(alpha: 0.08),
                      size: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === MAIN CONTENT ===
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Icon circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  'Masuk sebagai Dokter',
                  style: t.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan kredensial akun Anda',
                  style: t.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 28),

                // === FORM CARD ===
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryDark
                                      .withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Network error banner
                                if (_isNetworkError)
                                  _buildErrorBanner(
                                    icon: Icons.wifi_off_rounded,
                                    text: 'Koneksi internet bermasalah',
                                    color: Colors.orange,
                                  ),

                                // Form-level error
                                if (_errors.containsKey('_form'))
                                  _buildErrorBanner(
                                    icon: Icons.error_outline_rounded,
                                    text: _errors['_form']!,
                                    color: Colors.red,
                                  ),

                                ValidatedTextField(
                                  controller: _username,
                                  label: 'Username',
                                  hint: 'Masukkan username',
                                  helperText: 'Minimal 3 karakter',
                                  errorText: _errors['username'],
                                  enabled: !_loading,
                                  textInputAction: TextInputAction.next,
                                  prefixIcon:
                                      const Icon(Icons.person_outline_rounded),
                                ),
                                const SizedBox(height: 20),

                                ValidatedTextField(
                                  controller: _password,
                                  label: 'Password',
                                  hint: 'Masukkan password',
                                  helperText: 'Minimal 6 karakter',
                                  errorText: _errors['password'],
                                  obscureText: true,
                                  enabled: !_loading,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _doLogin(),
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                ),
                                const SizedBox(height: 28),

                                // Login button with teal gradient
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: _isFormValid() && !_loading
                                          ? AppColors.secondaryGradient
                                          : LinearGradient(
                                              colors: [
                                                AppColors.secondary
                                                    .withValues(alpha: 0.4),
                                                AppColors.secondaryDark
                                                    .withValues(alpha: 0.4),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: _isFormValid() && !_loading
                                          ? [
                                              BoxShadow(
                                                color: AppColors.secondary
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 12,
                                                offset: const Offset(0, 5),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: LoadingButton(
                                      isLoading: _loading,
                                      text: 'Masuk',
                                      loadingText: 'Memproses...',
                                      onPressed:
                                          _isFormValid() ? _doLogin : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner({
    required IconData icon,
    required String text,
    required MaterialColor color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecoCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildDecoCross(double opacity) {
    return Transform.rotate(
      angle: math.pi / 6,
      child: Icon(
        Icons.add_rounded,
        color: Colors.white.withValues(alpha: opacity),
        size: 24,
      ),
    );
  }
}
