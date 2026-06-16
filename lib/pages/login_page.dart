import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/api_client.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';
import '../utils/constants.dart';
import '../utils/form_validator.dart';
import '../utils/api_error_mapper.dart';
import '../widgets/validated_text_field.dart';
import '../widgets/loading_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  
  bool _loading = false;
  bool _obscurePassword = true;
  final Map<String, String> _errors = {};
  bool _isNetworkError = false;

  late final AuthApi _authApi;

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _authApi = AuthApi(client);
    
    // Real-time validation listeners
    _username.addListener(_validateUsername);
    _password.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
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

    // Re-validate all fields before submission
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

      // Save token
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top navigation / back button row
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Google-inspired clinical illustration circle
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative background circle inside
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Main biotech icon
                      const Icon(
                        Icons.biotech_rounded,
                        color: AppColors.primary,
                        size: 56,
                      ),
                      // Floating bubble 1
                      Positioned(
                        top: 24,
                        right: 28,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Floating bubble 2
                      Positioned(
                        bottom: 28,
                        left: 24,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title and Subtitle
              Center(
                child: Column(
                  children: [
                    Text(
                      'Selamat Datang',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk untuk mengakses layanan laboratorium eLabora',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Network Error Alert
              if (_isNetworkError)
                _buildAlertBanner(
                  icon: Icons.wifi_off_rounded,
                  message: 'Koneksi internet bermasalah. Periksa koneksi Anda.',
                  color: Colors.orange,
                ),

              // Form Level Error Alert
              if (_errors.containsKey('_form'))
                _buildAlertBanner(
                  icon: Icons.error_outline_rounded,
                  message: _errors['_form']!,
                  color: Colors.red,
                ),

              // Username Input
              ValidatedTextField(
                controller: _username,
                label: 'Username',
                hint: 'Masukkan username Anda',
                errorText: _errors['username'],
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              ValidatedTextField(
                controller: _password,
                label: 'Password',
                hint: 'Masukkan password Anda',
                errorText: _errors['password'],
                obscureText: _obscurePassword,
                enabled: !_loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _doLogin(),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              LoadingButton(
                isLoading: _loading,
                text: 'Masuk',
                loadingText: 'Menghubungkan...',
                onPressed: _isFormValid() ? _doLogin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 36),

              // Link to Register Screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum memiliki akun? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!_loading) {
                        Navigator.pushNamed(context, '/register');
                      }
                    },
                    child: Text(
                      'Daftar Sekarang',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner({
    required IconData icon,
    required String message,
    required MaterialColor color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
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
}
